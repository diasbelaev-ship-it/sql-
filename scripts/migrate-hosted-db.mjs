import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import pg from 'pg';

const {Pool}=pg;
const projectRoot=fileURLToPath(new URL('../',import.meta.url));
const lockId=717261211;

export const MIGRATION_FILES=Object.freeze([
  {name:'001_schema.sql',path:'db/migrations/001_schema.sql'},
  {name:'002_views_indexes.sql',path:'db/migrations/002_views_indexes.sql'},
  {name:'10_real_gyms.sql',path:'db/seed/10_real_gyms.sql'},
  {name:'20_demo_activity.sql',path:'db/seed/20_demo_activity.sql'},
  {name:'003_web.sql',path:'db/migrations/003_web.sql'},
  {name:'004_assistant.sql',path:'db/migrations/004_assistant.sql'},
  {name:'005_subscription_terms.sql',path:'db/migrations/005_subscription_terms.sql'},
  {name:'006_verified_venues.sql',path:'db/migrations/006_verified_venues.sql'}
]);

function getDatabaseUrl(env){
  const value=env.DATABASE_URL?.trim();
  if(!value)throw new Error('DATABASE_URL is required to initialize the hosted database.');
  try{
    const url=new URL(value);
    if(!['postgres:','postgresql:'].includes(url.protocol)||!url.hostname)throw new Error();
  }catch{
    throw new Error('DATABASE_URL must be a valid PostgreSQL connection URL.');
  }
  return value;
}

function safeCode(error){
  const code=error&&typeof error==='object'?'code' in error?error.code:undefined:undefined;
  return typeof code==='string'&&/^[A-Z0-9_]{3,20}$/.test(code)?code:'UNKNOWN';
}

/**
 * @param {{env?:Record<string,string|undefined>,poolFactory?:(url:string)=>any,readMigration?:(file:string)=>Promise<string>}} [options]
 */
export async function runMigrations(options={}){
  const env=options.env??process.env;
  const connectionString=getDatabaseUrl(env);
  const poolFactory=options.poolFactory??((url)=>new Pool({connectionString:url,max:1,connectionTimeoutMillis:30000}));
  const readMigration=options.readMigration??((file)=>readFile(path.join(projectRoot,file),'utf8'));
  let pool;
  let client;
  let phase='database connection';
  let inTransaction=false;
  try{
    pool=poolFactory(connectionString);
    client=await pool.connect();
    await client.query('BEGIN');
    inTransaction=true;
    await client.query('SELECT pg_advisory_xact_lock($1)',[lockId]);
    phase='database inspection';
    const schemas=await client.query(`SELECT to_regnamespace('almaty_gym') AS gym_schema,
      to_regnamespace('gym_web') AS web_schema`);
    const projectSchemaPresent=Boolean(schemas.rows[0]?.gym_schema||schemas.rows[0]?.web_schema);
    phase='migration ledger';
    await client.query(`CREATE TABLE IF NOT EXISTS public.gymfinder_schema_migrations (
      name text PRIMARY KEY,
      applied_at timestamptz NOT NULL DEFAULT now()
    )`);
    const result=await client.query('SELECT name FROM public.gymfinder_schema_migrations');
    const appliedNames=new Set(result.rows.map(row=>row.name));
    if(projectSchemaPresent&&appliedNames.size===0){
      throw Object.assign(new Error('GymFinder schemas already exist without a migration history.'),{code:'DATABASE_NOT_EMPTY'});
    }
    const applied=[];
    const skipped=[];
    for(const file of MIGRATION_FILES){
      if(appliedNames.has(file.name)){
        skipped.push(file.name);
        continue;
      }
      phase=file.name;
      const sql=await readMigration(file.path);
      await client.query(sql);
      await client.query('INSERT INTO public.gymfinder_schema_migrations(name) VALUES($1)',[file.name]);
      applied.push(file.name);
    }
    await client.query('COMMIT');
    inTransaction=false;
    return {applied,skipped};
  }catch(error){
    if(inTransaction&&client){
      try{await client.query('ROLLBACK');}catch{}
    }
    const detail=phase==='database connection'
      ?'No database changes were applied.'
      :'The migration transaction was rolled back.';
    throw new Error(`Hosted database migration failed during ${phase} (${safeCode(error)}). ${detail} Check DATABASE_URL and database access.`);
  }finally{
    try{client?.release();}catch{}
    try{await pool?.end();}catch{}
  }
}

if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  runMigrations().then(result=>{
    console.log(`Database initialized: ${result.applied.length} migrations applied, ${result.skipped.length} already applied.`);
  }).catch(error=>{
    console.error(error instanceof Error?error.message:'Hosted database migration failed.');
    process.exitCode=1;
  });
}
