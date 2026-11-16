'use client';

import {useEffect,useRef,useState} from 'react';
import {ArrowUpRight,Check,Heart,MapPin,MessageCircle,RefreshCcw,Sparkles} from 'lucide-react';
import {api,money} from '@/lib/client';
import type {Gym} from '@/lib/client';
import {filtersSchema} from '@/lib/filters';
import {humanizeAssistantText} from '@/lib/assistant-format';
import type {Filters} from '@/lib/filters';
import type {AssistantAction,AssistantPageContext,AssistantResponse,PendingReview} from '@/lib/assistant-client-types';

type Message = {
  role:'user'|'assistant'; text:string; provider?:'gemini'|'local';
  gyms?:Gym[]; actions?:AssistantAction[];
};

const greeting:Message = {
  role:'assistant',
  text:'Найду и сравню залы, покажу карту и избранное.',
};
const suggestions=['Студент до 20к','Сравни первый и третий','Покажи карту','Моё избранное'];
const sessionPattern=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function cachedMessages(value:unknown):Message[]{
  if(!Array.isArray(value))return [];
  return value.filter((item):item is Message=>Boolean(item)&&typeof item==='object'
    &&(item.role==='user'||item.role==='assistant')&&typeof item.text==='string'
    &&item.text.length<=16000).slice(-60).map(item=>({
      role:item.role,text:humanizeAssistantText(item.text),
      ...(item.provider==='gemini'||item.provider==='local'?{provider:item.provider}:{}),
    }));
}

function actionLabel(action:AssistantAction){
  if(action.type==='open_gym')return 'Карточка зала открыта';
  if(action.type==='compare')return `Сравнение: ${action.gymIds.length} зала`;
  if(action.type==='login')return 'Нужен вход в аккаунт';
  if(action.type==='favorites_changed')return 'Избранное обновлено';
  return {catalog:'Каталог',favorites:'Избранное',map:'Карта',list:'Список залов',sql:'Возможности'}[action.view];
}

function messageText(text:string){
  return text.split(/(\*\*[^*\n]+\*\*)/g).map((part,index)=>part.startsWith('**')&&part.endsWith('**')?<strong key={index}>{part.slice(2,-2)}</strong>:part);
}

