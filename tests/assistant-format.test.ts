import { test } from 'node:test';
import assert from 'node:assert/strict';
import { humanizeAssistantText } from '../src/lib/assistant-format';

test('cached estimate labels are removed when the explanation is already present', () => {
  const result=humanizeAssistantText('Все цены — учебные оценки (`model_estimate`).');
  assert.equal(result,'Все цены — учебные оценки.');
  assert.doesNotMatch(result,/model_estimate/i);
  assert.equal(humanizeAssistantText('(все цены — учебные оценки `model_estimate`):'),'(все цены — учебные оценки):');
});

test('bare database labels are replaced with readable Russian', () => {
  const result=humanizeAssistantText('Цена: model_estimate, price_kzt, duration_days.');
  assert.equal(result,'Цена: учебная оценка, цена тарифа, срок в днях.');
});
