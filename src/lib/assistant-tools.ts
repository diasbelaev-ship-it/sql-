import type { PoolClient } from 'pg';
import { z } from 'zod';
import { defaults, filtersSchema, type Filters } from './filters';
import { searchGyms } from './search';
import { getTermBounds, subscriptionTermValues } from './subscription-terms';

export type AssistantAction =
  | { type: 'open_gym'; gymId: string }
  | { type: 'view'; view: 'catalog' | 'favorites' | 'map' | 'list' | 'sql' }
  | { type: 'compare'; gymIds: string[] }
  | { type: 'login' }
  | { type: 'favorites_changed' };

export type ReviewDraft = {
  gymId: string;
  gymName: string;
  rating: number;
  content: string;
};

export type AssistantContext = {
  db: PoolClient;
  accountId?: string;
  filters: Filters;
  explicitFilters?: Partial<Filters>;
  results: string[];
  actions: AssistantAction[];
  pendingReview?: ReviewDraft;
};

const gymIdSchema = z.union([
  z.string().regex(/^[1-9]\d{0,17}$/, 'Нужен положительный id зала'),
  z.number().int().positive().max(Number.MAX_SAFE_INTEGER),
]).transform(String);

const filterPatchSchema = z.object({
  q: z.string().max(120).optional(),
  audience: z.enum(['student', 'adult', 'premium']).optional(),
  term: z.enum(subscriptionTermValues).optional(),
  zone: z.enum(['', 'west', 'north', 'center', 'south']).optional(),
  band: z.enum(['', 'budget', 'standard', 'premium']).optional(),
  max: z.number().int().min(0).max(2_000_000).optional(),
  published: z.enum(['', '1']).optional(),
  sort: z.enum(['verified', 'price', 'price_desc', 'name', 'distance', 'distance_desc']).optional(),
  lat: z.number().min(-90).max(90).nullable().optional(),
  lng: z.number().min(-180).max(180).nullable().optional(),
  radiusKm: z.number().int().min(1).max(50).optional(),
  page: z.number().int().min(1).max(10_000).optional(),
}).strict();

const searchSchema = z.object({
  filters: filterPatchSchema.default({}),
  reset: z.boolean().default(false),
}).strict();

const idArgsSchema = z.object({ gymId: gymIdSchema }).strict();
const compareSchema = z.object({
  gymIds: z.array(gymIdSchema).min(1).max(3).optional(),
  resultPositions: z.array(z.number().int().min(1).max(20)).min(1).max(3).optional(),
}).strict().refine(
  value => !(value.gymIds && value.resultPositions),
  'Укажите gymIds либо resultPositions, а не оба поля',
);

const views = ['catalog', 'favorites', 'map', 'list', 'sql'] as const;
const emptyArgsSchema = z.object({}).strict();

const filterProperties = {
  q: { type: 'string', description: 'Название или адрес. Пустая строка снимает поиск.' },
  audience: { type: 'string', enum: ['student', 'adult', 'premium'] },
  term: { type: 'string', enum: [...subscriptionTermValues], description: 'month — месяц; 2months — 2 месяца; 3months — 3 месяца; 6months — 6 месяцев; 9months — 9 месяцев; year — год (365–366 дней); any — любой срок. Не подменяй выбранный срок месячным.' },
  zone: { type: 'string', enum: ['', 'west', 'north', 'center', 'south'] },
  band: { type: 'string', enum: ['', 'budget', 'standard', 'premium'] },
  max: { type: 'integer', minimum: 0, maximum: 2_000_000, description: 'Бюджет в тенге за 30 дней, в том числе для годового тарифа.' },
  published: { type: 'string', enum: ['', '1'], description: '1 — только цены из источников; пустая строка — также учебные оценки.' },
  sort: { type: 'string', enum: ['verified', 'price', 'price_desc', 'name', 'distance', 'distance_desc'] },
  lat: { type: ['number', 'null'], minimum: -90, maximum: 90, description: 'Только координата, явно переданная пользователем или интерфейсом. Не выдумывать.' },
  lng: { type: ['number', 'null'], minimum: -180, maximum: 180 },
  radiusKm: { type: 'integer', minimum: 1, maximum: 50, description: 'Радиус поиска в километрах; сохраняй текущий радиус, не придумывай геолокацию.' },
  page: { type: 'integer', minimum: 1, maximum: 10_000 },
};

