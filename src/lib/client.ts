export type Gym={id:string;name:string;address:string;city_zone:string;price_band:string;latitude:string;longitude:string;geo_accuracy_m:number;monthly:number;price_kzt:number;duration_days:number;price_basis:string;price_checked_on:string;favorite:boolean;source_url:string;distance:number|null};
export type Account={id:string;name:string;email:string};
export const money=(v:number)=>new Intl.NumberFormat('ru-RU').format(v)+' ₸';
export const displayDate=(value:string)=>value.slice(0,10).split('-').reverse().join('.');
export const zones:Record<string,string>={west:'Запад',north:'Север',center:'Центр',south:'Юг'};
export const audiences:Record<string,string>={student:'Студент',adult:'Взрослый',premium:'Премиум'};
export async function api(path:string,method='GET',body?:unknown){const res=await fetch('/api/'+path,{method,headers:body?{'Content-Type':'application/json'}:undefined,body:body?JSON.stringify(body):undefined});const data=await res.json();if(!res.ok)throw Error(data.error??'Не удалось выполнить запрос');return data;}
