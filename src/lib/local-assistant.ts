import { parsePhrase } from './filters';
import { executeTool,type AssistantContext } from './assistant-tools';
import { requestsRecommendations } from './assistant-intents';
const positionWords:Record<string,number>={'перв':1,'втор':2,'трет':3};
export async function runLocal(message:string,ctx:AssistantContext){
  const text=message.toLowerCase();
  const positions=Object.entries(positionWords).filter(([word])=>text.includes(word)).map(([,n])=>n);
  const parsed=parsePhrase(message,ctx.filters);
  const recommends=requestsRecommendations(message);
  let answer:string;
  if(/сравни/.test(text)){
    const result=await executeTool('compare_gyms',positions.length?{resultPositions:positions}:{},ctx);
    answer=Array.isArray(result.gyms)&&result.gyms.length?result.gyms.map(g=>`${g.name}: ${g.price_kzt} ₸ / ${g.duration_days} дней (≈ ${g.monthly} ₸ за 30 дней; ${g.price_basis==='published'?'источник':'оценка'}).`).join('\n'):'Сначала найдите залы.';
  }else if(/карт[ауе]/.test(text)){
    await executeTool('navigate_site',{view:'map'},ctx);answer='Открываю карту.';
  }else if(/избранн/.test(text)&&!/добав|сохран|убер|удал/.test(text)){
    const result=await executeTool('list_favorites',{},ctx);answer=result.ok?'Открываю ваше избранное.':'Для доступа к избранному войдите в аккаунт.';
  }else if(/открой|покажи подроб/.test(text)&&positions.length&&ctx.results[positions[0]-1]){
    await executeTool('open_gym',{gymId:ctx.results[positions[0]-1]},ctx);answer='Карточка зала готова к открытию.';
  }else if(recommends){
    const found=await executeTool('search_gyms',{filters:parsed.filters},ctx);
    const gyms=Array.isArray(found.gyms)?found.gyms.slice(0,3):[];
    if(!gyms.length)answer='Подходящих залов нет.';
    else {
      const money=(n:unknown)=>Number(n).toLocaleString('ru-RU')+' ₸';
      const options=gyms.map((g,i)=>`${i+1}. ${g.name} — ${money(g.monthly)}/мес. · ${g.address} · ${g.price_basis==='published'?'источник':'оценка'}${Number(g.duration_days)>35?` · абонемент ${money(g.price_kzt)} за ${g.duration_days} дней`:''}`);
      answer='Варианты:\n'+options.join('\n');
      if(/рядом|поблизости/.test(text))answer+=ctx.filters.lat===undefined?'\nНажмите «Найти залы рядом».':`\nРадиус: ${ctx.filters.radiusKm??'без ограничений'} км.`;
    }
  }else if(parsed.recognized){
    const found=await executeTool('search_gyms',{filters:parsed.filters},ctx);
    answer=found.total?`Найдено: ${found.total}.`:'Залы не найдены.';
  }else answer='Попробуйте: «Студент до 20к», «Сравни первый и третий» или «Покажи карту».';
  return {answer,provider:'local' as const};
}
