import fs from 'node:fs';
import path from 'node:path';
import {spawn,spawnSync} from 'node:child_process';
const root=path.resolve(import.meta.dirname,'..');
const base='http://127.0.0.1:3000';
async function ready(){try{return (await fetch(base+'/api/gyms',{signal:AbortSignal.timeout(2000)})).ok;}catch{return false;}}
const db=spawnSync(process.execPath,['scripts/local-db.mjs','setup'],{cwd:root,stdio:'inherit',windowsHide:true});
if(db.status!==0)process.exit(db.status??1);
if(await ready()){console.log('GymFinder: '+base);process.exit(0);}
if(!fs.existsSync(path.join(root,'.next/BUILD_ID'))){
 const build=spawnSync(process.execPath,['node_modules/next/dist/bin/next','build'],{cwd:root,stdio:'inherit',windowsHide:true});
 if(build.status!==0)process.exit(build.status??1);
}
fs.mkdirSync(path.join(root,'.next/runtime'),{recursive:true});
const out=fs.openSync(path.join(root,'.next/runtime/server-out.log'),'a');
const server=spawn(process.execPath,['node_modules/next/dist/bin/next','start','-H','127.0.0.1'],{
 cwd:root,detached:true,stdio:['ignore',out,out],windowsHide:true,
});
server.unref();fs.closeSync(out);
for(let attempt=0;attempt<20;attempt++){
 if(await ready()){console.log('GymFinder: '+base);process.exit(0);}
 await new Promise(resolve=>setTimeout(resolve,500));
}
throw Error('Website did not start. Check .next/runtime/server-err.log');