export default function Chat({onFilters,ownerKey,onAction,context}:{
  onFilters:(filters:Filters)=>void;
  ownerKey:string;
  onAction?:(action:AssistantAction)=>void|Promise<void>;
  context?:AssistantPageContext;
}){
  const [messages,setMessages]=useState<Message[]>([greeting]);
  const [input,setInput]=useState('');
  const [session,setSession]=useState<string>();
  const [provider,setProvider]=useState<'gemini'|'local'>();
  const [busy,setBusy]=useState(false);
  const [loaded,setLoaded]=useState(false);
  const [error,setError]=useState('');
  const [providerNotice,setProviderNotice]=useState('');
  const [pendingReview,setPendingReview]=useState<PendingReview|null>(null);
  const cacheKey='gym-chat:v2:'+ownerKey;
  const inFlight=useRef(false);
  const logRef=useRef<HTMLDivElement>(null);
  const inputRef=useRef<HTMLInputElement>(null);
  const lastFilters=useRef<string|undefined>(undefined);

  useEffect(()=>{
    try{
      const raw=sessionStorage.getItem(cacheKey);
      if(raw){
        const cache=JSON.parse(raw) as {session?:unknown;messages?:unknown};
        const restored=cachedMessages(cache.messages);
        if(typeof cache.session==='string'&&sessionPattern.test(cache.session))setSession(cache.session);
        if(restored.length){
          setMessages(restored);
          setProvider(restored.findLast(message=>message.provider)?.provider);
        }
      }
    }catch{/* A denied or corrupted browser cache must not block the assistant. */}
    setLoaded(true);
  },[cacheKey]);

  useEffect(()=>{
    if(!loaded)return;
    try{
      // Drafts and confirmation identifiers are never saved in browser storage.
      sessionStorage.setItem(cacheKey,JSON.stringify({session,messages:cachedMessages(messages)}));
    }catch{/* Continue without persistence when storage is unavailable. */}
  },[loaded,session,messages,cacheKey]);

  useEffect(()=>{
    const log=logRef.current;
    if(!log)return;
    const latest=log.lastElementChild;
    if(!busy&&messages.at(-1)?.role==='assistant'&&latest){
      // Show the start of the answer; the attached gym cards can be much taller than the viewport.
      log.scrollTop+=latest.getBoundingClientRect().top-log.getBoundingClientRect().top;
    }else log.scrollTop=log.scrollHeight;
  },[messages,busy,pendingReview]);

  async function applyResponse(response:AssistantResponse){
    setSession(response.sessionId);
    setProvider(response.provider);
    setProviderNotice(response.providerNotice??'');
    setPendingReview(response.pendingReview??null);
    setMessages(previous=>[...previous,{
      role:'assistant',text:response.answer,provider:response.provider,
      gyms:response.gyms?.slice(0,20),actions:response.actions,
    }]);
    if(response.filters){
      const parsed=filtersSchema.safeParse(response.filters);
      if(parsed.success){
        const next=JSON.stringify(parsed.data);
        const current=context?JSON.stringify(context.filters):lastFilters.current;
        if(next!==current){onFilters(parsed.data);lastFilters.current=next;}
      }
    }
    for(const action of response.actions??[])await onAction?.(action);
  }

  async function send(text:string){
    const message=text.trim();
    if(inFlight.current||!loaded||!message||message.length>2000)return;
    inFlight.current=true;setBusy(true);setError('');setInput('');
    setMessages(previous=>[...previous,{role:'user',text:message}]);
    try{
      const response=await api('chat','POST',{message,sessionId:session,context}) as AssistantResponse;
      await applyResponse(response);
    }catch(cause){
      setError(cause instanceof Error?cause.message:'Не удалось связаться с помощником. Попробуйте ещё раз.');
    }finally{inFlight.current=false;setBusy(false);inputRef.current?.focus();}
  }

  async function decideReview(decision:'confirm'|'cancel'){
    if(inFlight.current||!session||!pendingReview)return;
    inFlight.current=true;setBusy(true);setError('');
    try{
      const response=await api('chat','POST',{
        sessionId:session,confirmationId:pendingReview.confirmationId,decision,
      }) as AssistantResponse;
      setPendingReview(null);await applyResponse(response);
    }catch(cause){
      setError(cause instanceof Error?cause.message:'Не удалось обработать подтверждение.');
    }finally{inFlight.current=false;setBusy(false);}
  }

  function newChat(){
    if(inFlight.current)return;
    setSession(undefined);setProvider(undefined);setPendingReview(null);setError('');setProviderNotice('');
    setMessages([greeting]);lastFilters.current=undefined;inputRef.current?.focus();
  }

  return <section className="assistant" aria-label="AI-помощник GymFinder">
    <div className="assistant-heading">
      <div><span className="assistant-label"><Sparkles size={15}/> Помощник GymFinder</span><h2>Скажите, что нужно сделать</h2></div>
      <button className="text-button assistant-reset" disabled={busy} onClick={newChat}><RefreshCcw size={14}/> Новый диалог</button>
    </div>
    <p className="assistant-description">{provider==='gemini'?'Gemini':provider==='local'?'Локальный режим':'Поиск · карта · избранное'}</p>
    {providerNotice&&<p className="assistant-provider-notice" role="status">{providerNotice} <a href="/settings/ai">Проверить Gemini</a></p>}
    <div className="chat-log assistant-log" ref={logRef} role="log" aria-label="История диалога" aria-live="polite" aria-busy={busy}>
      {messages.map((message,index)=><article className={'assistant-message '+message.role} key={index}>
        {message.role==='assistant'&&<span className="assistant-speaker">{message.provider==='gemini'?'Gemini':message.provider==='local'?'Помощник · локально':'GymFinder'}</span>}
        <p className={'bubble '+message.role}>{messageText(message.text)}</p>
        {Boolean(message.actions?.length)&&<div className="assistant-action-list" aria-label="Выполненные действия">{message.actions?.map((action,actionIndex)=><span key={actionIndex}><Check size={12}/>{actionLabel(action)}</span>)}</div>}
        {Boolean(message.gyms?.length)&&<div className="assistant-gyms" aria-label="Залы из ответа">{message.gyms?.map((gym,gymIndex)=><div className="assistant-gym" key={gym.id}>
          <span className="assistant-gym-number">{gymIndex+1}</span><div className="assistant-gym-info"><button type="button" onClick={()=>onAction?.({type:'open_gym',gymId:String(gym.id)})}>{gym.name}<ArrowUpRight size={14}/></button><p><MapPin size={12}/>{gym.address}</p><span>{money(Number(gym.monthly))} за 30 дней · {gym.price_basis==='published'?'из источника':'учебная оценка'}</span></div>
          <button type="button" className="assistant-save" aria-label={'Сохранить в избранное: '+gym.name} disabled={busy} onClick={()=>send('Добавь зал «'+gym.name+'» в моё избранное')}><Heart size={17}/></button>
        </div>)}</div>}
      </article>)}
      {busy&&<p className="assistant-working" role="status"><MessageCircle size={16}/>{pendingReview?'Выполняю…':'Ищу…'}</p>}
    </div>
    {pendingReview&&<section className="assistant-review" aria-labelledby="review-confirm-title">
      <h3 id="review-confirm-title">Подтвердите отзыв</h3>
      <p className="assistant-review-gym">{pendingReview.gymName} · {pendingReview.rating}/5</p>
      <blockquote>{pendingReview.content}</blockquote>
      <p className="assistant-review-note">Отзыв будет опубликован от вашего имени.</p>
      <div className="assistant-review-actions"><button type="button" className="primary" disabled={busy} onClick={()=>decideReview('confirm')}>Опубликовать отзыв</button><button type="button" disabled={busy} onClick={()=>decideReview('cancel')}>Отменить</button></div>
    </section>}
    {error&&<p className="error assistant-error" role="alert">{error}</p>}
    <div className="suggestions assistant-suggestions">{suggestions.map(text=><button type="button" key={text} disabled={busy||!loaded} onClick={()=>send(text)}>{text}</button>)}</div>
    <form className="chat-input" onSubmit={event=>{event.preventDefault();void send(input);}}>
      <label className="sr-only" htmlFor="chat-message">Сообщение</label><input ref={inputRef} id="chat-message" value={input} onChange={event=>setInput(event.target.value)} maxLength={2000} placeholder="Например: сравни первый и третий зал" disabled={!loaded}/>
      <button className="primary" disabled={busy||!loaded||!input.trim()}>Отправить</button>
    </form>
  </section>;
}
