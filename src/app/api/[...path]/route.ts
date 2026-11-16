import { NextRequest,NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { randomBytes,createHash } from 'node:crypto';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { pool } from '@/lib/db';
import { filtersSchema } from '@/lib/filters';
import { searchGyms } from '@/lib/search';
import { chatService } from '@/lib/chat-service';
import { getSiteOrigin,isSecureSiteOrigin } from '@/lib/runtime-origin';
export const runtime='nodejs';
const hash=(s:string)=>createHash('sha256').update(s).digest('hex');
const limits=new Map<string,{n:number,until:number}>();
async function user(){const jar=await cookies();const t=jar.get('gym_auth')?.value;if(!t)return null;const r=await pool.query('SELECT a.id::text,a.name,a.email FROM gym_web.sessions s JOIN gym_web.accounts a ON a.id=s.account_id WHERE s.token_hash=$1 AND s.expires_at>now()',[hash(t)]);return r.rows[0]??null;}
const options={httpOnly:true,sameSite:'lax' as const,secure:isSecureSiteOrigin(),path:'/'};
function ok(data:unknown,status=200){return NextResponse.json(data,{status});}
async function handle(req:NextRequest,ctx:{params:Promise<{path:string[]}>}){
 try{
 const path=(await ctx.params).path.join('/'), method=req.method;
 if(method!=='GET'){
   const origin=getSiteOrigin();
   if(req.headers.get('origin')!==origin)return ok({error:'Недопустимый источник запроса'},403);
   if(Number(req.headers.get('content-length')??0)>16384)return ok({error:'Слишком большой запрос'},413);
   const key=(req.headers.get('x-forwarded-for')??'local')+path;
   const now=Date.now(),old=limits.get(key);if(old&&old.until>now){if(++old.n>60)return ok({error:'Слишком много запросов. Попробуйте через минуту.'},429);}else limits.set(key,{n:1,until:now+60000});
   if(limits.size>1000)for(const [k,v] of limits)if(v.until<now)limits.delete(k);
 }
 const me=await user();
 if(path==='auth/me')return ok({user:me});
 if(path==='auth/logout'&&method==='POST'){const jar=await cookies();const token=jar.get('gym_auth')?.value;if(token)await pool.query('DELETE FROM gym_web.sessions WHERE token_hash=$1',[hash(token)]);jar.delete('gym_auth');return ok({success:true});}
 if((path==='auth/register'||path==='auth/login')&&method==='POST'){
   const body=z.object({email:z.email().max(254).transform(v=>v.toLowerCase()),password:z.string().min(8).max(100),name:z.string().trim().min(2).max(80).optional()}).parse(await req.json());
   let account;
   if(path.endsWith('register')){
     if(!body.name)return ok({error:'Укажите имя'},400);
     const r=await pool.query('INSERT INTO gym_web.accounts(name,email,password_hash) VALUES($1,$2,$3) RETURNING id::text,name,email',[body.name,body.email,await bcrypt.hash(body.password,12)]);account=r.rows[0];
   }else{
     const r=await pool.query('SELECT * FROM gym_web.accounts WHERE email=$1',[body.email]);
     if(!r.rows[0]||!await bcrypt.compare(body.password,r.rows[0].password_hash))return ok({error:'Неверный email или пароль'},401);
     account={id:String(r.rows[0].id),name:r.rows[0].name,email:r.rows[0].email};
   }
   const token=randomBytes(32).toString('hex');await pool.query("INSERT INTO gym_web.sessions VALUES($1,$2,now()+interval '8 hours')",[hash(token),account.id]);
   (await cookies()).set('gym_auth',token,{...options,maxAge:28800});return ok({user:account});
 }
 if(path==='gyms'&&method==='GET')return ok(await searchGyms(filtersSchema.parse(Object.fromEntries(req.nextUrl.searchParams)),me?.id,false,pool,req.nextUrl.searchParams.get('map')==='1'));
 if(/^gyms\/\d+$/.test(path)&&method==='GET'){
   const id=path.split('/')[1];
   const g=await pool.query('SELECT * FROM almaty_gym.gyms WHERE id=$1',[id]);if(!g.rowCount)return ok({error:'Зал не найден'},404);
   const [plans,classes,trainers,reviews]=await Promise.all([
     pool.query('SELECT * FROM almaty_gym.plans WHERE gym_id=$1 ORDER BY duration_days,audience',[id]),
     pool.query('SELECT * FROM almaty_gym.classes WHERE gym_id=$1 ORDER BY weekday',[id]),
     pool.query('SELECT * FROM almaty_gym.trainers WHERE gym_id=$1',[id]),
     pool.query('SELECT r.rating,r.content,r.created_at,a.name FROM gym_web.reviews r JOIN gym_web.accounts a ON a.id=r.account_id WHERE gym_id=$1 ORDER BY r.created_at DESC LIMIT 50',[id])]);
   return ok({gym:g.rows[0],plans:plans.rows,classes:classes.rows,trainers:trainers.rows,reviews:reviews.rows});
 }
 if(path==='favorites'){
   if(!me)return ok({error:'Войдите в аккаунт'},401);
   if(method==='GET')return ok(await searchGyms(filtersSchema.parse(Object.fromEntries(req.nextUrl.searchParams)),me.id,true,pool,req.nextUrl.searchParams.get('map')==='1'));
   const body=z.object({gymId:z.coerce.number().int().positive()}).parse(await req.json());
   if(method==='POST')await pool.query('INSERT INTO gym_web.favorites VALUES($1,$2) ON CONFLICT DO NOTHING',[me.id,body.gymId]);
   else if(method==='DELETE')await pool.query('DELETE FROM gym_web.favorites WHERE account_id=$1 AND gym_id=$2',[me.id,body.gymId]);
   return ok({success:true});
 }
 if(path==='reviews'&&method==='POST'){
   if(!me)return ok({error:'Войдите, чтобы оставить отзыв'},401);
   const b=z.object({gymId:z.coerce.number().int().positive(),rating:z.coerce.number().int().min(1).max(5),content:z.string().trim().min(3).max(2000)}).parse(await req.json());
   await pool.query('INSERT INTO gym_web.reviews(account_id,gym_id,rating,content) VALUES($1,$2,$3,$4) ON CONFLICT(account_id,gym_id) DO UPDATE SET rating=excluded.rating,content=excluded.content,created_at=now()',[me.id,b.gymId,b.rating,b.content]);return ok({success:true});
 }
 if(path==='chat'&&method==='POST'){const result=await chatService(await req.json(),me);return ok(result.data,result.status);}
 return ok({error:'Страница API не найдена'},404);
 }catch(e){if(e instanceof z.ZodError)return ok({error:e.issues[0]?.message??'Проверьте поля'},400);
 if(e instanceof SyntaxError)return ok({error:'Некорректный JSON'},400);
 if((e as {code?:string}).code==='23505')return ok({error:'Такой email уже зарегистрирован'},409);
 console.error('API error',e instanceof Error?e.message:'unknown');return ok({error:'Не удалось выполнить запрос к базе. Проверьте подключение PostgreSQL.'},503);}
}
export const GET=handle;export const POST=handle;export const DELETE=handle;
