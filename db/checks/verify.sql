-- Проверка критериев DOCX: 10 связанных таблиц, >=70 строк в каждой, >=1000 всего.
SET search_path = almaty_gym, public;
DO $$
DECLARE r record; n bigint; table_count integer := 0; total_rows bigint := 0;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname='almaty_gym' ORDER BY tablename LOOP
    EXECUTE format('SELECT count(*) FROM almaty_gym.%I',r.tablename) INTO n;
    RAISE NOTICE '%: % строк',r.tablename,n;
    IF n < 70 THEN RAISE EXCEPTION 'В таблице % меньше 70 строк: %',r.tablename,n; END IF;
    table_count := table_count+1; total_rows := total_rows+n;
  END LOOP;
  IF table_count <> 10 THEN RAISE EXCEPTION 'Нужно 10 таблиц, найдено %',table_count; END IF;
  IF total_rows < 1000 THEN RAISE EXCEPTION 'Меньше 1000 строк: %',total_rows; END IF;
  IF (SELECT count(*) FROM gyms) <> 70 THEN RAISE EXCEPTION 'Ожидалось 70 реальных названий залов'; END IF;
  IF (SELECT count(*) FROM plans WHERE price_basis='published') <> 14 THEN
    RAISE EXCEPTION 'Неверное число тарифов с опубликованной ценой';
  END IF;
  IF (SELECT count(*) FROM plans) <> 1060 THEN
    RAISE EXCEPTION 'Ожидалось 1060 тарифов после миграции сроков';
  END IF;
  IF total_rows <> 2460 THEN
    RAISE EXCEPTION 'Ожидалось 2460 строк SQL-кейса, найдено %',total_rows;
  END IF;
  IF EXISTS (
    SELECT 1 FROM plans base
    CROSS JOIN (VALUES (60), (90), (180), (270)) AS term(days)
    LEFT JOIN plans longer ON longer.gym_id=base.gym_id
                          AND longer.audience=base.audience
                          AND longer.duration_days=term.days
    WHERE base.duration_days=30 AND longer.id IS NULL
  ) THEN
    RAISE EXCEPTION 'Не для каждого месячного тарифа есть варианты на 2/3/6/9 месяцев';
  END IF;
  IF (SELECT count(*) FROM plans WHERE duration_days IN (60,90,180,270)) <> 840 THEN
    RAISE EXCEPTION 'Ожидалось 840 новых вариантов срока абонемента';
  END IF;
  IF EXISTS (
    SELECT 1 FROM plans longer JOIN plans base
      ON base.gym_id=longer.gym_id AND base.audience=longer.audience AND base.duration_days=30
    WHERE longer.duration_days IN (60,90,180,270)
      AND (longer.price_kzt<>base.price_kzt*(longer.duration_days/30)
           OR longer.price_basis<>'model_estimate' OR longer.price_source_url IS NOT NULL
           OR longer.name NOT LIKE 'Учебный расчёт%')
  ) THEN
    RAISE EXCEPTION 'Длинные учебные тарифы имеют неверную цену или пометку источника';
  END IF;
  IF EXISTS (SELECT 1 FROM v_gym_prices WHERE student_month_kzt > adult_month_kzt
                                               OR adult_month_kzt > premium_month_kzt) THEN
    RAISE EXCEPTION 'Учебные ценовые категории нарушены';
  END IF;
  IF EXISTS (SELECT 1 FROM memberships m JOIN plans p ON p.id=m.plan_id
             WHERE m.ends_on <> m.starts_on+p.duration_days OR m.price_paid_kzt<>p.price_kzt) THEN
    RAISE EXCEPTION 'Абонемент не совпадает с тарифом';
  END IF;
  IF EXISTS (SELECT 1 FROM memberships m LEFT JOIN payments p ON p.membership_id=m.id AND p.status='paid'
             WHERE p.id IS NULL OR p.amount_kzt<>m.price_paid_kzt) THEN
    RAISE EXCEPTION 'Неоплаченный или неверно оплаченный абонемент';
  END IF;
  IF EXISTS (SELECT 1 FROM bookings b JOIN classes c ON c.id=b.class_id
             JOIN memberships m ON m.client_id=b.client_id
             JOIN plans p ON p.id=m.plan_id
             WHERE c.gym_id<>p.gym_id OR EXTRACT(ISODOW FROM b.booked_for)<>c.weekday
                OR b.booked_for NOT BETWEEN m.starts_on AND m.ends_on) THEN
    RAISE EXCEPTION 'Запись не соответствует клубу, расписанию или абонементу';
  END IF;
  IF (SELECT count(*) FROM gyms WHERE geo_accuracy_m=1000) <> 67
     OR (SELECT count(*) FROM gyms WHERE geo_accuracy_m=8000) <> 3 THEN
    RAISE EXCEPTION 'Неверная отметка проверенных и приблизительных координат';
  END IF;
  IF EXISTS (SELECT 1 FROM gyms WHERE geo_accuracy_m=1000 AND city_zone <> CASE
    WHEN longitude < 76.87 THEN 'west'
    WHEN latitude > 43.28 THEN 'north'
    WHEN latitude < 43.225 THEN 'south'
    ELSE 'center' END) THEN
    RAISE EXCEPTION 'Городская зона не соответствует точке из источника';
  END IF;
  IF EXISTS (SELECT 1 FROM gyms WHERE source_url IS NULL OR source_url IN
    ('https://1fit.app/ru/almaty/gym','https://invictus.kz/ru-kz/clubs')) THEN
    RAISE EXCEPTION 'У зала отсутствует прямая страница источника';
  END IF;
  RAISE NOTICE 'ПРОВЕРКА ПРОЙДЕНА: % таблиц, % строк',table_count,total_rows;
END $$;

SELECT 'gyms' AS metric,count(*) AS value FROM gyms
UNION ALL SELECT 'all_rows',(SELECT sum(n) FROM (
  SELECT count(*) n FROM gyms UNION ALL SELECT count(*) FROM plans
  UNION ALL SELECT count(*) FROM clients UNION ALL SELECT count(*) FROM trainers
  UNION ALL SELECT count(*) FROM classes UNION ALL SELECT count(*) FROM memberships
  UNION ALL SELECT count(*) FROM payments UNION ALL SELECT count(*) FROM reviews
  UNION ALL SELECT count(*) FROM bookings UNION ALL SELECT count(*) FROM gym_amenities
) x)
UNION ALL SELECT 'published_prices',count(*) FROM plans WHERE price_basis='published'
UNION ALL SELECT 'plans',count(*) FROM plans
UNION ALL SELECT 'extended_term_estimates',count(*) FROM plans
  WHERE duration_days IN (60,90,180,270) AND price_basis='model_estimate'
ORDER BY metric;
