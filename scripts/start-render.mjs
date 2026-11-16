import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';

/** @param {string|undefined} value */
export function getRenderPort(value){
  if(typeof value!=='string'||!/^\d+$/.test(value.trim()))return 3000;
  const port=Number(value.trim());
  return Number.isSafeInteger(port)&&port>=1&&port<=65535?port:3000;
}

/** @param {Record<string,string|undefined>} [env] */
export function getRenderStartArgs(env=process.env){
  return ['start','-H','0.0.0.0','-p',String(getRenderPort(env.PORT))];
}

const nextCli=fileURLToPath(new URL('../node_modules/next/dist/bin/next',import.meta.url));

/** @param {Record<string,string|undefined>} [env] */
export function getRenderCommand(env=process.env){
  return {command:process.execPath,args:[nextCli,...getRenderStartArgs(env)]};
}

function startRender(){
  const env=process.env;
  const {command,args}=getRenderCommand(env);
  const child=spawn(command,args,{stdio:'inherit',env});
  const signals=['SIGINT','SIGTERM'];
  const forwardSignal=(signal)=>child.kill(signal);
  const removeSignalHandlers=()=>{
    for(const signal of signals)process.removeListener(signal,handlers[signal]);
  };
  const handlers=Object.fromEntries(signals.map(signal=>[signal,()=>forwardSignal(signal)]));
  for(const signal of signals)process.on(signal,handlers[signal]);
  child.once('error',(error)=>{
    removeSignalHandlers();
    console.error('Не удалось запустить сервер Next.js.',error.code??'UNKNOWN');
    process.exitCode=1;
  });
  child.once('exit',(code,signal)=>{
    removeSignalHandlers();
    process.exitCode=code??(signal?0:1);
  });
  return child;
}

if(process.argv[1]&&fileURLToPath(import.meta.url)===process.argv[1])startRender();
