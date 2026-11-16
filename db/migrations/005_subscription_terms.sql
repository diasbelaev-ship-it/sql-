-- Миграция 005. Учебные варианты на 2, 3, 6 и 9 месяцев (30 дней в месяце).
-- Это расчёт от базового 30-дневного тарифа без скидок, а не новая оферта клуба.
-- Даже если исходная месячная цена опубликована, длинный вариант остаётся оценкой.
-- Повторный запуск сохраняет уже существующие тарифы и не меняет данные сайта.
SET search_path = almaty_gym, public;

DO $$
DECLARE
  plan_sequence regclass := pg_get_serial_sequence('almaty_gym.plans', 'id')::regclass;
  sequence_value bigint;
  highest_id bigint;
BEGIN
  -- Сериализуем записи в plans на время согласования identity после старого seed.
  LOCK TABLE almaty_gym.plans IN SHARE ROW EXCLUSIVE MODE;
  SELECT COALESCE(MAX(id), 0) INTO highest_id FROM almaty_gym.plans;
  EXECUTE format('SELECT last_value FROM %s', plan_sequence) INTO sequence_value;
  PERFORM setval(plan_sequence, GREATEST(highest_id, sequence_value, 1), true);

  INSERT INTO almaty_gym.plans
    (gym_id, name, audience, duration_days, price_kzt,
     price_basis, price_source_url, price_checked_on)
  SELECT base.gym_id,
         format('Учебный расчёт — %s %s (%s дней)', term.months,
                CASE term.months WHEN 2 THEN 'месяца' WHEN 3 THEN 'месяца' ELSE 'месяцев' END,
                term.months * 30),
         base.audience, term.months * 30, base.price_kzt * term.months,
         'model_estimate', NULL, CURRENT_DATE
  FROM almaty_gym.plans base
  CROSS JOIN (VALUES (2), (3), (6), (9)) AS term(months)
  WHERE base.duration_days = 30
    AND NOT EXISTS (
      SELECT 1 FROM almaty_gym.plans existing
      WHERE existing.gym_id = base.gym_id
        AND existing.audience = base.audience
        AND existing.duration_days = term.months * 30
    )
  ORDER BY base.gym_id, base.audience, term.months
  ON CONFLICT (gym_id, audience, duration_days) DO NOTHING;
END $$;

ANALYZE almaty_gym.plans;
