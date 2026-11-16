import {test} from 'node:test';
import assert from 'node:assert/strict';
import {filtersSchema,parsePhrase} from '../src/lib/filters';
import {getTermBounds,matchesTerm,type SubscriptionTerm} from '../src/lib/subscription-terms';

const phrases:[string,SubscriptionTerm][]=[
  ['Найди зал на 2 месяца','2months'],
  ['Абонемент на два месяца','2months'],
  ['Нужен трёхмесячный абонемент','3months'],
  ['Подбери зал на 3 месяца','3months'],
  ['Хочу заниматься на полгода','6months'],
  ['Студенту на шесть месяцев','6months'],
  ['Абонемент на девять месяцев','9months'],
  ['Покажи варианты на 9 месяцев','9months'],
  ['Нужен месячный абонемент','month'],
  ['Годовой абонемент до 30к','year'],
];

for(const [phrase,term] of phrases){
  test(`subscription duration is understood in Russian: ${phrase}`,()=>{
    const result=parsePhrase(phrase,{audience:'student',zone:'west',max:35000});
    assert.equal(result.filters.term,term);
    assert.equal(result.filters.audience,'student');
    assert.equal(result.filters.zone,'west');
    assert.ok(result.recognized);
  });
}

test('changing a monthly budget keeps the chosen multi-month subscription',()=>{
  const first=parsePhrase('Взрослому на два месяца до 30к');
  const next=parsePhrase('до 20000 в месяц',first.filters);
  assert.equal(next.filters.term,'2months');
  assert.equal(next.filters.max,20000);
  assert.equal(next.filters.audience,'adult');
});

test('a new explicit duration replaces the prior one without resetting category or budget',()=>{
  const first=parsePhrase('Студенту на полгода до 25к');
  const next=parsePhrase('Лучше на 2 месяца',first.filters);
  assert.equal(next.filters.term,'2months');
  assert.equal(next.filters.audience,'student');
  assert.equal(next.filters.max,25000);
});

const durationCases:[SubscriptionTerm,number,number,number][]=[
  ['month',28,35,30],
  ['2months',56,62,60],
  ['3months',84,93,90],
  ['6months',168,186,180],
  ['9months',252,279,270],
  ['year',365,366,365],
];

for(const [term,min,max,typical] of durationCases){
  test(`${term} accepts its full duration range and excludes neighboring terms`,()=>{
    assert.deepEqual(getTermBounds(term),[min,max]);
    assert.equal(matchesTerm(min,term),true);
    assert.equal(matchesTerm(max,term),true);
    assert.equal(matchesTerm(typical,term),true);
    assert.equal(matchesTerm(min-1,term),false);
    assert.equal(matchesTerm(max+1,term),false);
  });
}

test('annual subscriptions include leap years and do not silently become 12 times 30 days',()=>{
  assert.equal(matchesTerm(365,'year'),true);
  assert.equal(matchesTerm(366,'year'),true);
  assert.equal(matchesTerm(360,'year'),false);
  assert.equal(matchesTerm(30,'year'),false);
});

test('any term covers all supported stored durations while rejecting invalid durations',()=>{
  assert.deepEqual(getTermBounds('any'),[1,730]);
  for(const days of [1,30,60,90,180,270,365,366,730])assert.equal(matchesTerm(days,'any'),true);
  for(const days of [0,-1,731,NaN])assert.equal(matchesTerm(days,'any'),false);
});

test('API filters allow offered duration choices and reject unsupported values',()=>{
  for(const term of ['month','2months','3months','6months','9months','year','any']){
    assert.equal(filtersSchema.safeParse({term}).success,true,term);
  }
  assert.equal(filtersSchema.safeParse({term:'5months'}).success,false);
});
