// Read-only checks against the local database after npm run db:setup.
// Run: node --env-file=.env.local node_modules/tsx/dist/cli.mjs scripts/verify-subscription-terms.ts
import assert from 'node:assert/strict';
import {pool} from '../src/lib/db';
import {defaults,type Filters} from '../src/lib/filters';
import {searchGyms} from '../src/lib/search';
import {executeTool,type AssistantContext} from '../src/lib/assistant-tools';

type GymPlan={id:string;duration_days:number;price_kzt:number;monthly:number;price_basis:string};
const terms=[['2months',60],['3months',90],['6months',180],['9months',270]] as const;
const audiences=['student','adult','premium'] as const;
const db=await pool.connect();
try{
  await db.query('BEGIN READ ONLY');
  const counts=await db.query(`SELECT count(*)::int total,
    count(*) FILTER(WHERE price_basis='published')::int published,
    count(*) FILTER(WHERE duration_days IN (60,90,180,270))::int new_terms
    FROM almaty_gym.plans`);
  assert.deepEqual(counts.rows[0],{total:1060,published:14,new_terms:840});
  const generated=await db.query(`SELECT count(*)::int invalid FROM almaty_gym.plans longer
    JOIN almaty_gym.plans monthly ON monthly.gym_id=longer.gym_id
      AND monthly.audience=longer.audience AND monthly.duration_days=30
    WHERE longer.duration_days IN (60,90,180,270)
      AND (longer.price_kzt<>monthly.price_kzt*(longer.duration_days/30)
        OR longer.price_basis<>'model_estimate' OR longer.price_source_url IS NOT NULL)`);
  assert.equal(generated.rows[0].invalid,0,'new estimates must not invent discounts or published sources');

  for(const [term,days] of terms){
    for(const audience of audiences){
      const filters:Filters={...defaults,term,audience,max:2000000};
      const found=await searchGyms(filters,undefined,false,db);
      assert.equal(found.total,70,`${audience}/${term}: every existing gym needs the new estimate`);
      assert.equal(found.gyms.length,20);
      for(const gym of found.gyms as GymPlan[]){
        assert.equal(gym.duration_days,days);
        assert.equal(gym.price_basis,'model_estimate');
        assert.equal(gym.monthly,Math.round(Number(gym.price_kzt)*30/days));
      }

      const ctx:AssistantContext={db,filters,results:found.gyms.map(gym=>String(gym.id)),actions:[]};
      const comparison=await executeTool('compare_gyms',{resultPositions:[3,1]},ctx);
      const compared=comparison.gyms as GymPlan[];
      assert.deepEqual(compared.map(gym=>String(gym.id)),[ctx.results[2],ctx.results[0]]);
      assert.ok(compared.every(gym=>gym.duration_days===days));
      assert.deepEqual(comparison.unavailableIds,[]);

      const limit=audience==='premium'?40000:audience==='adult'?25000:20000;
      const budget=await searchGyms({...filters,max:limit},undefined,false,db);
      assert.ok(budget.total>0,`${audience}/${term}: monthly budget should find affordable plans`);
      assert.ok(budget.gyms.every(gym=>Number(gym.monthly)<=limit));
      assert.ok(budget.gyms.some(gym=>Number(gym.price_kzt)>limit),'budget remains a 30-day equivalent, not full purchase cost');

      const published=await searchGyms({...filters,published:'1'},undefined,false,db);
      assert.equal(published.total,0,'generated multi-month plans must never appear as published club offers');
      console.log(`PASS ${audience}/${term}: ${found.total} gyms, ${days} days, budget, source filter and ordinal comparison`);
    }
  }
  await db.query('ROLLBACK');
  console.log('PASS new subscription terms: 840 estimates, original 14 published prices preserved; no data changed');
}catch(error){
  await db.query('ROLLBACK');
  throw error;
}finally{
  db.release();
  await pool.end();
}
