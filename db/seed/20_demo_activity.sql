-- Все строки ниже синтетические. Только название/адрес залов в 10_real_gyms.sql основаны на источниках.
SET search_path = almaty_gym, public;

WITH base AS (
  SELECT g.id AS gym_id, g.price_band,
         CASE g.price_band
           WHEN 'budget' THEN 15000 + (g.id % 4)::integer * 1000
           WHEN 'standard' THEN 24000 + (g.id % 5)::integer * 1500
           ELSE 40000 + (g.id % 5)::integer * 3000
         END AS adult_price
  FROM gyms g
), priced AS (
  SELECT gym_id, price_band,
         CASE WHEN gym_id=21 THEN 31000 WHEN gym_id=22 THEN 26000 ELSE adult_price END AS adult_price
  FROM base
)
INSERT INTO plans (id, gym_id, name, audience, duration_days, price_kzt,
                   price_basis, price_source_url, price_checked_on)
OVERRIDING SYSTEM VALUE
SELECT (p.gym_id-1)*3+s.n, p.gym_id,
       CASE s.n WHEN 1 THEN 'Учебный студенческий — 30 дней'
                WHEN 2 THEN 'Базовый — 30 дней'
                ELSE 'Учебный расширенный — 30 дней' END,
       s.audience, 30,
       CASE s.n WHEN 1 THEN CASE WHEN p.gym_id=22 THEN 20000
                                ELSE (floor(p.adult_price*0.8/500)*500)::integer END
                WHEN 2 THEN p.adult_price
                ELSE CASE WHEN p.gym_id=21 THEN 46000
                          ELSE (round(p.adult_price*1.5/1000)*1000)::integer END END,
       CASE WHEN (p.gym_id=21 AND s.n IN (2,3)) OR (p.gym_id=22 AND s.n IN (1,2))
            THEN 'published' ELSE 'model_estimate' END,
       CASE WHEN p.gym_id=21 AND s.n IN (2,3)
            THEN 'https://fitnestastak.kz/ru/page/klubnaya-karta'
            WHEN p.gym_id=22 AND s.n IN (1,2)
            THEN 'https://www.firstfitness.kz/' END,
       DATE '2026-11-09'
FROM priced p CROSS JOIN (VALUES (1,'student'),(2,'adult'),(3,'premium')) AS s(n,audience)
ORDER BY p.gym_id, s.n;

-- Опубликованные годовые цены Invictus не выдаются за месячные тарифы.
INSERT INTO plans (id, gym_id, name, audience, duration_days, price_kzt,
                   price_basis, price_source_url, price_checked_on)
OVERRIDING SYSTEM VALUE
SELECT 210 + g.id - 60, g.id, 'Годовой тариф по каталогу Invictus',
       'adult', 365,
       CASE WHEN g.id=68 THEN 240000 WHEN g.id=70 THEN 280000 ELSE 219000 END,
       'published', 'https://invictus.kz/ru-kz/clubs', DATE '2026-11-09'
FROM gyms g WHERE g.id BETWEEN 61 AND 70 ORDER BY g.id;
SELECT setval(pg_get_serial_sequence('almaty_gym.plans','id'), 220, true);

INSERT INTO clients (id, full_name, email, segment) OVERRIDING SYSTEM VALUE
SELECT (g.id-1)*3+s.n, 'Учебный клиент ' || lpad(((g.id-1)*3+s.n)::text,3,'0'),
       'client' || lpad(((g.id-1)*3+s.n)::text,3,'0') || '@example.test', s.audience
FROM gyms g CROSS JOIN (VALUES (1,'student'),(2,'adult'),(3,'premium')) AS s(n,audience)
ORDER BY g.id, s.n;
SELECT setval(pg_get_serial_sequence('almaty_gym.clients','id'), 210, true);

INSERT INTO trainers (id, gym_id, full_name, specialty) OVERRIDING SYSTEM VALUE
SELECT g.id, g.id, 'Учебный тренер ' || lpad(g.id::text,2,'0'),
       CASE WHEN g.id % 2=0 THEN 'Силовой тренинг' ELSE 'Функциональный тренинг' END
FROM gyms g ORDER BY g.id;
SELECT setval(pg_get_serial_sequence('almaty_gym.trainers','id'), 70, true);

INSERT INTO classes (id, gym_id, trainer_id, title, weekday, start_time, capacity)
OVERRIDING SYSTEM VALUE
SELECT (g.id-1)*2+s.n, g.id, g.id,
       CASE s.n WHEN 1 THEN 'Силовая тренировка' ELSE 'Функциональная тренировка' END,
       CASE s.n WHEN 1 THEN 1 ELSE 3 END,
       CASE s.n WHEN 1 THEN TIME '18:00' ELSE TIME '19:00' END,
       12
FROM gyms g CROSS JOIN (VALUES (1),(2)) AS s(n) ORDER BY g.id,s.n;
SELECT setval(pg_get_serial_sequence('almaty_gym.classes','id'), 140, true);

INSERT INTO memberships (id, client_id, plan_id, starts_on, ends_on, status, price_paid_kzt)
OVERRIDING SYSTEM VALUE
SELECT c.id, c.id, p.id, DATE '2026-11-09', DATE '2026-12-09', 'active', p.price_kzt
FROM clients c JOIN plans p ON p.id=c.id ORDER BY c.id;
SELECT setval(pg_get_serial_sequence('almaty_gym.memberships','id'), 210, true);

INSERT INTO payments (id, membership_id, amount_kzt, method, status, paid_at)
OVERRIDING SYSTEM VALUE
SELECT m.id, m.id, m.price_paid_kzt,
       CASE m.id % 3 WHEN 0 THEN 'kaspi' WHEN 1 THEN 'card' ELSE 'cash' END,
       'paid', TIMESTAMPTZ '2026-11-09 09:00:00+05'
FROM memberships m ORDER BY m.id;
SELECT setval(pg_get_serial_sequence('almaty_gym.payments','id'), 210, true);

INSERT INTO reviews (id, client_id, gym_id, rating, comment) OVERRIDING SYSTEM VALUE
SELECT g.id, (g.id-1)*3+2, g.id, (3+g.id%3)::smallint,
       'Учебный отзыв для проверки SQL; не является отзывом посетителя.'
FROM gyms g ORDER BY g.id;
SELECT setval(pg_get_serial_sequence('almaty_gym.reviews','id'), 70, true);

INSERT INTO bookings (id, client_id, class_id, booked_for, status)
OVERRIDING SYSTEM VALUE
SELECT c.id, (c.gym_id-1)*3+c.class_no, c.id,
       CASE c.class_no WHEN 1 THEN DATE '2026-11-09' ELSE DATE '2026-11-11' END,
       'booked'
FROM (SELECT id, gym_id, ((id-1)%2)+1 AS class_no FROM classes) c ORDER BY c.id;
SELECT setval(pg_get_serial_sequence('almaty_gym.bookings','id'), 140, true);

INSERT INTO gym_amenities (gym_id, amenity_code)
SELECT g.id, x.code FROM gyms g
CROSS JOIN (VALUES ('cardio'),('weights'),('showers'),('group_classes')) AS x(code)
ORDER BY g.id,x.code;

ANALYZE;
