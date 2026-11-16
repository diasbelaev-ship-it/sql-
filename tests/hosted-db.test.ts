import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {MIGRATION_FILES,runMigrations} from '../scripts/migrate-hosted-db.mjs';

const databaseUrl='postgresql://deploy-user:do-not-log@localhost:5432/gymfinder_test';

function fakePool(initiallyApplied:string[]=[],projectSchemas:{gymSchema?:string|null,webSchema?:string|null}={}){
  const applied=new Set(initiallyApplied);
  const queries:{sql:string,values?:unknown[]}[]=[];
  const pool={
    async connect(){
      return {
        async query(sql:string,values?:unknown[]){
          queries.push({sql,values});
          if(sql.includes('SELECT name FROM public.gymfinder_schema_migrations')){
            return {rows:[...applied].map(name=>({name})),rowCount:applied.size};
          }
          if(sql.includes('to_regnamespace')){
            return {rows:[{gym_schema:projectSchemas.gymSchema??null,web_schema:projectSchemas.webSchema??null}],rowCount:1};
          }
          if(sql.includes('INSERT INTO public.gymfinder_schema_migrations')){
            applied.add(String(values?.[0]));
          }
          return {rows:[],rowCount:0};
        },
        release(){}
      };
    },
    async end(){}
  };
  return {pool,queries,applied};
}

test('hosted migrations use the dependency-safe schema, seed and web order',()=>{
  assert.deepEqual(MIGRATION_FILES.map(item=>item.path),[
    'db/migrations/001_schema.sql',
    'db/migrations/002_views_indexes.sql',
    'db/seed/10_real_gyms.sql',
    'db/seed/20_demo_activity.sql',
    'db/migrations/003_web.sql',
    'db/migrations/004_assistant.sql',
    'db/migrations/005_subscription_terms.sql',
    'db/migrations/006_verified_venues.sql'
  ]);
});

test('pending schema, seed and web SQL runs once in one locked transaction',async()=>{
  const fake=fakePool();
  const result=await runMigrations({env:{DATABASE_URL:databaseUrl},poolFactory:()=>fake.pool});
  const migrationSql=await Promise.all(MIGRATION_FILES.map(item=>readFile(item.path,'utf8')));
  const queries=fake.queries.map(item=>item.sql);
  assert.deepEqual(result.applied,MIGRATION_FILES.map(item=>item.name));
  assert.deepEqual(queries.filter(sql=>migrationSql.includes(sql)),migrationSql);
  assert.equal(queries[0],'BEGIN');
  assert.match(queries[1],/pg_advisory_xact_lock/);
  assert.equal(queries.at(-1),'COMMIT');
});

test('a second run skips migrations already recorded in the ledger',async()=>{
  const fake=fakePool();
  await runMigrations({env:{DATABASE_URL:databaseUrl},poolFactory:()=>fake.pool});
  const migrationSql=await Promise.all(MIGRATION_FILES.map(item=>readFile(item.path,'utf8')));
  const firstRunCount=fake.queries.filter(item=>migrationSql.includes(item.sql)).length;
  const result=await runMigrations({env:{DATABASE_URL:databaseUrl},poolFactory:()=>fake.pool});
  assert.equal(firstRunCount,MIGRATION_FILES.length);
  assert.deepEqual(result.applied,[]);
  assert.deepEqual(result.skipped,MIGRATION_FILES.map(item=>item.name));
});

test('an existing GymFinder schema without migration history is left untouched',async()=>{
  const fake=fakePool([],{gymSchema:'almaty_gym'});
  await assert.rejects(runMigrations({env:{DATABASE_URL:databaseUrl},poolFactory:()=>fake.pool}),error=>{
    assert.match((error as Error).message,/DATABASE_NOT_EMPTY/);
    assert.equal((error as Error).message.includes(databaseUrl),false);
    return true;
  });
  assert.equal(fake.queries.some(item=>item.sql.includes('TRUNCATE TABLE')),false);
  assert.equal(fake.queries.at(-1)?.sql,'ROLLBACK');
});

test('missing or malformed DATABASE_URL fails before creating a database pool',async()=>{
  let poolCreated=false;
  for(const env of [{},{DATABASE_URL:'http://not-postgres.example'}]){
    await assert.rejects(runMigrations({env,poolFactory:()=>{poolCreated=true;throw new Error('must not connect');}}),/DATABASE_URL/);
  }
  assert.equal(poolCreated,false);
});

test('connection failures expose a safe code but never the URL or driver message',async()=>{
  const secretUrl='postgresql://deploy-user:very-secret@private-host.invalid:5432/db';
  const driverError=Object.assign(new Error(`connect EHOSTUNREACH private-host.invalid for ${secretUrl}`),{code:'ECONNREFUSED'});
  const pool={async connect(){throw driverError;},async end(){}};
  await assert.rejects(runMigrations({env:{DATABASE_URL:secretUrl},poolFactory:()=>pool}),error=>{
    assert.match((error as Error).message,/ECONNREFUSED/);
    assert.equal((error as Error).message.includes(secretUrl),false);
    assert.equal((error as Error).message.includes('very-secret'),false);
    assert.equal((error as Error).message.includes('private-host.invalid'),false);
    return true;
  });
});
