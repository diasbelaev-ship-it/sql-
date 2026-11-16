export const subscriptionTermValues=['month','2months','3months','6months','9months','year','any'] as const;
export type SubscriptionTerm=typeof subscriptionTermValues[number];

/** Calendar-length ranges; the demo's intermediate plans use 30 days per month. */
export const subscriptionTerms:readonly {value:SubscriptionTerm;label:string;minDays:number;maxDays:number}[]=[
  {value:'month',label:'1 месяц',minDays:28,maxDays:35},
  {value:'2months',label:'2 месяца',minDays:56,maxDays:62},
  {value:'3months',label:'3 месяца',minDays:84,maxDays:93},
  {value:'6months',label:'6 месяцев',minDays:168,maxDays:186},
  {value:'9months',label:'9 месяцев',minDays:252,maxDays:279},
  {value:'year',label:'1 год',minDays:365,maxDays:366},
  {value:'any',label:'Любой срок',minDays:1,maxDays:730},
];

export function getTermBounds(term:SubscriptionTerm):readonly [number,number]{
  const option=subscriptionTerms.find(option=>option.value===term)!;
  return [option.minDays,option.maxDays];
}

export function matchesTerm(days:number,term:SubscriptionTerm):boolean{
  const [min,max]=getTermBounds(term);
  return days>=min&&days<=max;
}

export function termLabel(term:SubscriptionTerm):string{
  return subscriptionTerms.find(option=>option.value===term)!.label;
}

export function formatDuration(days:number):string{
  const option=subscriptionTerms.find(option=>option.value!=='any'&&matchesTerm(days,option.value));
  return option?`${option.label} · ${days} дней`:`${days} дней`;
}
