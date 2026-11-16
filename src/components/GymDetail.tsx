'use client';
import {useEffect,useState} from 'react';
import {api,money,displayDate,audiences,zones,Account} from '@/lib/client';
import {formatDuration} from '@/lib/subscription-terms';

type Plan={id:string;name:string;audience:string;duration_days:number;price_kzt:number;price_basis:string;price_source_url:string|null;price_checked_on:string};
type Detail={gym:{name:string;address:string;city_zone:string;source_url:string;source_checked_on:string;geo_accuracy_m:number};plans:Plan[];reviews:{name:string;rating:number;content:string;created_at:string}[]};

export default function GymDetail({id,me,onLogin}:{id:string;me:Account|null;onLogin:()=>void}){
 const [data,setData]=useState<Detail|null>(null),[error,setError]=useState(''),[message,setMessage]=useState('');
 useEffect(()=>{api('gyms/'+id).then(setData).catch(e=>setError(e.message));},[id]);
 if(error)return <p role="alert">{error}</p>;
 if(!data)return <p>Загрузка…</p>;
 return <>
  <p className="section-label">{zones[data.gym.city_zone]} · Алматы</p>
  <h2>{data.gym.name}</h2>
  <p>{data.gym.address}</p>
  <p className="detail-source"><a href={data.gym.source_url} target="_blank" rel="noreferrer">Источник ↗</a><span>{displayDate(data.gym.source_checked_on)}</span></p>
  <h3>Абонементы</h3>
  <div className="table-wrap"><table><thead><tr><th>Категория</th><th>Срок</th><th>Цена</th><th>Источник</th></tr></thead><tbody>{data.plans.map(plan=><tr key={plan.id}>
   <td>{audiences[plan.audience]}</td>
   <td>{formatDuration(plan.duration_days)}</td>
   <td>{plan.price_basis==='published'?'':'≈ '}{money(plan.price_kzt)}</td>
   <td>{plan.price_basis==='published'?<a href={plan.price_source_url!} target="_blank" rel="noreferrer" title={`Опубликовано ${displayDate(plan.price_checked_on)}`} aria-label={`Источник цены от ${displayDate(plan.price_checked_on)}`}>{displayDate(plan.price_checked_on)} ↗</a>:'Оценка'}</td>
  </tr>)}</tbody></table></div>

  <h3>Отзывы</h3>
  {data.reviews.length?data.reviews.map((review,index)=><article className="review" key={index}><strong>{review.name} · {review.rating}/5</strong><p>{review.content}</p></article>):<p className="muted">Отзывов пока нет.</p>}
  {me?<form onSubmit={async event=>{event.preventDefault();const form=new FormData(event.currentTarget);try{await api('reviews','POST',{gymId:id,...Object.fromEntries(form)});setMessage('Отзыв отправлен');setData(await api('gyms/'+id));}catch(e){setMessage((e as Error).message);}}}>
   <label>Оценка<select name="rating" defaultValue="5">{[5,4,3,2,1].map(rating=><option key={rating}>{rating}</option>)}</select></label>
   <label>Отзыв<textarea name="content" required minLength={3} maxLength={2000}/></label>
   <button className="primary">Отправить</button>{message&&<p role="status">{message}</p>}
  </form>:<button onClick={onLogin}>Войти, чтобы оставить отзыв</button>}
 </>;
}
