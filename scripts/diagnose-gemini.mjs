const key=process.env.GEMINI_API_KEY;
if(!key)throw Error('Key is missing');
const r=await fetch('https://generativelanguage.googleapis.com/v1beta/models',{headers:{'x-goog-api-key':key},signal:AbortSignal.timeout(15000)});
const d=await r.json();
const reason=String(d.error?.message??'').replaceAll(key,'[REDACTED]').replace(/(?:AQ\.|AIza)[A-Za-z0-9_.-]+/g,'[REDACTED]');
console.log(JSON.stringify({status:r.status,reason,models:d.models?.map(m=>m.name).filter(n=>/flash/.test(n)).slice(0,10)}));
