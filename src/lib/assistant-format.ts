const internalLabels:Record<string,string>={
  model_estimate:'учебная оценка',published:'цена из источника',price_basis:'источник цены',
  price_kzt:'цена тарифа',monthly:'цена за 30 дней',duration_days:'срок в днях',
  radiuskm:'радиус поиска',resultids:'выбранные залы',
};

/** Keep database and API enum labels out of both new and cached assistant messages. */
export function humanizeAssistantText(text:string):string {
  const alreadyExplainsEstimates=/учебн|оценк/i.test(text);
  return text.replace(/\b(model_estimate|published|price_basis|price_kzt|monthly|duration_days|radiusKm|resultIds)\b/gi,label=>{
    if(label.toLowerCase()==='model_estimate'&&alreadyExplainsEstimates)return '';
    return internalLabels[label.toLowerCase()]??label;
  }).replace(/`{1,2}\s*`{1,2}/g,'').replace(/\(\s*\)/g,'').replace(/\s+\)/g,')').replace(/\(\s+/g,'(').replace(/\s+([,.;!?])/g,'$1').replace(/[ \t]{2,}/g,' ').trim();
}
