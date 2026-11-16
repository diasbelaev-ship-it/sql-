import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { PoolClient } from 'pg';
import { defaults } from '../src/lib/filters';
import type { AssistantContext } from '../src/lib/assistant-tools';
import { providerSafe, ProviderUnavailable, runGemini, type ModelTransport, type ModelTurn } from '../src/lib/gemini-assistant';

type History = Parameters<ModelTransport>[0];

function context(accountId?: string) {
  const queries: string[] = [];
  const db = {
    query: async (sql: string) => {
      queries.push(sql);
      if (/FROM almaty_gym\.gyms WHERE id/.test(sql)) return { rows: [{ id: '61', name: 'Тестовый зал', address: 'Адрес' }] };
      if(/SELECT count\(\*\)::int total FROM chosen/.test(sql))return {rows:[{total:0}]};
      if(/SELECT \* FROM chosen/.test(sql))return {rows:[]};
      return { rows: [] };
    },
  } as unknown as PoolClient;
  const ctx: AssistantContext = {
    db, accountId, filters: { ...defaults }, results: ['61'], actions: [],
  };
  return { ctx, queries };
}

function scripted(turns: ModelTurn[]) {
  const histories: History[] = [];
  const requiredTools: Array<Parameters<ModelTransport>[2]> = [];
  let calls = 0;
  const transport: ModelTransport = async (history, instruction, requiredTool) => {
    assert.ok(instruction.includes('GymFinder'));
    histories.push(structuredClone(history));
    requiredTools.push(requiredTool);
    const result = turns[calls++];
    assert.ok(result, 'unexpected extra model request');
    return result;
  };
  return { transport, histories, requiredTools, count: () => calls };
}

function catalogContext(rows: Record<string, unknown>[]) {
  const queries: string[] = [];
  const db = {
    query: async (sql: string) => {
      queries.push(sql);
      if (/SELECT count\(\*\)::int total FROM chosen/.test(sql)) return { rows: [{ total: rows.length }] };
      if (/SELECT \* FROM chosen/.test(sql)) return { rows };
      return { rows: [] };
    },
  } as unknown as PoolClient;
  const ctx: AssistantContext = { db, filters: { ...defaults }, results: ['61'], actions: [] };
  return { ctx, queries };
}

function functionResult(history: History, name: string): Record<string, unknown> {
  const step = history.find(item => item.type === 'function_result' && item.name === name);
  assert.ok(step);
  assert.ok(Array.isArray(step.result));
  const part = step.result[0] as { type: string; text: string };
  return JSON.parse(part.text) as Record<string, unknown>;
}

test('runtime routes function calls and returns the final model response', async () => {
  const { ctx, queries } = context();
  const model = scripted([
    { status: 'requires_action', steps: [
      { type: 'function_call', id: 'call-map', name: 'navigate_site', arguments: { view: 'map' } },
      { type: 'function_call', id: 'call-gym', name: 'open_gym', arguments: { gymId: '61' } },
    ] },
    { status: 'completed', output_text: 'Открыл карту и карточку зала.' },
  ]);
  let admissions = 0;
  const result = await runGemini('Открой карту и этот зал', ctx, [], {
    transport: model.transport,
    beforeTool: async () => { admissions++; },
  });
  assert.equal(result.provider, 'gemini');
  assert.equal(result.answer, 'Открыл карту и карточку зала.');
  assert.equal(model.count(), 2);
  assert.deepEqual(model.requiredTools, [undefined, undefined], 'non-recommendation actions must remain free to select their tools');
  assert.equal(admissions, 2);
  assert.deepEqual(ctx.actions, [{ type: 'view', view: 'map' }, { type: 'open_gym', gymId: '61' }]);
  assert.equal(functionResult(model.histories[1], 'navigate_site').ok, true);
  assert.equal(functionResult(model.histories[1], 'open_gym').ok, true);
  assert.equal(queries.filter(sql => sql === 'SAVEPOINT assistant_tool').length, 2);
  assert.equal(queries.filter(sql => sql === 'RELEASE SAVEPOINT assistant_tool').length, 2);
});

