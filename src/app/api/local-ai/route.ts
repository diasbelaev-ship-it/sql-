import {NextRequest,NextResponse} from 'next/server';
import {GoogleGenAI} from '@google/genai';
import {setDefaultResultOrder} from 'node:dns';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {z} from 'zod';
import {clearGeminiCooldown} from '@/lib/gemini-circuit';
export const runtime='nodejs';
function local(req:NextRequest){return ['127.0.0.1','localhost','[::1]'].includes(req.nextUrl.hostname);}
export async function GET(req:NextRequest){if(!local(req))return NextResponse.json({error:'Настройка ключа доступна только в локальном режиме разработки.'},{status:403});return NextResponse.json({configured:!!process.env.GEMINI_API_KEY,model:process.env.GEMINI_MODEL??'gemini-3.5-flash-lite'});}
export async function POST(req:NextRequest){
 if(!local(req)||req.headers.get('origin')!==(process.env.APP_ORIGIN??'http://127.0.0.1:3000'))return NextResponse.json({error:'Настройка доступна только локально с этой страницы.'},{status:403});
 if(Number(req.headers.get('content-length')??0)>2048)return NextResponse.json({error:'Слишком большой запрос'},{status:413});
 try{
  const body=z.object({apiKey:z.string().trim().min(25).max(250).regex(/^[A-Za-z0-9._-]+$/),model:z.string().regex(/^gemini-[a-zA-Z0-9._-]+$/).max(80).default('gemini-3.5-flash-lite')}).strict().parse(await req.json());
  setDefaultResultOrder('ipv4first');
  const ai=new GoogleGenAI({apiKey:body.apiKey,httpOptions:{timeout:15000}});
  try{await ai.interactions.create({model:body.model,input:'Ответь только OK',store:false,automatic_continuation:false,generation_config:{max_output_tokens:256,thinking_level:'low'}},{timeout_ms:20000,retries:{strategy:'none'}});}catch(e){const status=Number((e as {status?:number;statusCode?:number}).status??(e as {statusCode?:number}).statusCode);return NextResponse.json({error:status===401?'Google отклонил API-ключ. Создайте новый в Google AI Studio.':status===403?'У проекта нет доступа к Gemini API. Проверьте проект и ключ.':status===404?'Такая модель Gemini недоступна.':status===400?'Gemini отклонил параметры запроса. Проверьте модель.':status===429?'Квота Gemini исчерпана. Проверьте квоты проекта.':status>=500?'Gemini временно недоступен.':'Не удалось подключиться. Проверьте интернет и повторите.'},{status:400});}
  const envPath=path.join(process.cwd(),'.env.local');
  let content='';try{content=await readFile(envPath,'utf8');}catch{}
  content=content.replace(/^GEMINI_API_KEY=.*\r?\n?/gm,'').replace(/^GEMINI_MODEL=.*\r?\n?/gm,'');
  await writeFile(envPath,content.trimEnd()+'\nGEMINI_API_KEY='+body.apiKey+'\nGEMINI_MODEL='+body.model+'\n','utf8');
  process.env.GEMINI_API_KEY=body.apiKey;process.env.GEMINI_MODEL=body.model;
  clearGeminiCooldown();
  return NextResponse.json({success:true,message:'Gemini подключён. Значение ключа сохранено только на сервере.'});
 }catch(e){return NextResponse.json({error:e instanceof z.ZodError?'Проверьте полное значение ключа и название модели.':'Не удалось сохранить серверные настройки.'},{status:400});}
}
