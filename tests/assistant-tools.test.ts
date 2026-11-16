import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { PoolClient } from 'pg';
import { z } from 'zod';
import { defaults } from '../src/lib/filters';
import { executeTool, type AssistantContext } from '../src/lib/assistant-tools';

type QueryCall = { sql: string; values: unknown[] };

function context(rows: Record<string, unknown>[] = [], accountId?: string) {
  const calls: QueryCall[] = [];
  const db = {
    query: async (sql: string, values: unknown[] = []) => {
      calls.push({ sql, values });
      if(/SELECT count\(\*\)::int total FROM chosen/.test(sql))return {rows:[{total:rows.length}]};
      if(/SELECT \* FROM chosen/.test(sql))return {rows};
      return { rows };
    },
  } as unknown as PoolClient;
  const ctx: AssistantContext = {
    db, accountId, filters: { ...defaults }, results: ['61', '62', '63'], actions: [],
  };
  return { ctx, calls };
}

test('guest cannot mutate favorites or prepare a review', async () => {
  const favorite = context();
  const result = await executeTool('set_favorite', { gymId: '61', favorite: true }, favorite.ctx);
  assert.equal(result.error, 'LOGIN_REQUIRED');
  assert.deepEqual(favorite.ctx.actions, [{ type: 'login' }]);
  assert.equal(favorite.calls.length, 0);

  const review = context();
  const draft = await executeTool('prepare_review', {
    gymId: '61', rating: 5, content: 'Мой тестовый отзыв',
  }, review.ctx);
  assert.equal(draft.error, 'LOGIN_REQUIRED');
  assert.equal(review.ctx.pendingReview, undefined);
  assert.equal(review.calls.length, 0);
});

test('client-supplied accountId is rejected before database access', async () => {
  const { ctx, calls } = context([], '7');
  await assert.rejects(
    executeTool('set_favorite', { gymId: '61', favorite: true, accountId: '8' }, ctx),
    z.ZodError,
  );
  assert.equal(calls.length, 0);
});

test('unknown raw SQL tool cannot reach the database', async () => {
  const { ctx, calls } = context([], '7');
  await assert.rejects(
    executeTool('execute_sql', { sql: 'DROP TABLE gym_web.accounts' }, ctx),
    /UNKNOWN_ASSISTANT_TOOL/,
  );
  assert.equal(calls.length, 0);
});

test('explicit user filter intent takes precedence over model search arguments',async()=>{
  const {ctx}=context();
  ctx.explicitFilters={term:'year',max:30000};
  const result=await executeTool('search_gyms',{filters:{term:'month',max:20000}},ctx);
  assert.deepEqual(result.filters,{...defaults,term:'year',max:30000,page:1});
  assert.equal(ctx.filters.term,'year');
  assert.equal(ctx.filters.max,30000);
});

test('comparison preserves annual published plans and positions [3,1]', async () => {
  const { ctx, calls } = context([
    { id: '63', name: 'Третий зал', duration_days: 365, monthly: 18000, price_kzt: 219000, price_basis: 'published' },
    { id: '61', name: 'Первый зал', duration_days: 365, monthly: 18000, price_kzt: 219000, price_basis: 'published' },
  ]);
  ctx.filters = { ...defaults, term: 'year', published: '1', max: 30000 };
  const compared = await executeTool('compare_gyms', { resultPositions: [3, 1] }, ctx);
  assert.equal(compared.ok, true);
  assert.deepEqual(calls[0].values, [['63', '61'], 'adult', 'year', '1', 30000, 365, 366]);
  assert.match(calls[0].sql, /duration_days BETWEEN \$6::integer AND \$7::integer/);
  assert.doesNotMatch(calls[0].sql, /v_gym_prices/);
  assert.deepEqual(ctx.actions, [{ type: 'compare', gymIds: ['63', '61'] }]);
  assert.deepEqual(ctx.results, ['61', '62', '63']);
  assert.deepEqual(compared.unavailableIds, []);
});

test('comparison reports a missing matching tariff without falling back', async () => {
  const { ctx, calls } = context([]);
  ctx.filters = { ...defaults, term: 'year', audience: 'student', published: '1' };
  const result = await executeTool('compare_gyms', { gymIds: ['61'] }, ctx);
  assert.deepEqual(result.gyms, []);
  assert.deepEqual(result.unavailableIds, ['61']);
  assert.equal(calls.length, 1);
  assert.deepEqual(ctx.actions, []);
});

