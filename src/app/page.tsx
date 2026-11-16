'use client';
import {useCallback,useEffect,useRef,useState} from 'react';
import dynamic from 'next/dynamic';
import Link from 'next/link';
import {ArrowUpRight,Heart,MapPin,Search,SlidersHorizontal,X,MessageCircle,Mountain,List,Map as MapIcon,LocateFixed,LogOut} from 'lucide-react';
import {api,money,displayDate,zones,audiences,Gym,Account} from '@/lib/client';
import {defaults,Filters,filtersSchema} from '@/lib/filters';
import {subscriptionTerms,matchesTerm,formatDuration} from '@/lib/subscription-terms';
import AccountDialog from '@/components/AccountDialog';
import GymDetail from '@/components/GymDetail';
import Chat from '@/components/Chat';
import type {AssistantAction} from '@/lib/assistant-client-types';
import {useRouter} from 'next/navigation';
const GymMap=dynamic(()=>import('@/components/Map'),{ssr:false,loading:()=> <p>Загружаем карту…</p>});
export default function Home(){
 const [filters,setFilters]=useState<Filters>(defaults),[ready,setReady]=useState(false),[gyms,setGyms]=useState<Gym[]>([]),[total,setTotal]=useState(0),[busy,setBusy]=useState(true),[error,setError]=useState('');
 const [me,setMe]=useState<Account|null>(null),[view,setView]=useState('list'),[section,setSection]=useState('catalog'),[dialog,setDialog]=useState<string|null>(null),[mobileFilters,setMobileFilters]=useState(false),[toast,setToast]=useState(''),[compare,setCompare]=useState<Gym[]>([]),[compareBusy,setCompareBusy]=useState(false);
 const [assistantOpen,setAssistantOpen]=useState(false);
 const assistantFiltersRef=useRef(filters);
 const router=useRouter();
 useEffect(()=>{assistantFiltersRef.current=filters;},[filters]);
 const assistantAction=async(action:AssistantAction)=>{
   if(action.type==='open_gym'){setDialog('gym:'+action.gymId);return;}
   if(action.type==='login'){setDialog('account');return;}
   if(action.type==='favorites_changed'){setFilters(f=>({...f}));return;}
   if(action.type==='view'){
     if(action.view==='sql'){router.push('/guide');return;}
     setSection(action.view==='favorites'?'favorites':'catalog');
     if(action.view==='map'||action.view==='list')setView(action.view);
     return;
   }
   if(action.type==='compare')await openComparison(action.gymIds);
 };
 const openComparison=async(ids:string[])=>{
   if(!ids.length)return;
   const f=assistantFiltersRef.current;
   setCompareBusy(true);
   try{
     const details=await Promise.all(ids.map(id=>api('gyms/'+id)));
     const selected:Gym[]=details.flatMap(d=>{
       const gym=d.gym as Gym;
       if((f.zone&&gym.city_zone!==f.zone)||(f.band&&gym.price_band!==f.band))return [];
       const query=f.q.toLocaleLowerCase('ru-RU');
       if(query&&!gym.name.toLocaleLowerCase('ru-RU').includes(query)&&!gym.address.toLocaleLowerCase('ru-RU').includes(query))return [];
       const plans=d.plans as {audience:string;duration_days:number;price_kzt:number;price_basis:string;price_checked_on:string}[];
       const plan=plans.filter(p=>p.audience===f.audience&&matchesTerm(p.duration_days,f.term)&&(!f.published||p.price_basis==='published')&&Math.round(p.price_kzt*30/p.duration_days)<=f.max).sort((a,b)=>a.price_kzt/a.duration_days-b.price_kzt/b.duration_days)[0];
       return plan?[{...gym,price_kzt:plan.price_kzt,duration_days:plan.duration_days,price_basis:plan.price_basis,price_checked_on:plan.price_checked_on,monthly:Math.round(plan.price_kzt*30/plan.duration_days)}]:[];
     });
     setCompare(selected);
     if(!selected.length){setToast('Выбранные залы не подходят под текущие фильтры');return;}
     if(selected.length<ids.length)setToast('Часть залов не подходит под текущие фильтры');
     setDialog('compare');
   }catch(e){setToast((e as Error).message);}finally{setCompareBusy(false);}
 };
 const dialogRef=useRef<HTMLDialogElement>(null);
 const update=(p:Partial<Filters>)=>setFilters(f=>({...f,...p,page:p.page??1}));
 useEffect(()=>{const parsed=filtersSchema.safeParse(Object.fromEntries(new URLSearchParams(location.search)));if(parsed.success)setFilters(parsed.data);setReady(true);api('auth/me').then(d=>setMe(d.user)).catch(()=>{});},[]);
 useEffect(()=>{if(!ready)return;const c=new AbortController();setBusy(true);setError('');const params=new URLSearchParams();Object.entries(filters).forEach(([k,v])=>{if(v!==undefined&&v!=='')params.set(k,String(v));});const shareable=new URLSearchParams(params);shareable.delete('lat');shareable.delete('lng');shareable.delete('radiusKm');if(filters.sort.startsWith('distance'))shareable.set('sort','verified');history.replaceState(null,'','?'+shareable);
 const requestParams=new URLSearchParams(params);if(view==='map')requestParams.set('map','1');
 const timer=setTimeout(()=>{fetch('/api/'+(section==='favorites'?'favorites?'+requestParams:'gyms?'+requestParams),{signal:c.signal}).then(async r=>{const d=await r.json();if(!r.ok)throw Error(d.error);return d;}).then(d=>{setGyms(d.gyms);setTotal(d.total??d.gyms.length);}).catch(e=>{if(e.name!=='AbortError')setError(e.message);}).finally(()=>{if(!c.signal.aborted)setBusy(false);});},150);return()=>{clearTimeout(timer);c.abort();};},[filters,ready,section,me,view]);
 useEffect(()=>{if(dialog){dialogRef.current?.showModal();const old=document.body.style.overflow;document.body.style.overflow='hidden';return()=>{document.body.style.overflow=old;};}else dialogRef.current?.close();},[dialog]);
 useEffect(()=>{if(!toast)return;const t=setTimeout(()=>setToast(''),4500);return()=>clearTimeout(t);},[toast]);
 const selectGym=useCallback((id:string)=>setDialog('gym:'+id),[]);
 const favorite=async(g:Gym)=>{if(!me){setDialog('account');return;}try{await api('favorites',g.favorite?'DELETE':'POST',{gymId:g.id});setGyms(gs=>section==='favorites'?gs.filter(x=>x.id!==g.id):gs.map(x=>x.id===g.id?{...x,favorite:!x.favorite}:x));setFilters(f=>({...f}));setToast(g.favorite?'Удалено из избранного':'Зал сохранён');}catch(e){setToast((e as Error).message);}};
 return <><header><Link className="brand" href="/" aria-label="GymFinder, главная"><Mountain size={37} strokeWidth={1.7}/><strong>GymFinder</strong></Link><span className="city"><MapPin size={17}/> Алматы</span><nav aria-label="Основная навигация"><button className={section==='catalog'?'active':''} onClick={()=>setSection('catalog')}>Каталог</button><button className={section==='favorites'?'active':''} onClick={()=>{if(!me)setDialog('account');else setSection('favorites');}}>Избранное</button><Link href="/guide">Возможности</Link></nav>{me?<div className="account"><span>{me.name}</span><button aria-label="Выйти" onClick={async()=>{await api('auth/logout','POST');setMe(null);setSection('catalog');setToast('Вы вышли из аккаунта');}}><LogOut size={18}/></button></div>:<button className="login" onClick={()=>setDialog('account')}>Войти <ArrowUpRight size={15}/></button>}</header>
 <main><div className="intro"><div><h1>{section==='favorites'?'Ваши любимые места':'Найдите свой зал'}</h1><p>{section==='favorites'?'Всё, что вы сохранили, — в одном месте.':'70 залов Алматы.'}</p></div><button className="assistant-launch" onClick={()=>setAssistantOpen(true)}><MessageCircle size={18}/> Помочь с выбором</button></div>
 <div className="workspace"><aside className={mobileFilters?'filters open':'filters'} aria-label="Фильтры поиска"><div className="filter-top"><h2>Ваши предпочтения</h2><button className="text-button" onClick={()=>setFilters(defaults)}>Сбросить</button></div>
 <fieldset><legend>Кто будет заниматься</legend>{Object.entries(audiences).map(([v,label])=><label className="choice" key={v}><input type="radio" name="audience" checked={filters.audience===v} onChange={()=>update({audience:v as Filters['audience']})}/>{label}</label>)}</fieldset>
 <fieldset><legend>Бюджет за 30 дней</legend><div className="budget">до <strong>{money(filters.max)}</strong></div><input aria-label="Максимальный бюджет" type="range" min="10000" max="100000" step="1000" value={Math.min(filters.max,100000)} onChange={e=>update({max:+e.target.value})}/><div className="range-label"><span>10 000 ₸</span><span>100 000 ₸</span></div><input aria-label="Точный бюджет в тенге" type="number" min="0" max="2000000" step="500" value={filters.max} onChange={e=>update({max:+e.target.value})}/></fieldset>
 <label>Срок абонемента<select value={filters.term} onChange={e=>update({term:e.target.value as Filters['term']})}>{subscriptionTerms.map(term=><option key={term.value} value={term.value}>{term.label}</option>)}</select></label>
 <label>Городская зона<select value={filters.zone} onChange={e=>update({zone:e.target.value as Filters['zone']})}><option value="">Весь Алматы</option>{Object.entries(zones).map(([v,l])=><option key={v} value={v}>{l}</option>)}</select></label>
 <label>Ценовой сегмент<select value={filters.band} onChange={e=>update({band:e.target.value as Filters['band']})}><option value="">Все сегменты</option><option value="budget">Низкий</option><option value="standard">Средний</option><option value="premium">Высокий</option></select></label>
 <label className="choice published"><input type="checkbox" checked={filters.published==='1'} onChange={e=>update({published:e.target.checked?'1':''})}/>Только опубликованные цены</label><button className="locate" onClick={()=>{if(!navigator.geolocation){setToast('Геолокация недоступна');return;}navigator.geolocation.getCurrentPosition(p=>{update({lat:p.coords.latitude,lng:p.coords.longitude,radiusKm:filters.radiusKm??5,sort:'distance'});setView('list');setToast('Залы рядом.');},e=>setToast(e.code===1?'Разрешите геолокацию в браузере.':e.code===3?'Не удалось определить местоположение вовремя. Попробуйте ещё раз.':'Не удалось получить геолокацию.'),{enableHighAccuracy:true,timeout:10000,maximumAge:30000});}}><LocateFixed size={16}/>{filters.lat!==undefined?'Обновить местоположение':'Найти залы рядом'}</button>{filters.lat!==undefined&&<><label className="radius-filter">Радиус от вас<select aria-label="Радиус поиска" value={filters.radiusKm??5} onChange={e=>update({radiusKm:+e.target.value,sort:'distance'})}>{[1,3,5,10,20].map(n=><option key={n} value={n}>{n} км</option>)}</select></label><button className="text-button" onClick={()=>{update({lat:undefined,lng:undefined,radiusKm:undefined,sort:'verified'});setToast('Поиск рядом выключен');}}>Сбросить геолокацию</button></>}
 </aside><section className="results" aria-label="Результаты поиска"><div className="toolbar"><label className="search"><Search size={19}/><input aria-label="Поиск по названию или адресу" placeholder="Название зала или адрес" value={filters.q} onChange={e=>update({q:e.target.value})}/>{filters.q&&<button aria-label="Очистить поиск" onClick={()=>update({q:''})}><X size={16}/></button>}</label><button className="mobile-toggle" onClick={()=>setMobileFilters(!mobileFilters)}><SlidersHorizontal size={18}/> Фильтры</button><label className="sort"><span className="sr-only">Сортировка</span><select value={filters.sort} onChange={e=>update({sort:e.target.value as Filters['sort']})}><option value="verified">Сначала подтверждённые</option><option value="price">Сначала доступнее</option><option value="price_desc">Сначала дороже</option><option value="name">По названию</option><option value="distance" disabled={filters.lat===undefined}>Ближе → дальше</option><option value="distance_desc" disabled={filters.lat===undefined}>Дальше → ближе</option></select></label></div>
 <div className="result-meta"><span aria-live="polite">{busy?'Ищем подходящие залы…':`${total} залов · ${audiences[filters.audience].toLowerCase()}${filters.radiusKm?` · до ${filters.radiusKm} км от вас`:''}`}</span><div className="view-switch"><button aria-label="Список" className={view==='list'?'selected':''} onClick={()=>setView('list')}><List size={16}/> Список</button><button aria-label="Карта" className={view==='map'?'selected':''} onClick={()=>setView('map')}><MapIcon size={16}/> Карта</button></div></div>
 {error?<div className="empty" role="alert"><h2>Не удалось загрузить залы</h2><p>{error}</p><button onClick={()=>setFilters({...filters})}>Повторить</button></div>:busy?<div className="loading" role="status">{[1,2,3,4].map(n=><div key={n}/>)}</div>:!gyms.length?<div className="empty"><Search size={32}/><h2>{filters.radiusKm?'Рядом нет залов в выбранном радиусе':filters.published?'Нет опубликованных тарифов по этим условиям':'Пока без совпадений'}</h2><p>{'Измените фильтры.'}</p>{filters.radiusKm&&<button onClick={()=>update({radiusKm:undefined})}>Показать весь каталог</button>}{filters.published&&<button onClick={()=>update({published:''})}>Показать оценки</button>}<button onClick={()=>setFilters(defaults)}>Сбросить фильтры</button></div>:view==='map'?<GymMap gyms={gyms} onSelect={selectGym} userLat={filters.lat} userLng={filters.lng} radiusKm={filters.radiusKm}/>:<div className="gym-list">{gyms.map((g,i)=><article className="gym-row" key={g.id}><span className="row-number">{String((filters.page-1)*20+i+1).padStart(2,'0')}</span><div className="gym-info"><span className="zone-label">{zones[g.city_zone]} · Алматы</span><button className="gym-title" onClick={()=>selectGym(g.id)}>{g.name}</button><p><MapPin size={13}/>{g.address}</p><label className="compare-choice"><input type="checkbox" checked={compare.some(x=>x.id===g.id)} onChange={e=>{if(e.target.checked&&compare.length===3){setToast('Можно сравнить до трёх залов');return;}setCompare(c=>e.target.checked?[...c,g]:c.filter(x=>x.id!==g.id));}}/>Сравнить</label></div><div className="price"><strong className={g.price_basis==='published'?'':'unverified-title'}>{g.price_basis==='published'?money(g.monthly):'≈ '+money(g.monthly)}</strong><span>{g.price_basis==='published'?`за 30 дней${g.duration_days>35?' · эквивалент':''}`:`за 30 дней · оценка`}</span>{g.price_basis==='published'&&<small className="verified">Источник · {displayDate(g.price_checked_on)}</small>}{g.duration_days>35&&<span>{g.price_basis==='published'?'':'≈ '}{money(g.price_kzt)} / {formatDuration(g.duration_days)}</span>}{g.distance!==null&&g.distance!==undefined&&<span>≈ {Number(g.distance).toFixed(1)} км от вас</span>}</div><div className="row-actions"><button aria-label={(g.favorite?'Убрать из избранного: ':'В избранное: ')+g.name} onClick={()=>favorite(g)}><Heart size={21} fill={g.favorite?'currentColor':'none'}/></button><button aria-label={'Открыть '+g.name} onClick={()=>selectGym(g.id)}><ArrowUpRight size={21}/></button></div></article>)}</div>}
 {view==='list'&&!busy&&!error&&total>20&&<div className="pagination"><button disabled={filters.page===1} onClick={()=>update({page:filters.page-1})}>← Назад</button><span>{filters.page} / {Math.ceil(total/20)}</span><button disabled={filters.page*20>=total} onClick={()=>update({page:filters.page+1})}>Далее →</button></div>}
 </section></div><footer><Link href="/guide">Возможности сайта ↗</Link></footer></main>
 {compare.length>0&&<div className="compare-bar"><span>Выбрано: {compare.length} из 3</span><button className="primary" disabled={compareBusy} onClick={()=>openComparison(compare.map(g=>g.id))}>{compareBusy?'Проверяем тарифы…':'Сравнить залы'}</button><button aria-label="Очистить сравнение" onClick={()=>setCompare([])}><X size={18}/></button></div>}
 {assistantOpen&&<aside className="assistant-dock" aria-label="Помощник сайта"><button className="close" aria-label="Закрыть помощника" onClick={()=>setAssistantOpen(false)}><X size={22}/></button><Chat key={me?.id??'guest'} ownerKey={me?.id??'guest'} context={{filters,view:section==='favorites'?'favorites':view,resultIds:!busy&&!error?gyms.map(g=>String(g.id)):undefined}} onAction={assistantAction} onFilters={f=>{assistantFiltersRef.current=f;setSection('catalog');setFilters(f);}}/></aside>}
 {toast&&<div className="toast" role="status">{toast}</div>}
 <dialog ref={dialogRef} onCancel={()=>setDialog(null)} onClick={e=>{if(e.target===e.currentTarget)setDialog(null);}}><div className="dialog-inner"><button className="close" aria-label="Закрыть" onClick={()=>setDialog(null)}><X size={23}/></button>{dialog==='account'&&<AccountDialog onDone={a=>{setMe(a);setDialog(null);setToast('Вы вошли как '+a.name);}}/>}{dialog?.startsWith('gym:')&&<GymDetail id={dialog.slice(4)} me={me} onLogin={()=>setDialog('account')}/>}{dialog==='compare'&&<><h2>Сравнение залов</h2><div className="table-wrap"><table><thead><tr><th>Зал</th><th>Зона</th><th>За 30 дней</th><th>Цена</th></tr></thead><tbody>{compare.map(g=><tr key={g.id}><td>{g.name}</td><td>{zones[g.city_zone]}</td><td>{g.price_basis==='published'?'':'≈ '}{money(g.monthly)}<br/><small>{g.price_basis==='published'?'':'≈ '}{money(g.price_kzt)} / {formatDuration(g.duration_days)}</small></td><td>{g.price_basis==='published'?`Источник · ${displayDate(g.price_checked_on)}`:''}</td></tr>)}</tbody></table></div></>}</div></dialog>
 </>;
}
