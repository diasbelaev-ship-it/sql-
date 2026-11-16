import fs from 'node:fs';
import path from 'node:path';
import {spawn,spawnSync} from 'node:child_process';
import pg from 'pg';
import {randomBytes} from 'node:crypto';
const root=path.resolve(import.meta.dirname,'..'),data=path.join(root,'.local-db');
const bin=process.env.PG_BIN??'C:/Program Files/PostgreSQL/18/bin';
const exe=n=>process.platform==='win32'?path.join(bin,n+'.exe'):n;
const port=Number(process.env.PGPORT??55443);
const url=process.env.DATABASE_URL??`postgresql://postgres@127.0.0.1:${port}/gymfinder_almaty`;
async function connect(database='gymfinder_almaty'){const u=new URL(url);u.pathname='/'+database;const c=new pg.Client({connectionString:u.toString()});await c.connect();return c;}
if(process.argv[2]==='stop'){
 const r=spawnSync(exe('pg_ctl'),['-D',data,'-m','fast','stop'],{stdio:'inherit',windowsHide:true});process.exit(r.status??1);
}
if(!fs.existsSync(path.join(data,'PG_VERSION'))){const r=spawnSync(exe('initdb'),['-D',data,'-A','trust','-U','postgres','-E','UTF8','--no-instructions'],{stdio:'inherit',windowsHide:true});if(r.status!==0)process.exit(r.status??1);}
let admin;
try{admin=await connect('postgres');}catch{
 // pg_ctl starts one detached server process and waits for readiness. Spawning
 // postgres once per retry could otherwise leave dozens of server processes.
 const started=spawnSync(exe('pg_ctl'),[
  '-D',data,'-o',`-p ${port} -h 127.0.0.1`,'-l',path.join(data,'server-err.log'),'-w','-t','180','start',
 ],{cwd:root,stdio:'ignore',windowsHide:true,timeout:210_000,encoding:'utf8'});
 for(let n=0;n<40;n++){await new Promise(r=>setTimeout(r,250));try{admin=await connect('postgres');break;}catch{}}
 if(!admin&&(started.error||started.status!==0))throw Error(`pg_ctl завершился с ошибкой (${started.error?.message??started.status}). Проверьте .local-db/server-err.log`);
}
if(!admin)throw Error('PostgreSQL не запустился. Проверьте .local-db/server.log');
const exists=await admin.query("SELECT 1 FROM pg_database WHERE datname='gymfinder_almaty'");
if(!exists.rowCount)await admin.query('CREATE DATABASE gymfinder_almaty');await admin.end();
const c=await connect();
const has=await c.query("SELECT to_regclass('almaty_gym.gyms') t");
if(!has.rows[0].t){await c.query('BEGIN');try{for(const f of ['db/migrations/001_schema.sql','db/migrations/002_views_indexes.sql','db/seed/10_real_gyms.sql','db/seed/20_demo_activity.sql'])await c.query(fs.readFileSync(path.join(root,f),'utf8'));await c.query('COMMIT');}catch(e){await c.query('ROLLBACK');throw e;}}
await c.query(fs.readFileSync(path.join(root,'db/migrations/003_web.sql'),'utf8'));
await c.query(fs.readFileSync(path.join(root,'db/migrations/004_assistant.sql'),'utf8'));
await c.query(fs.readFileSync(path.join(root,'db/migrations/005_subscription_terms.sql'),'utf8'));
await c.query(fs.readFileSync(path.join(root,'db/migrations/006_verified_venues.sql'),'utf8'));
const envPath=path.join(root,'.env.local');
const oldEnv=fs.existsSync(envPath)?fs.readFileSync(envPath,'utf8'):'';
if(!oldEnv||oldEnv.includes('postgresql://postgres@')){
 const password=randomBytes(24).toString('hex');
 const role=await c.query("SELECT 1 FROM pg_roles WHERE rolname='gymfinder_almaty_site'");
 await c.query(`${role.rowCount?'ALTER':'CREATE'} ROLE gymfinder_almaty_site LOGIN PASSWORD '${password}'`);
 await c.query('GRANT USAGE ON SCHEMA almaty_gym,gym_web TO gymfinder_almaty_site; GRANT SELECT ON ALL TABLES IN SCHEMA almaty_gym TO gymfinder_almaty_site; GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA gym_web TO gymfinder_almaty_site; GRANT USAGE ON ALL SEQUENCES IN SCHEMA gym_web TO gymfinder_almaty_site');
 const appUrl=new URL(url);appUrl.username='gymfinder_almaty_site';appUrl.password=password;
 fs.writeFileSync(envPath,`DATABASE_URL=${appUrl}\nAPP_ORIGIN=http://127.0.0.1:3000\n`);
}
await c.end();
console.log('PostgreSQL готов. Данные сохранены. Запуск сайта: npm run site:start');