test('out-of-range result position is rejected without a query', async () => {
  const { ctx, calls } = context();
  const result = await executeTool('compare_gyms', { resultPositions: [7] }, ctx);
  assert.equal(result.error, 'RESULT_POSITION_NOT_FOUND');
  assert.equal(calls.length, 0);
});

test('review preparation creates a draft and never publishes it', async () => {
  const { ctx, calls } = context([{ id: '61', name: 'Проверяемый зал', address: 'Проверяемый адрес' }], '7');
  const result = await executeTool('prepare_review', {
    gymId: '61', rating: 4, content: '  Мои впечатления о зале  ',
  }, ctx);
  assert.equal(result.requiresConfirmation, true);
  assert.equal(result.published, false);
  assert.deepEqual(ctx.pendingReview, {
    gymId: '61', gymName: 'Проверяемый зал', rating: 4, content: 'Мои впечатления о зале',
  });
  assert.equal(calls.length, 1);
  assert.ok(calls.every(call => /^\s*SELECT\b/.test(call.sql)));
  assert.ok(calls.every(call => !/\b(?:INSERT|UPDATE|DELETE)\b/.test(call.sql)));
});

test('favorite mutation uses only the verified account from context', async () => {
  const { ctx, calls } = context([{ id: '61', name: 'Зал' }], '7');
  await executeTool('set_favorite', { gymId: '61', favorite: true }, ctx);
  assert.equal(calls.length, 2);
  assert.match(calls[1].sql, /INSERT INTO gym_web\.favorites/);
  assert.deepEqual(calls[1].values, ['7', '61']);
  assert.deepEqual(ctx.actions, [{ type: 'favorites_changed' }]);
});

test('navigation and identifiers accept only supported site operations', async () => {
  const { ctx, calls } = context();
  await assert.rejects(executeTool('navigate_site', { view: 'https://outside.example' }, ctx), z.ZodError);
  await assert.rejects(executeTool('get_gym', { gymId: "61' OR 1=1" }, ctx), z.ZodError);
  assert.equal(calls.length, 0);
  assert.deepEqual(ctx.actions, []);
});

test('partial search refinement preserves annual and published-only filters', async () => {
  const { ctx, calls } = context();
  ctx.filters = { ...defaults, term: 'year', published: '1', zone: 'south', max: 30000 };
  ctx.db = {
    query: async (sql: string, values: unknown[]) => {
      calls.push({ sql, values });
      if (/SELECT count\(\*\)::int total FROM chosen/.test(sql)) return { rows: [{ total: 1 }] };
      return { rows: [{ id: '61', name: 'Зал', duration_days: 365, price_basis: 'published' }] };
    },
  } as unknown as PoolClient;
  const result = await executeTool('search_gyms', { filters: { max: 25000 } }, ctx);
  assert.equal(result.total, 1);
  assert.equal(ctx.filters.term, 'year');
  assert.equal(ctx.filters.published, '1');
  assert.equal(ctx.filters.zone, 'south');
  assert.equal(ctx.filters.max, 25000);
  assert.deepEqual(ctx.results, ['61']);
  assert.equal(calls.length, 2);
  assert.equal(calls[0].values[1], 'year');
  assert.equal(calls[0].values[6], '1');
});

test('adding a favorite then listing it uses the same transaction client', async () => {
  const { ctx, calls } = context([], '7');
  let transactionFavorite = false;
  ctx.db = {
    query: async (sql: string, values: unknown[] = []) => {
      calls.push({ sql, values });
      if (/FROM almaty_gym\.gyms WHERE id/.test(sql)) return { rows: [{ id: '61', name: 'Зал' }] };
      if (/INSERT INTO gym_web\.favorites/.test(sql)) {
        transactionFavorite = true;
        return { rows: [] };
      }
      assert.equal(values[7], '7', 'favorites read must use the verified account');
      assert.equal(values[10], true, 'read must be restricted to favorites');
      if (/SELECT count\(\*\)::int total FROM chosen/.test(sql)) {
        return { rows: [{ total: transactionFavorite ? 1 : 0 }] };
      }
      return { rows: transactionFavorite ? [{ id: '61', name: 'Зал', favorite: true }] : [] };
    },
  } as unknown as PoolClient;
  await executeTool('set_favorite', { gymId: '61', favorite: true }, ctx);
  const listed = await executeTool('list_favorites', {}, ctx);
  assert.equal(listed.total, 1);
  assert.deepEqual(listed.gyms, [{ id: '61', name: 'Зал', favorite: true }]);
  assert.deepEqual(ctx.results, ['61']);
  assert.equal(calls.length, 4);
  assert.deepEqual(ctx.actions, [{ type: 'favorites_changed' }, { type: 'view', view: 'favorites' }]);
});