test('unknown tools return an error to the model and execute no generated SQL', async () => {
  const { ctx, queries } = context();
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'bad', name: 'execute_sql', arguments: { sql: 'DELETE FROM gym_web.accounts' } }] },
    { status: 'completed', output_text: 'Такое действие недоступно.' },
  ]);
  await runGemini('Удали базу', ctx, [], { transport: model.transport });
  assert.equal(functionResult(model.histories[1], 'execute_sql').error, 'UNKNOWN_TOOL');
  assert.deepEqual(queries, [
    'SAVEPOINT assistant_tool', 'ROLLBACK TO SAVEPOINT assistant_tool', 'RELEASE SAVEPOINT assistant_tool',
  ]);
  assert.deepEqual(ctx.actions, []);
});

test('invalid tool arguments are isolated with a savepoint', async () => {
  const { ctx, queries } = context('7');
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'bad-owner', name: 'set_favorite', arguments: { gymId: '61', favorite: true, accountId: '8' } }] },
    { status: 'completed', output_text: 'Не удалось изменить избранное.' },
  ]);
  await runGemini('Сохрани зал', ctx, [], { transport: model.transport });
  assert.equal(functionResult(model.histories[1], 'set_favorite').error, 'INVALID_ARGUMENTS');
  assert.deepEqual(queries, [
    'SAVEPOINT assistant_tool', 'ROLLBACK TO SAVEPOINT assistant_tool', 'RELEASE SAVEPOINT assistant_tool',
  ]);
});

test('providerSafe removes private coordinates, profiles and credentials recursively', () => {
  const value = {
    filters: { audience: 'adult', lat: 43.123456, lng: 76.123456 },
    accountId: '7', email: 'person@example.test', password: 'test-secret',
    password_hash: 'test-hash', token_hash: 'test-hash',
    profile: { name: 'Private visitor', email: 'person@example.test' },
    credentials: { apiKey: 'test-secret' },
    apiKey: 'test-secret', GEMINI_API_KEY: 'test-secret', cookie: 'test-secret',
    authorization: 'test-secret', accessToken: 'test-secret',
    gyms: [{ name: 'Публичный зал', latitude: 43.25, longitude: 76.90, geo_accuracy_m: 8000, email: 'private@example.test' }],
  };
  const expected = {
    filters: { audience: 'adult' },
    gyms: [{ name: 'Публичный зал', latitude: 43.25, longitude: 76.90, geo_accuracy_m: 8000 }],
  };
  assert.deepEqual(providerSafe(value), expected);
  assert.equal(value.filters.lat, 43.123456, 'sanitization must not mutate the original filters');
});

test('initial model context omits exact visitor coordinates and account identity', async () => {
  const { ctx } = context('7');
  ctx.filters = { ...defaults, lat: 43.123456, lng: 76.123456 };
  const model = scripted([{ status: 'completed', output_text: 'Помогу выбрать зал.' }]);
  await runGemini('Помоги с выбором', ctx, [], { transport: model.transport });
  const serialized = JSON.stringify(model.histories[0]);
  assert.ok(!serialized.includes('43.123456'));
  assert.ok(!serialized.includes('76.123456'));
  assert.ok(!serialized.includes('accountId'));
  assert.match(serialized, /authenticated/);
});

test('function-loop rounds are bounded even when the model never answers', async () => {
  const { ctx, queries } = context();
  let calls = 0;
  const transport: ModelTransport = async () => ({
    status: 'requires_action', steps: [{ type: 'function_call', id: String(++calls), name: 'navigate_site', arguments: { view: 'map' } }],
  });
  await assert.rejects(runGemini('Открой карту', ctx, [], { transport }), error =>
    error instanceof ProviderUnavailable && error.code === 'tool_limit');
  assert.equal(calls, 5);
  assert.equal(queries.filter(sql => sql === 'SAVEPOINT assistant_tool').length, 5);
});

