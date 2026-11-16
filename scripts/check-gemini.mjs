import {GoogleGenAI} from '@google/genai';
import {setDefaultResultOrder} from 'node:dns';
setDefaultResultOrder('ipv4first');
if(!process.env.GEMINI_API_KEY){console.log('Gemini key is not configured');process.exit(1);}
const ai=new GoogleGenAI({apiKey:process.env.GEMINI_API_KEY,httpOptions:{timeout:20000}});
try{
 const result=await ai.interactions.create({model:process.env.GEMINI_MODEL??'gemini-3.5-flash-lite',input:'Ответь только: OK',store:false,automatic_continuation:false,generation_config:{max_output_tokens:256,thinking_level:'low'}},{timeout_ms:25000,retries:{strategy:'none'}});
 console.log(JSON.stringify({connected:true,status:result.status,model:result.model}));
}catch(e){const status=e?.status??e?.statusCode??e?.code??'network_error';const reason=String(e?.message??'').replaceAll(process.env.GEMINI_API_KEY,'[REDACTED]').replace(/(?:AQ\.|AIza)[A-Za-z0-9_.-]+/g,'[REDACTED]').slice(0,700);console.log(JSON.stringify({connected:false,status,reason}));process.exitCode=1;}