const idProperty = {
  type: 'string',
  pattern: '^[1-9][0-9]{0,17}$',
  description: 'Реальный id зала, полученный из поиска или get_gym. Не номер позиции.',
};

function declaration(
  name: string,
  description: string,
  properties: Record<string, unknown>,
  required: string[] = [],
) {
  return {
    type: 'function' as const,
    name,
    description,
    parameters: { type: 'object' as const, properties, required, additionalProperties: false },
  };
}

/** JSON declarations for the Gemini Interactions API. No arbitrary SQL or URLs are accepted. */
export const assistantToolDeclarations = [
  declaration(
    'search_gyms',
    'Найти залы и применить фильтры каталога. Передавай только явно изменяемые поля: остальные сохраняются. reset=true сбрасывает прежние фильтры. Результаты и их порядок запоминаются для ссылок «первый», «третий».',
    {
      filters: { type: 'object', properties: filterProperties, additionalProperties: false },
      reset: { type: 'boolean' },
    },
  ),
  declaration('get_gym', 'Получить публичную карточку зала, тарифы, источники и учебные занятия/тренеров. Не открывает карточку автоматически.', { gymId: idProperty }, ['gymId']),
  declaration(
    'compare_gyms',
    'Сравнить до трёх залов по текущим аудитории, сроку, бюджету и происхождению цены. Передай gymIds либо resultPositions (с 1). Без аргументов сравниваются первые три из последнего поиска. Неподходящий тариф не заменяется месячным.',
    {
      gymIds: { type: 'array', items: idProperty, minItems: 1, maxItems: 3 },
      resultPositions: { type: 'array', items: { type: 'integer', minimum: 1, maximum: 20 }, minItems: 1, maxItems: 3 },
    },
  ),
  declaration('list_favorites', 'Показать избранные залы текущего вошедшего пользователя с сохранением фильтров. Для гостя требуется вход.', {}),
  declaration(
    'set_favorite',
    'Добавить или убрать один зал из избранного по просьбе пользователя. Аккаунт определяется сервером. Операция идемпотентна; favorite=true добавляет, false удаляет.',
    { gymId: idProperty, favorite: { type: 'boolean' } },
    ['gymId', 'favorite'],
  ),
  declaration('navigate_site', 'Переключить раздел сайта: каталог, избранное, карту, список или возможности сайта. Никакие произвольные адреса не поддерживаются.', { view: { type: 'string', enum: [...views] } }, ['view']),
  declaration('open_gym', 'Открыть карточку конкретного существующего зала в интерфейсе.', { gymId: idProperty }, ['gymId']),
  declaration(
    'prepare_review',
    'Подготовить отзыв текущего пользователя для подтверждения. НЕ публикует отзыв. Используй только оценку и впечатления, которые сообщил сам пользователь; недостающие сведения уточни. Публикация возможна лишь отдельным подтверждением в интерфейсе.',
    {
      gymId: idProperty,
      rating: { type: 'integer', minimum: 1, maximum: 5 },
      content: { type: 'string', minLength: 3, maxLength: 2000 },
    },
    ['gymId', 'rating', 'content'],
  ),
];

export const toolDeclarations = assistantToolDeclarations;

const publicGymFields = [
  'id', 'name', 'address', 'city_zone', 'price_band', 'latitude', 'longitude',
  'geo_accuracy_m', 'source_url', 'source_checked_on', 'plan_id', 'plan_name',
  'price_kzt', 'duration_days', 'price_basis', 'price_source_url', 'monthly',
  'favorite', 'distance',
] as const;

function publicGym(row: Record<string, unknown>) {
  return Object.fromEntries(publicGymFields.filter(key => key in row).map(key => [key, row[key]]));
}

function requireAccount(ctx: AssistantContext) {
  if (ctx.accountId) return true;
  ctx.actions.push({ type: 'login' });
  return false;
}

const loginRequired = { ok: false, error: 'LOGIN_REQUIRED', message: 'Для этого действия войдите в аккаунт. Данные не изменены.' };

