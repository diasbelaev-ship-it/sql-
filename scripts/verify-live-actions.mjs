// Manual live Gemini check. Creates and removes only its own temporary QA account.
// Run with: node --env-file=.env.local scripts/verify-live-actions.mjs
import assert from 'node:assert/strict';
import {randomBytes,randomUUID} from 'node:crypto';
import pg from 'pg';

const base=process.env.APP_ORIGIN??'http://127.0.0.1:3000';
if(!['127.0.0.1','localhost','[::1]'].includes(new URL(base).hostname)){
  throw Error('This QA script may run only against a local website');
}
const jar=new Map();
const email='live-agent-qa-'+randomUUID()+'@example.test';
const db=new pg.Client({connectionString:process.env.DATABASE_URL});
let accountId;
let sessionId;
let connected=false;

async function request(step,path,body){
  const started=Date.now();
  const response=await fetch(base+'/api/'+path,{
    method:'POST',
    headers:{Origin:base,'Content-Type':'application/json',Cookie:[...jar].map(([k,v])=>k+'='+v).join('; ')},
    body:JSON.stringify(body),
    signal:AbortSignal.timeout(90000),
  });
  for(const set of response.headers.getSetCookie()){
    const pair=set.split(';')[0],index=pair.indexOf('=');
    const name=pair.slice(0,index),value=pair.slice(index+1);
    if(/(?:^|;)\s*Max-Age=0(?:;|$)/i.test(set)||!value)jar.delete(name);
    else jar.set(name,value);
  }
  const data=await response.json();
  console.log(JSON.stringify({step,status:response.status,provider:data.provider,notice:data.providerNotice,
    actions:(data.actions??[]).map(action=>action.type),ms:Date.now()-started}));
  assert.equal(response.status,200,step+': expected successful local API response');
  return data;
}

async function chat(step,message){
  const result=await request(step,'chat',{message,sessionId});
  sessionId=result.sessionId;
  assert.equal(result.provider,'gemini',step+': a live Gemini response is required; fallback is not success');
  return result;
}

try{
  await db.connect();
  connected=true;
  const auth=await request('register','auth/register',{
    name:'Live Gemini QA',email,password:randomBytes(24).toString('base64url'),
  });
  accountId=String(auth.user.id);

  const search=await chat('search','Найди Invictus GO Abay, годовой, только опубликованные цены, до 30к');
  assert.equal(search.filters.term,'year','search must preserve the annual plan requirement');
  assert.equal(search.filters.published,'1','search must use published prices');
  assert.equal(search.filters.max,30000);
  assert.ok(Array.isArray(search.gyms)&&search.gyms.length>0,'search must return a gym');
  const gym=search.gyms[0];
  const gymId=String(gym.id);
  assert.match(gym.name,/Invictus GO Abay/i);
  assert.ok(gym.duration_days>=365&&gym.duration_days<=366);
  assert.equal(gym.price_basis,'published');

  const save=await chat('favorite-add','Добавь первый зал в моё избранное');
  assert.ok(save.actions?.some(action=>action.type==='favorites_changed'),'save must execute a favorite mutation');
  const favorites=await db.query('SELECT gym_id::text FROM gym_web.favorites WHERE account_id=$1',[accountId]);
  assert.deepEqual(favorites.rows.map(row=>row.gym_id),[gymId],'only the selected gym must belong to the QA account');

  const reviewText='Тестовый отзыв QA: удобное расположение. Проверка работы помощника.';
  const draft=await chat('review-draft',
    'Подготовь отзыв этому залу: оценка 4 из 5. Текст отзыва дословно: «'+reviewText+'». Не публикуй, только подготовь черновик.');
  assert.ok(draft.pendingReview,'review must require an explicit confirmation');
  assert.equal(draft.pendingReview.gymId,gymId);
  assert.equal(draft.pendingReview.rating,4);
  assert.equal(draft.pendingReview.content,reviewText,'the assistant must preserve the authored review text');
  const unpublished=await db.query('SELECT count(*)::int n FROM gym_web.reviews WHERE account_id=$1',[accountId]);
  assert.equal(unpublished.rows[0].n,0,'preparing a draft must never publish the review');

  await request('review-cancel','chat',{
    sessionId,confirmationId:draft.pendingReview.confirmationId,decision:'cancel',
  });
  const cancelled=await db.query('SELECT count(*)::int n FROM gym_web.reviews WHERE account_id=$1',[accountId]);
  assert.equal(cancelled.rows[0].n,0,'cancelling the draft must leave no published review');

  const remove=await chat('favorite-remove','Удали этот зал из моего избранного');
  assert.ok(remove.actions?.some(action=>action.type==='favorites_changed'),'remove must execute a favorite mutation');
  const removed=await db.query('SELECT count(*)::int n FROM gym_web.favorites WHERE account_id=$1',[accountId]);
  assert.equal(removed.rows[0].n,0,'the favorite must be removed from the QA account');
  console.log('PASS live Gemini: annual search, own favorite add/remove, review draft and cancellation');
}catch(error){
  console.error('FAIL live Gemini actions:',error instanceof Error?error.message:'Unknown failure');
  process.exitCode=1;
}finally{
  try{
    // The generated email uniquely identifies this run even if registration succeeded before a client error.
    if(connected&&!accountId){
      const account=await db.query('SELECT id::text FROM gym_web.accounts WHERE email=$1',[email]);
      accountId=account.rows[0]?.id;
    }
    if(connected&&accountId){
      await db.query('DELETE FROM gym_web.chats WHERE owner_hash=$1',['account:'+accountId]);
      await db.query('DELETE FROM gym_web.accounts WHERE id=$1 AND email=$2',[accountId,email]);
    }
  }catch{
    console.error('QA cleanup could not complete; the generated QA account needs local cleanup.');
    process.exitCode=1;
  }
  await db.end();
}
