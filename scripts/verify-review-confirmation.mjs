import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import pg from 'pg';
const base='http://127.0.0.1:3000';const jar=new Map();
async function request(path,body,expected=200){const r=await fetch(base+'/api/'+path,{method:'POST',headers:{Origin:base,'Content-Type':'application/json',Cookie:[...jar].map(([k,v])=>k+'='+v).join('; ')},body:JSON.stringify(body)});const data=await r.json();assert.equal(r.status,expected,JSON.stringify(data));for(const set of r.headers.getSetCookie()){const pair=set.split(';')[0],index=pair.indexOf('=');jar.set(pair.slice(0,index),pair.slice(index+1));}return data;}
const db=new pg.Client({connectionString:process.env.DATABASE_URL});await db.connect();
const email='review-agent-qa-'+randomUUID()+'@example.test';let accountId;
try{
 const auth=await request('auth/register',{name:'Review Agent QA',email,password:'TemporaryQA991!'});accountId=auth.user.id;
 const chat=await request('chat',{message:'Привет'});const nonce=randomUUID();
 await db.query('UPDATE gym_web.chats SET pending_action=$1 WHERE id=$2',[{gymId:'1',gymName:'Gym Point',rating:4,content:'Тест подтверждения отзыва',confirmationId:nonce,accountId,expiresAt:Date.now()+60000},chat.sessionId]);
 assert.equal((await db.query('SELECT count(*)::int n FROM gym_web.reviews WHERE account_id=$1',[accountId])).rows[0].n,0);
 await request('chat',{sessionId:chat.sessionId,confirmationId:randomUUID(),decision:'confirm'},409);
 await request('chat',{sessionId:chat.sessionId,confirmationId:nonce,decision:'confirm'});
 assert.equal((await db.query('SELECT count(*)::int n FROM gym_web.reviews WHERE account_id=$1',[accountId])).rows[0].n,1);
 await request('chat',{sessionId:chat.sessionId,confirmationId:nonce,decision:'confirm'},409);
 console.log('PASS review confirmation: draft stays private, invalid nonce rejected, confirm publishes once, replay rejected');
}finally{if(accountId){await db.query('DELETE FROM gym_web.chats WHERE owner_hash=$1',['account:'+accountId]);await db.query('DELETE FROM gym_web.accounts WHERE id=$1',[accountId]);}await db.end();}
