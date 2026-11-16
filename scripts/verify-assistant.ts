import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {pool} from '../src/lib/db';
import {defaults} from '../src/lib/filters';
import {executeTool,type AssistantContext} from '../src/lib/assistant-tools';
const db=await pool.connect();
try{
 await db.query('BEGIN');
 const email='agent-qa-'+randomUUID()+'@example.test';
 const a=await db.query('INSERT INTO gym_web.accounts(name,email,password_hash) VALUES($1,$2,$3) RETURNING id::text',['Agent QA',email,'not-a-login-password']);
 const ctx:AssistantContext={db,accountId:a.rows[0].id,filters:{...defaults,term:'year',published:'1',max:30000},results:[],actions:[]};
 const found=await executeTool('search_gyms',{},ctx);assert.equal(found.total,10);
 const compared=await executeTool('compare_gyms',{resultPositions:[3,1]},ctx);
 const gyms=compared.gyms as {id:string;duration_days:number;price_basis:string}[];
 assert.equal(gyms[0].id,ctx.results[2]);assert.equal(gyms[1].id,ctx.results[0]);assert.ok(gyms.every(g=>g.duration_days===365&&g.price_basis==='published'));
 await executeTool('set_favorite',{gymId:ctx.results[0],favorite:true},ctx);
 const favorites=await executeTool('list_favorites',{},ctx);assert.equal(favorites.total,1);
 await executeTool('prepare_review',{gymId:ctx.results[0],rating:4,content:'Черновик отзыва для QA'},ctx);
 assert.ok(ctx.pendingReview);assert.equal((await db.query('SELECT count(*)::int n FROM gym_web.reviews WHERE account_id=$1',[ctx.accountId])).rows[0].n,0);
 await db.query('ROLLBACK');console.log('PASS real PostgreSQL: annual ordinal comparison, write/read favorites in one transaction, review remains draft');
}catch(e){await db.query('ROLLBACK');throw e;}finally{db.release();await pool.end();}
