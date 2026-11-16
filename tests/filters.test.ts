import {test} from 'node:test';
import assert from 'node:assert/strict';
import {parsePhrase,filtersSchema} from '../src/lib/filters';
test('chat refinement preserves annual term and audience',()=>{const first=parsePhrase('студент годовой до 20к');const next=parsePhrase('до 30000',first.filters);assert.equal(next.filters.audience,'student');assert.equal(next.filters.term,'year');assert.equal(next.filters.max,30000);});
test('short annual phrase is parsed in local fallback',()=>{const intent=parsePhrase('годовой до 30к');assert.equal(intent.filters.term,'year');assert.equal(intent.filters.max,30000);assert.deepEqual(intent.patch,{term:'year',max:30000});});
test('distance sort requires paired coordinates',()=>{assert.equal(filtersSchema.safeParse({sort:'distance'}).success,false);assert.equal(filtersSchema.safeParse({lat:43}).success,false);assert.equal(filtersSchema.safeParse({sort:'distance',lat:43,lng:76}).success,true);});
test('reset clears prior budget and zone',()=>{const r=parsePhrase('сброс',{max:12000,zone:'west'});assert.equal(r.filters.max,100000);assert.equal(r.filters.zone,'');});
test('budget unit does not override annual term',()=>{const r=parsePhrase('до 25к в месяц',{term:'year'});assert.equal(r.filters.term,'year');assert.equal(r.filters.max,25000);});
