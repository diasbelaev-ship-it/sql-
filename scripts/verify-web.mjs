import assert from 'node:assert/strict';
import pg from 'pg';
const base='http://127.0.0.1:3000';let cookie='';
async function call(path,method='GET',body,expected=200,customCookie=cookie){const r=await fetch(base+'/api/'+path,{method,headers:{Origin:base,...(body?{'Content-Type':'application/json'}:{}),Cookie:customCookie},body:body?JSON.stringify(body):undefined});const d=await r.json();assert.equal(r.status,expected,JSON.stringify(d));for(const value of r.headers.getSetCookie()){const pair=value.split(';')[0],name=pair.split('=')[0];cookie=cookie.split('; ').filter(v=>v&&!v.startsWith(name+'=')).concat(pair).join('; ');}return d;}
const email=`qa-${Date.now()}@example.test`;
const db=new pg.Client({connectionString:'postgresql://postgres@127.0.0.1:55443/gymfinder_almaty'});await db.connect();
try{
 const all=await call('gyms');assert.equal(all.total,70);assert.equal(all.gyms.length,20);assert.equal(all.gyms[0].price_basis,'published');
 const map=await call('gyms?map=1');assert.equal(map.total,70);assert.equal(map.gyms.length,70);assert.equal(map.gyms.filter(g=>g.geo_accuracy_m===1000).length,67);
 const filtered=await call('gyms?audience=student&max=15000');assert.ok(filtered.gyms.length);assert.ok(filtered.gyms.every(g=>g.monthly<=15000));
 const year=await call('gyms?term=year');assert.equal(year.total,10);assert.ok(year.gyms.every(g=>g.duration_days>=365));
 await call('gyms?sort=distance','GET',undefined,400);
 const injection=await call('gyms?q='+encodeURIComponent("'; DROP TABLE almaty_gym.gyms;--"));assert.equal(injection.total,0);
 await call('favorites','POST',{gymId:1},401);
 const bad=await fetch(base+'/api/auth/login',{method:'POST',headers:{Origin:'https://evil.test','Content-Type':'application/json'},body:'{}'});assert.equal(bad.status,403);
 await call('auth/register','POST',{name:'QA пользователь',email,password:'TemporaryTest982!'});
 const token=cookie;assert.ok((await call('auth/me')).user);
 await call('favorites','POST',{gymId:1});assert.equal((await call('favorites')).gyms.length,1);
 await call('favorites','DELETE',{gymId:1});assert.equal((await call('favorites')).gyms.length,0);
 await call('reviews','POST',{gymId:1,rating:5,content:'Тестовый отзыв QA'});assert.ok((await call('gyms/1')).reviews.some(r=>r.content==='Тестовый отзыв QA'));
 const chat=await call('chat','POST',{message:'годовой до 30к'});
 assert.equal(chat.filters.term,'year','chat must preserve the explicitly requested annual term');
 assert.equal(chat.filters.max,30000,'chat must preserve the explicitly requested budget');
 assert.ok(chat.gyms?.every(g=>g.duration_days>=365&&g.monthly<=30000),'chat results must match the requested annual term and monthly budget');
 const refined=await call('chat','POST',{sessionId:chat.sessionId,message:'до 25к'});assert.equal(refined.filters.term,'year');assert.equal(refined.filters.max,25000);
 await call('chat','POST',{sessionId:chat.sessionId,message:'до 20к'},404,'');
 cookie=token;await call('auth/logout','POST');cookie=token;assert.equal((await call('auth/me')).user,null);
 console.log('PASS: search, annual plans, validation, SQL injection, origin, auth, favorites, reviews, chat memory/ownership, logout');
}finally{await db.query("DELETE FROM gym_web.messages WHERE chat_id IN(SELECT id FROM gym_web.chats WHERE owner_hash IN(SELECT 'account:'||id FROM gym_web.accounts WHERE email=$1))",[email]);await db.query("DELETE FROM gym_web.chats WHERE owner_hash IN(SELECT 'account:'||id FROM gym_web.accounts WHERE email=$1)",[email]);await db.query('DELETE FROM gym_web.accounts WHERE email=$1',[email]);await db.end();}