test('a single model round cannot execute more than twelve tool calls', async () => {
  const { ctx, queries } = context();
  let admissions = 0;
  const transport: ModelTransport = async () => ({
    status: 'requires_action',
    steps: Array.from({ length: 13 }, (_, index) => ({
      type: 'function_call', id: String(index), name: 'navigate_site', arguments: { view: 'list' },
    })),
  });
  await assert.rejects(runGemini('Покажи список', ctx, [], {
    transport, beforeTool: async () => { admissions++; },
  }), error => error instanceof ProviderUnavailable && error.code === 'tool_limit');
  assert.equal(admissions, 12);
  assert.equal(queries.filter(sql => sql === 'SAVEPOINT assistant_tool').length, 12);
});

test('recommendation forces a fresh catalogue search only on the first model round', async () => {
  const { ctx, queries } = catalogContext([
    { id: '61', name: 'Invictus GO Abay', monthly: 18000, price_kzt: 219000, duration_days: 365, price_basis: 'published' },
  ]);
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'search', name: 'search_gyms', arguments: { filters: { term: 'year', published: '1' } } }] },
    { status: 'completed', output_text: 'Invictus GO Abay: 219 000 ₸ за 365 дней, цена из источника.' },
  ]);
  const result = await runGemini('Какие залы порекомендуешь?', ctx, [], { transport: model.transport });
  assert.deepEqual(model.requiredTools, ['search_gyms', undefined]);
  assert.ok(queries.some(sql => /SELECT count\(\*\)::int total FROM chosen/.test(sql)));
  assert.ok(queries.some(sql => /SELECT \* FROM chosen/.test(sql)));
  const search = functionResult(model.histories[1], 'search_gyms');
  assert.equal(search.ok, true);
  assert.equal(search.total, 1);
  assert.equal(ctx.filters.term, 'year');
  assert.equal(ctx.filters.published, '1');
  assert.match(result.answer, /Invictus GO Abay/);
});

test('an explicit filter update forces a grounded catalogue search',async()=>{
  const {ctx}=context();
  ctx.filters={...defaults,term:'year',max:30000};
  ctx.explicitFilters={term:'year',max:30000};
  const model=scripted([
    {status:'requires_action',steps:[{type:'function_call',id:'intent-search',name:'search_gyms',arguments:{filters:{term:'month',max:20000}}}]},
    {status:'completed',output_text:'Показываю годовые варианты до 30 000 ₸ за 30 дней.'},
  ]);
  await runGemini('годовой до 30к',ctx,[],{transport:model.transport,forceCatalogSearch:true});
  assert.deepEqual(model.requiredTools,['search_gyms',undefined]);
  assert.equal(ctx.filters.term,'year');
  assert.equal(ctx.filters.max,30000);
});

test('recommendation text without the forced search is rejected before accepting invented advice', async () => {
  const { ctx, queries } = context();
  const model = scripted([{ status: 'completed', output_text: 'Советую выдуманный клуб с бассейном за 5 000 ₸.' }]);
  await assert.rejects(runGemini('Посоветуй зал', ctx, [], { transport: model.transport }), error =>
    error instanceof ProviderUnavailable && error.code === 'ungrounded_response');
  assert.deepEqual(model.requiredTools, ['search_gyms']);
  assert.equal(queries.length, 0);
  assert.deepEqual(ctx.actions, []);
});

test('an unrelated first tool does not satisfy the required recommendation search', async () => {
  const { ctx, queries } = context();
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'not-search', name: 'navigate_site', arguments: { view: 'map' } }] },
  ]);
  await assert.rejects(runGemini('Подбери мне зал', ctx, [], { transport: model.transport }), error =>
    error instanceof ProviderUnavailable && error.code === 'ungrounded_response');
  assert.equal(queries.length, 0, 'an unrelated action must not execute before the grounding guard');
  assert.deepEqual(ctx.actions, []);
});

