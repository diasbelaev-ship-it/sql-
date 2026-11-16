import {test} from 'node:test';
import assert from 'node:assert/strict';
import type {PoolClient} from 'pg';
import {defaults,type Filters} from '../src/lib/filters';
import type {AssistantContext} from '../src/lib/assistant-tools';
import {runLocal} from '../src/lib/local-assistant';

type QueryCall={sql:string;values:unknown[]};
const sampleGyms=[
  {id:'12',name:'King Fitness',address:'микрорайон Шугыла',city_zone:'west',
    monthly:15000,price_kzt:15000,duration_days:30,price_basis:'model_estimate',
    source_url:'https://1fit.app/ru/almaty/gym?page=2'},
  {id:'22',name:'First Fitness Таугуль',address:'микрорайон Таугуль-1, 22/1',city_zone:'west',
    monthly:26000,price_kzt:26000,duration_days:30,price_basis:'published',
    source_url:'https://www.firstfitness.kz/'},
];

function context(rows:Record<string,unknown>[]=sampleGyms,patch:Partial<Filters>={}){
  const calls:QueryCall[]=[];
  const db={query:async(sql:string,values:unknown[]=[])=>{
    calls.push({sql,values});
    return {rows:/SELECT count\(\*\)::int total FROM chosen/.test(sql)?[{total:rows.length}]:rows};
  }} as unknown as PoolClient;
  const ctx:AssistantContext={db,filters:{...defaults,...patch},results:[],actions:[]};
  return {ctx,calls};
}

for(const phrase of [
  'какие залы порекомендуешь',
  'посоветуй зал',
  'что выбрать',
  'подбери мне зал',
  'рекомендуй недорогой зал',
  'хороший зал рядом',
]){
  test(`ordinary recommendation returns catalogue choices: ${phrase}`,async()=>{
    const {ctx,calls}=context();
    const result=await runLocal(phrase,ctx);
    assert.equal(result.provider,'local');
    assert.ok(calls.some(call=>/FROM chosen/.test(call.sql)),'must query the catalogue');
    assert.match(result.answer,/King Fitness/);
    assert.match(result.answer,/First Fitness Таугуль/);
    assert.doesNotMatch(result.answer,/В локальном режиме понимаю категорию/);
    assert.ok(ctx.actions.some(action=>action.type==='view'&&action.view==='catalog'));
  });
}

test('recommendation-only question preserves the current category, annual term, source and budget',async()=>{
  const {ctx,calls}=context([
    {id:'61',name:'Invictus GO Abay',address:'проспект Абая, 165',city_zone:'south',
      monthly:18000,price_kzt:219000,duration_days:365,price_basis:'published'},
  ],{audience:'student',term:'year',published:'1',max:30000,zone:'south'});
  await runLocal('какие залы порекомендуешь',ctx);
  assert.equal(ctx.filters.audience,'student');
  assert.equal(ctx.filters.term,'year');
  assert.equal(ctx.filters.published,'1');
  assert.equal(ctx.filters.max,30000);
  assert.equal(ctx.filters.zone,'south');
  const search=calls.find(call=>/FROM chosen/.test(call.sql));
  assert.ok(search);
  assert.equal(search.values[0],'student');
  assert.equal(search.values[1],'year');
  assert.equal(search.values[5],30000);
  assert.equal(search.values[6],'1');
});

test('recommendation answer includes grounded prices and distinguishes source from estimate',async()=>{
  const {ctx}=context();
  const {answer}=await runLocal('посоветуй зал',ctx);
  const normalized=answer.replace(/[\u00a0\u202f]/g,' ');
  assert.match(normalized,/15\s?000\s*₸/);
  assert.match(normalized,/26\s?000\s*₸/);
  assert.match(answer,/оценк/i);
  assert.match(answer,/источник|опубликован/i);
  assert.doesNotMatch(answer,/есть бассейн|с бассейном|сауна включена|рейтинг\s*[45]|[45][.,][0-9]\s*(?:из\s*5|звезд)/i);
});

test('empty recommendations contain no fabricated gym or price',async()=>{
  const {ctx}=context([],{max:1000});
  const {answer}=await runLocal('какие залы порекомендуешь',ctx);
  assert.match(answer,/не найден|нет.*(?:зал|вариант|совпад)|подходящих.*нет|не наш/i);
  assert.doesNotMatch(answer,/King Fitness|First Fitness|Invictus|15\s?000|26\s?000/);
  assert.deepEqual(ctx.results,[]);
});

test('nearby request without coordinates never invents an exact distance',async()=>{
  const {ctx}=context();
  const {answer}=await runLocal('хороший зал рядом',ctx);
  assert.equal(ctx.filters.lat,undefined);
  assert.equal(ctx.filters.lng,undefined);
  assert.doesNotMatch(answer,/(?:в|через)\s*\d+(?:[.,]\d+)?\s*(?:метр|минут|км)/i);
});
