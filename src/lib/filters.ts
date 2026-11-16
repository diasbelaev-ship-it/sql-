import { z } from 'zod';
import {subscriptionTermValues,type SubscriptionTerm} from './subscription-terms';
export const filtersSchema=z.object({
 q:z.string().max(120).default(''), audience:z.enum(['student','adult','premium']).default('adult'),
 term:z.enum(subscriptionTermValues).default('month'), zone:z.enum(['','west','north','center','south']).default(''),
 band:z.enum(['','budget','standard','premium']).default(''),
 max:z.coerce.number().int().min(0).max(2000000).default(100000), published:z.enum(['','1']).default(''),
 sort:z.enum(['verified','price','price_desc','name','distance','distance_desc']).default('verified'),
 lat:z.coerce.number().min(-90).max(90).optional(), lng:z.coerce.number().min(-180).max(180).optional(),
 radiusKm:z.coerce.number().int().min(1).max(50).optional(),
 page:z.coerce.number().int().min(1).max(10000).default(1)
}).refine(f=>(f.lat===undefined)===(f.lng===undefined),'Укажите обе координаты')
 .refine(f=>!f.sort.startsWith('distance')||f.lat!==undefined,'Для расстояния нужна геолокация')
 .refine(f=>f.radiusKm===undefined||f.lat!==undefined,'Для радиуса нужна геолокация');
export type Filters=z.infer<typeof filtersSchema>;
export const defaults=filtersSchema.parse({});
export function parsePhrase(text:string, previous:Partial<Filters>={}) {
 const t=text.toLowerCase().replace(/ё/g,'е');
 const patch:Partial<Filters>={};
 if(/студент/.test(t))patch.audience='student';
 if(/взросл|обычн/.test(t))patch.audience='adult';
 if(/преми|состоятельн/.test(t))patch.audience='premium';
 const months=t.match(/(?:^|[^\dа-я])(12|1|2|3|6|9|двенадцать|один|одна|два|две|три|шесть|девять)\s*(?:месяц(?:а|ев)?|мес\.?)(?![а-яa-z0-9])/);
 const monthTerms:Record<string,SubscriptionTerm>={'1':'month',один:'month',одна:'month','2':'2months',два:'2months',две:'2months','3':'3months',три:'3months','6':'6months',шесть:'6months','9':'9months',девять:'9months','12':'year',двенадцать:'year'};
 if(/любой срок|без ограничени[яй] срока/.test(t))patch.term='any';
 else if(months)patch.term=monthTerms[months[1]];
 else if(/двухмесячн/.test(t))patch.term='2months';
 else if(/трехмесячн|квартал/.test(t))patch.term='3months';
 else if(/полгода|полугод|шестимесячн/.test(t))patch.term='6months';
 else if(/девятимесячн/.test(t))patch.term='9months';
 else if(/годов|на год|двенадцатимесячн/.test(t))patch.term='year';
 else if(/месячн|на месяц/.test(t))patch.term='month';
 const budget=t.match(/(?:до|бюджет)\s*(\d[\d ]*)(?:\s*(тыс|к))?/);
 if(budget)patch.max=Number(budget[1].replaceAll(' ',''))*(budget[2]?1000:1);
 if(/дешев|недорог/.test(t)){patch.sort='price';}
 if(/дороже|дорогие/.test(t))patch.sort='price_desc';
 if(/опублик|подтвержден/.test(t))patch.published='1';
 if(/запад|аксай/.test(t))patch.zone='west';
 if(/центр/.test(t))patch.zone='center';
 if(/юг/.test(t))patch.zone='south';
 if(/север/.test(t))patch.zone='north';
 const reset=/сброс|заново/.test(t);
 return {filters:filtersSchema.parse({...defaults,...(reset?{}:previous),...patch,page:1}),recognized:reset||Object.keys(patch).length>0,patch:reset?defaults:patch};
}