test('a failed search cannot ground a later text-only recommendation', async () => {
  const { ctx, queries } = context();
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'bad-search', name: 'search_gyms', arguments: { filters: { audience: 'made-up-category' } } }] },
    { status: 'completed', output_text: 'Советую этот зал, он отличный.' },
  ]);
  await assert.rejects(runGemini('Что выбрать?', ctx, [], { transport: model.transport }), error =>
    error instanceof ProviderUnavailable && error.code === 'ungrounded_response');
  assert.equal(functionResult(model.histories[1], 'search_gyms').error, 'INVALID_ARGUMENTS');
  assert.ok(!queries.some(sql => /FROM chosen/.test(sql)));
  assert.deepEqual(ctx.actions, []);
});

test('a successful empty search can produce honest no-results guidance', async () => {
  const { ctx } = catalogContext([]);
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'empty-search', name: 'search_gyms', arguments: {} }] },
    { status: 'completed', output_text: 'По текущим фильтрам подходящих залов нет. Попробуйте увеличить бюджет.' },
  ]);
  const result = await runGemini('Посоветуй зал', ctx, [], { transport: model.transport });
  assert.equal(functionResult(model.histories[1], 'search_gyms').total, 0);
  assert.match(result.answer, /подходящих залов нет/);
  assert.deepEqual(ctx.results, []);
});

test('model-estimate prices add a disclaimer when the model omits it', async () => {
  const { ctx } = catalogContext([
    { id: '12', name: 'King Fitness', monthly: 15000, price_kzt: 15000, duration_days: 30, price_basis: 'model_estimate' },
  ]);
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'estimated-search', name: 'search_gyms', arguments: {} }] },
    { status: 'completed', output_text: 'King Fitness — 15 000 ₸ за 30 дней.' },
  ]);
  const result = await runGemini('Какие залы порекомендуешь?', ctx, [], { transport: model.transport });
  assert.match(result.answer, /King Fitness — 15 000 ₸/);
  assert.match(result.answer, /учебные расчёты/);
  assert.match(result.answer, /уточняйте реальные условия/);
});

test('an existing estimate explanation is not duplicated', async () => {
  const { ctx } = catalogContext([
    { id: '12', name: 'King Fitness', monthly: 15000, price_kzt: 15000, duration_days: 30, price_basis: 'model_estimate' },
  ]);
  const output = 'King Fitness — 15 000 ₸ за 30 дней. Это учебная оценка, уточните цену у клуба.';
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'estimated-search', name: 'search_gyms', arguments: {} }] },
    { status: 'completed', output_text: output },
  ]);
  const result = await runGemini('Посоветуй зал', ctx, [], { transport: model.transport });
  assert.equal(result.answer, output);
});

test('model database labels are converted to plain Russian', async () => {
  const { ctx } = catalogContext([
    { id: '12', name: 'King Fitness', monthly: 15000, price_kzt: 15000, duration_days: 30, price_basis: 'model_estimate' },
  ]);
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'estimated-search', name: 'search_gyms', arguments: {} }] },
    { status: 'completed', output_text: 'King Fitness — 15 000 ₸ за 30 дней. Цена: `model_estimate`.' },
  ]);
  const result = await runGemini('Какие залы порекомендуешь?', ctx, [], { transport: model.transport });
  assert.doesNotMatch(result.answer, /model_estimate|price_basis|price_kzt|duration_days/i);
  assert.match(result.answer, /учебная оценка/);
});

test('published-only prices do not receive an invented model-estimate label', async () => {
  const { ctx } = catalogContext([
    { id: '22', name: 'First Fitness Таугуль', monthly: 26000, price_kzt: 26000, duration_days: 30, price_basis: 'published' },
  ]);
  const output = 'First Fitness Таугуль — 26 000 ₸ за 30 дней, опубликовано в источнике.';
  const model = scripted([
    { status: 'requires_action', steps: [{ type: 'function_call', id: 'published-search', name: 'search_gyms', arguments: { filters: { published: '1' } } }] },
    { status: 'completed', output_text: output },
  ]);
  const result = await runGemini('Посоветуй зал', ctx, [], { transport: model.transport });
  assert.equal(result.answer, output);
  assert.doesNotMatch(result.answer, /учебные расчёты/);
});
