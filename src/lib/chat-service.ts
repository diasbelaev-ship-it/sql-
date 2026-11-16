import { cookies } from 'next/headers';
import { createHash,randomBytes,randomUUID } from 'node:crypto';
import { z } from 'zod';
import { pool } from './db';
import { defaults, filtersSchema } from './filters';
import { parsePhrase } from './filters';
import { getTermBounds } from './subscription-terms';
import type { AssistantContext,ReviewDraft } from './assistant-tools';
import { runGemini,ProviderUnavailable } from './gemini-assistant';
import { clearGeminiCooldown,geminiCooldownCode,recordGeminiFailure } from './gemini-circuit';
import { runLocal } from './local-assistant';
const hash=(s:string)=>createHash('sha256').update(s).digest('hex');
const contextSchema=z.object({filters:filtersSchema,view:z.enum(['catalog','favorites','map','list','sql']),resultIds:z.array(z.string().regex(/^[1-9]\d{0,17}$/)).max(20).optional()});
const messageSchema=z.object({message:z.string().trim().min(1).max(2000),sessionId:z.uuid().optional(),context:contextSchema.optional()});
const confirmationSchema=z.object({sessionId:z.uuid(),confirmationId:z.uuid(),decision:z.enum(['confirm','cancel'])}).strict();
type Pending=ReviewDraft&{confirmationId:string;accountId:string;expiresAt:number};
type Account={id:string;name:string;email:string}|null;
const reasons:Record<string,string>={invalid_key:'Ключ Gemini отклонён.',not_configured:'Gemini не настроен.',quota:'Квота Gemini исчерпана.',model_not_available:'Модель Gemini недоступна.',invalid_request:'Gemini отклонил запрос.',overloaded:'Gemini временно перегружен.',network:'Нет связи с Gemini.',timeout:'Gemini не ответил вовремя.',tool_limit:'Слишком много действий за один запрос.',empty_response:'Gemini вернул пустой ответ.',ungrounded_response:'Не удалось подтвердить ответ каталогом.'};