async function findGym(ctx: AssistantContext, gymId: string) {
  const result = await ctx.db.query(
    `SELECT id::text, name, address, city_zone, price_band,
            latitude, longitude, geo_accuracy_m, source_url, source_checked_on
       FROM almaty_gym.gyms WHERE id=$1`,
    [gymId],
  );
  return result.rows[0] as Record<string, unknown> | undefined;
}

async function search(args: unknown, ctx: AssistantContext) {
  const { filters: patch, reset } = searchSchema.parse(args);
  const merged: Record<string, unknown> = { ...(reset ? defaults : ctx.filters), ...patch, ...ctx.explicitFilters, page: patch.page ?? 1 };
  if (merged.lat === null) delete merged.lat;
  if (merged.lng === null) delete merged.lng;
  const filters = filtersSchema.parse(merged);
  const found = await searchGyms(filters, ctx.accountId, false, ctx.db);
  ctx.filters = filters;
  ctx.results = found.gyms.map(gym => String(gym.id));
  ctx.actions.push({ type: 'view', view: 'catalog' });
  return {
    ok: true,
    ...found,
    gyms: found.gyms.map(publicGym),
    filters,
    note: 'monthly — цена за 30 дней; price_kzt — полная цена выбранного тарифа. model_estimate — учебная оценка, не тариф клуба. У 67 залов координаты из страниц источников; у 3 геолокация не подтверждена.',
  };
}

async function getGym(args: unknown, ctx: AssistantContext) {
  const { gymId } = idArgsSchema.parse(args);
  const gym = await findGym(ctx, gymId);
  if (!gym) return { ok: false, error: 'GYM_NOT_FOUND', gymId };
  const plans = await ctx.db.query(
    `SELECT id::text, name, audience, duration_days, price_kzt,
            round(price_kzt*30.0/duration_days)::integer AS monthly,
            price_basis, price_source_url, price_checked_on
       FROM almaty_gym.plans WHERE gym_id=$1 ORDER BY duration_days, audience`,
    [gymId],
  );
  const trainers = await ctx.db.query(
    'SELECT full_name, specialty, is_demo FROM almaty_gym.trainers WHERE gym_id=$1 ORDER BY id',
    [gymId],
  );
  const classes = await ctx.db.query(
    'SELECT title, weekday, start_time, capacity FROM almaty_gym.classes WHERE gym_id=$1 ORDER BY weekday,start_time,id',
    [gymId],
  );
  return {
    ok: true,
    gym: publicGym(gym),
    plans: plans.rows,
    trainers: trainers.rows,
    demoClasses: classes.rows,
    note: 'Тренеры и расписание учебные. Часы реального открытия не подтверждены. Для маршрута проверьте адрес по прямой странице зала source_url.',
  };
}

async function compareGyms(args: unknown, ctx: AssistantContext) {
  const parsed = compareSchema.parse(args);
  let gymIds = parsed.gymIds;
  if (parsed.resultPositions) {
    if (parsed.resultPositions.some(position => !ctx.results[position - 1])) {
      return { ok: false, error: 'RESULT_POSITION_NOT_FOUND', availableResults: ctx.results.length };
    }
    gymIds = parsed.resultPositions.map(position => ctx.results[position - 1]);
  }
  gymIds = [...new Set(gymIds ?? ctx.results.slice(0, 3))];
  if (!gymIds.length) return { ok: false, error: 'NO_PREVIOUS_RESULTS', message: 'Сначала найдите залы или укажите их id.' };

  const { audience, term, max, published } = ctx.filters;
  const found = await ctx.db.query(
    `SELECT g.id::text, g.name, g.address, g.city_zone, g.price_band,
            g.latitude, g.longitude, g.geo_accuracy_m, g.source_url,
            p.id::text AS plan_id, p.name AS plan_name, p.duration_days,
            p.price_kzt, round(p.price_kzt*30.0/p.duration_days)::integer AS monthly,
            p.price_basis, p.price_source_url
       FROM almaty_gym.gyms g
       CROSS JOIN LATERAL (
         SELECT p.* FROM almaty_gym.plans p
          WHERE p.gym_id=g.id AND p.audience=$2
            AND ($3='any' OR p.duration_days BETWEEN $6::integer AND $7::integer)
            AND ($4='' OR p.price_basis='published')
            AND round(p.price_kzt*30.0/p.duration_days)<=$5
          ORDER BY p.price_kzt*30.0/p.duration_days,p.id LIMIT 1
       ) p
      WHERE g.id=ANY($1::bigint[])
      ORDER BY array_position($1::bigint[],g.id)`,
    [gymIds, audience, term, published, max, ...getTermBounds(term)],
  );
  const availableIds = new Set(found.rows.map(row => String(row.id)));
  const unavailableIds = gymIds.filter(id => !availableIds.has(id));
  if (found.rows.length) ctx.actions.push({ type: 'compare', gymIds: found.rows.map(row => String(row.id)) });
  return {
    ok: true,
    filters: ctx.filters,
    gyms: found.rows.map(publicGym),
    unavailableIds,
    note: 'Сравниваются выбранные тарифы с сохранением срока, аудитории, бюджета и источника цены. unavailableIds — нет подходящего тарифа; месячная замена не применяется.',
  };
}

/** Execute only the named, validated site capabilities using the server-owned account. */
export async function executeTool(
  name: string,
  args: unknown,
  ctx: AssistantContext,
): Promise<Record<string, unknown>> {
  switch (name) {
    case 'search_gyms':
      return search(args, ctx);
    case 'get_gym':
      return getGym(args, ctx);
    case 'compare_gyms':
      return compareGyms(args, ctx);
    case 'list_favorites': {
      emptyArgsSchema.parse(args);
      if (!requireAccount(ctx)) return loginRequired;
      const found = await searchGyms(ctx.filters, ctx.accountId, true, ctx.db);
      ctx.results = found.gyms.map(gym => String(gym.id));
      ctx.actions.push({ type: 'view', view: 'favorites' });
      return { ok: true, ...found, gyms: found.gyms.map(publicGym), filters: ctx.filters };
    }
    case 'set_favorite': {
      const { gymId, favorite } = z.object({ gymId: gymIdSchema, favorite: z.boolean() }).strict().parse(args);
      if (!requireAccount(ctx)) return loginRequired;
      const gym = await findGym(ctx, gymId);
      if (!gym) return { ok: false, error: 'GYM_NOT_FOUND', gymId };
      if (favorite) {
        await ctx.db.query(
          'INSERT INTO gym_web.favorites(account_id,gym_id) VALUES($1,$2) ON CONFLICT DO NOTHING',
          [ctx.accountId, gymId],
        );
      } else {
        await ctx.db.query('DELETE FROM gym_web.favorites WHERE account_id=$1 AND gym_id=$2', [ctx.accountId, gymId]);
      }
      ctx.actions.push({ type: 'favorites_changed' });
      return { ok: true, gymId, gymName: gym.name, favorite };
    }
    case 'navigate_site': {
      const { view } = z.object({ view: z.enum(views) }).strict().parse(args);
      if (view === 'favorites' && !requireAccount(ctx)) return loginRequired;
      ctx.actions.push({ type: 'view', view });
      return { ok: true, view };
    }
    case 'open_gym': {
      const { gymId } = idArgsSchema.parse(args);
      const gym = await findGym(ctx, gymId);
      if (!gym) return { ok: false, error: 'GYM_NOT_FOUND', gymId };
      ctx.actions.push({ type: 'open_gym', gymId });
      return { ok: true, gym: publicGym(gym) };
    }
    case 'prepare_review': {
      const parsed = z.object({
        gymId: gymIdSchema,
        rating: z.number().int().min(1).max(5),
        content: z.string().trim().min(3).max(2000),
      }).strict().parse(args);
      if (!requireAccount(ctx)) return loginRequired;
      const gym = await findGym(ctx, parsed.gymId);
      if (!gym) return { ok: false, error: 'GYM_NOT_FOUND', gymId: parsed.gymId };
      ctx.pendingReview = { ...parsed, gymName: String(gym.name) };
      return { ok: true, requiresConfirmation: true, published: false, draft: ctx.pendingReview };
    }
    default:
      throw new Error('UNKNOWN_ASSISTANT_TOOL');
  }
}