export async function chatService(raw:unknown,me:Account){
 const confirmation=confirmationSchema.safeParse(raw);
 const input=confirmation.success?confirmation.data:messageSchema.parse(raw);
 const jar=await cookies();let guest=jar.get('gym_guest')?.value;
 if(!guest){guest=randomBytes(32).toString('hex');jar.set('gym_guest',guest,{httpOnly:true,sameSite:'lax',secure:process.env.APP_ORIGIN?.startsWith('https:')??false,path:'/',maxAge:86400});}
 const owner=me?'account:'+me.id:hash(guest),authToken=jar.get('gym_auth')?.value;
 const db=await pool.connect();
 try{
  await db.query('BEGIN');
  await db.query("SET LOCAL lock_timeout='65s'");
  let session;
  if(input.sessionId){
   const r=await db.query("SELECT * FROM gym_web.chats WHERE id=$1 AND owner_hash=$2 AND updated_at>now()-interval '24 hours' FOR UPDATE",[input.sessionId,owner]);
   if(!r.rowCount){await db.query('ROLLBACK');return {status:404,data:{error:'Чат недоступен. Начните новый диалог.'}};}session=r.rows[0];
  }else{
   const r=await db.query('INSERT INTO gym_web.chats(owner_hash) VALUES($1) RETURNING *',[owner]);session=r.rows[0];
  }
  const currentAccount=async()=>{
   if(!me||!authToken)return undefined;
   const r=await db.query('SELECT account_id::text FROM gym_web.sessions WHERE token_hash=$1 AND expires_at>now() AND account_id=$2',[hash(authToken),me.id]);
   return r.rows[0]?.account_id as string|undefined;
  };
  if(me&&!await currentAccount()){await db.query('ROLLBACK');return {status:401,data:{error:'Сессия завершена. Войдите заново.'}};}
  const parsed=messageSchema.safeParse(raw);
  const initial=filtersSchema.safeParse(session.filters);
  const filters=parsed.success&&parsed.data.context?.filters?parsed.data.context.filters:Object.keys(session.filters??{}).length&&initial.success?initial.data:defaults;
  const currentResults=parsed.success?parsed.data.context?.resultIds:undefined;
  const ctx:AssistantContext={db,accountId:me?.id,filters,results:currentResults??(session.results??[]).map(String),actions:[]};
  if(confirmation.success){
    const pending=session.pending_action as Pending|null;
    if(!me||!pending||pending.accountId!==me.id||pending.confirmationId!==confirmation.data.confirmationId||pending.expiresAt<Date.now()){
      await db.query('ROLLBACK');return {status:409,data:{error:'Подтверждение отзыва истекло или уже использовано.'}};
    }
    const publish=confirmation.data.decision==='confirm';
    if(publish)await db.query('INSERT INTO gym_web.reviews(account_id,gym_id,rating,content) VALUES($1,$2,$3,$4) ON CONFLICT(account_id,gym_id) DO UPDATE SET rating=excluded.rating,content=excluded.content,created_at=now()',[me.id,pending.gymId,pending.rating,pending.content]);
    const answer=publish?'Отзыв опубликован.':'Публикация отзыва отменена.';
    await db.query('UPDATE gym_web.chats SET pending_action=NULL,updated_at=now() WHERE id=$1',[session.id]);
    await db.query("INSERT INTO gym_web.messages(chat_id,role,content) VALUES($1,'assistant',$2)",[session.id,answer]);
    await db.query('COMMIT');return {status:200,data:{sessionId:session.id,answer,provider:'local',filters:ctx.filters,actions:publish?[{type:'open_gym',gymId:pending.gymId}]:[]}};
  }
  if(!parsed.success)throw Error('MESSAGE_REQUIRED');
  const intent=parsePhrase(parsed.data.message,ctx.filters);
  ctx.filters=intent.filters;
  ctx.explicitFilters=intent.patch;
  const previous=await db.query('SELECT role,content FROM (SELECT id,role,content FROM gym_web.messages WHERE chat_id=$1 ORDER BY id DESC LIMIT 12) m ORDER BY id',[session.id]);
  await db.query('SAVEPOINT provider_turn');
  let outcome;let providerNotice:string|undefined;
  const original={filters:ctx.filters,results:[...ctx.results]};
  try{
    const cooldown=process.env.AI_PROVIDER==='local'?undefined:geminiCooldownCode();
    if(process.env.AI_PROVIDER==='local')outcome=await runLocal(parsed.data.message,ctx);
    else if(cooldown){
      outcome=await runLocal(parsed.data.message,ctx);
      providerNotice=(reasons[cooldown]??'Gemini недоступен.')+' Ответил локальный помощник.';
    }else{
      outcome=await runGemini(parsed.data.message,ctx,previous.rows,{pageView:parsed.data.context?.view,forceCatalogSearch:intent.recognized,beforeTool:async()=>{ctx.accountId=await currentAccount();}});
      clearGeminiCooldown();
    }
    await db.query('RELEASE SAVEPOINT provider_turn');
  }catch(error){
    if(!(error instanceof ProviderUnavailable))throw error;
    recordGeminiFailure(error.code);
    await db.query('ROLLBACK TO SAVEPOINT provider_turn');await db.query('RELEASE SAVEPOINT provider_turn');
    ctx.filters=original.filters;ctx.results=original.results;ctx.actions=[];ctx.pendingReview=undefined;
    ctx.accountId=await currentAccount();
    outcome=await runLocal(parsed.data.message,ctx);
    providerNotice=(reasons[error.code]??'Gemini временно недоступен.')+' Сейчас работает локальный помощник.';
  }
  const pending:Pending|undefined=ctx.pendingReview&&ctx.accountId?{...ctx.pendingReview,confirmationId:randomUUID(),accountId:ctx.accountId,expiresAt:Date.now()+10*60000}:undefined;
  await db.query('UPDATE gym_web.chats SET filters=$1,results=$2,pending_action=$3,updated_at=now() WHERE id=$4',[ctx.filters,ctx.results,pending??null,session.id]);
  await db.query("INSERT INTO gym_web.messages(chat_id,role,content) VALUES($1,'user',$2),($1,'assistant',$3)",[session.id,parsed.data.message,outcome.answer]);
  const comparison=ctx.actions.findLast(action=>action.type==='compare');
  const displayIds=comparison?.type==='compare'?comparison.gymIds:ctx.actions.some(action=>action.type==='view'&&(action.view==='catalog'||action.view==='favorites'))?ctx.results:[];
  const gyms=displayIds.length?(await db.query(
    `SELECT g.*,p.monthly,p.price_kzt,p.duration_days,p.price_basis
       FROM almaty_gym.gyms g CROSS JOIN LATERAL (
         SELECT price_kzt,duration_days,price_basis,round(price_kzt*30.0/duration_days)::int monthly
           FROM almaty_gym.plans WHERE gym_id=g.id AND audience=$2
            AND ($3='any' OR duration_days BETWEEN $6::integer AND $7::integer)
            AND ($4='' OR price_basis='published')
            AND round(price_kzt*30.0/duration_days)<=$5
          ORDER BY price_kzt*30.0/duration_days,id LIMIT 1
       ) p WHERE g.id=ANY($1::bigint[])
       ORDER BY array_position($1::bigint[],g.id) LIMIT 5`,
    [displayIds,ctx.filters.audience,ctx.filters.term,ctx.filters.published,ctx.filters.max,...getTermBounds(ctx.filters.term)]
  )).rows:[];
  await db.query('COMMIT');
  return {status:200,data:{sessionId:session.id,...outcome,providerNotice,filters:ctx.filters,actions:ctx.actions,gyms,pendingReview:pending?{confirmationId:pending.confirmationId,gymId:pending.gymId,gymName:pending.gymName,rating:pending.rating,content:pending.content}:undefined}};
 }catch(error){await db.query('ROLLBACK');throw error;}finally{db.release();}
}
