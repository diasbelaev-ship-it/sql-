-- Запросы по критериям кейса. Все суммы в тенге; модельные цены не являются офертой клуба.
SET search_path = almaty_gym, public;

-- Q01 SELECT / WHERE / ORDER BY: доступные студенту месячные планы.
SELECT g.name, g.address, p.price_kzt FROM gyms g
JOIN plans p ON p.gym_id=g.id
WHERE p.audience='student' AND p.duration_days=30 AND p.price_kzt<=20000
ORDER BY p.price_kzt, g.name LIMIT 10;

-- Q02 JOIN 1: базовая стоимость по залам.
SELECT g.name, g.price_band, p.price_kzt, p.price_basis FROM gyms g
JOIN plans p ON p.gym_id=g.id AND p.audience='adult' AND p.duration_days=30
ORDER BY p.price_kzt DESC, g.id LIMIT 10;

-- Q03 JOIN 2: тренер и его зал.
SELECT g.name AS gym, t.full_name, t.specialty FROM trainers t
JOIN gyms g ON g.id=t.gym_id ORDER BY g.id LIMIT 10;

-- Q04 JOIN 3: расписание, тренер и зал.
SELECT g.name AS gym, c.title, c.weekday, c.start_time, t.full_name AS trainer
FROM classes c JOIN gyms g ON g.id=c.gym_id JOIN trainers t ON t.id=c.trainer_id
ORDER BY g.id,c.weekday LIMIT 10;

-- Q05 JOIN 4: абонемент клиента и ценовая категория.
SELECT cl.full_name, cl.segment, g.name AS gym, p.price_kzt, m.status
FROM memberships m JOIN clients cl ON cl.id=m.client_id
JOIN plans p ON p.id=m.plan_id JOIN gyms g ON g.id=p.gym_id
ORDER BY m.id LIMIT 10;

-- Q06 JOIN 5: платежи и покупатели.
SELECT cl.full_name, pay.method, pay.amount_kzt, pay.status
FROM payments pay JOIN memberships m ON m.id=pay.membership_id
JOIN clients cl ON cl.id=m.client_id ORDER BY pay.id LIMIT 10;

-- Q07 JOIN 6: отзывы; здесь они учебные, не оценки реальных посетителей.
SELECT g.name, cl.full_name, r.rating, r.is_demo
FROM reviews r JOIN gyms g ON g.id=r.gym_id JOIN clients cl ON cl.id=r.client_id
ORDER BY r.id LIMIT 10;

-- Q08 JOIN 7: записи на занятия.
SELECT cl.full_name, g.name AS gym, c.title, b.booked_for
FROM bookings b JOIN classes c ON c.id=b.class_id
JOIN gyms g ON g.id=c.gym_id JOIN clients cl ON cl.id=b.client_id
ORDER BY b.id LIMIT 10;

-- Q09 JOIN 8: удобства (тестовые) по залам и регионам города.
SELECT g.city_zone, g.name, a.amenity_code FROM gym_amenities a
JOIN gyms g ON g.id=a.gym_id
WHERE a.amenity_code='cardio' ORDER BY g.city_zone,g.name LIMIT 10;

-- Q10 GROUP BY / COUNT / AVG: средняя учебная цена взрослого по ценовому сегменту.
SELECT g.price_band, count(*) AS gyms, round(avg(p.price_kzt))::integer AS avg_adult_month_kzt
FROM gyms g JOIN plans p ON p.gym_id=g.id AND p.audience='adult' AND p.duration_days=30
GROUP BY g.price_band ORDER BY avg_adult_month_kzt;

-- Q11 GROUP BY / HAVING / SUM: оплаченный объём по зонам с выручкой более 200 тыс.
SELECT g.city_zone, count(*) AS payments, sum(pay.amount_kzt) AS paid_kzt
FROM payments pay JOIN memberships m ON m.id=pay.membership_id
JOIN plans p ON p.id=m.plan_id JOIN gyms g ON g.id=p.gym_id
WHERE pay.status='paid' GROUP BY g.city_zone
HAVING sum(pay.amount_kzt)>200000 ORDER BY paid_kzt DESC;

-- Q12 Подзапрос 1: планы выше средней цены среди месячных взрослых.
SELECT g.name, p.price_kzt FROM plans p JOIN gyms g ON g.id=p.gym_id
WHERE p.audience='adult' AND p.duration_days=30
  AND p.price_kzt>(SELECT avg(price_kzt) FROM plans WHERE audience='adult' AND duration_days=30)
ORDER BY p.price_kzt DESC LIMIT 10;

-- Q13 Подзапрос 2 EXISTS: залы с опубликованной, а не модельной ценой.
SELECT g.name FROM gyms g WHERE EXISTS
  (SELECT 1 FROM plans p WHERE p.gym_id=g.id AND p.price_basis='published')
ORDER BY g.id;

-- Q14 Подзапрос 3 IN: клиенты с учебным премиальным тарифом.
SELECT full_name, segment FROM clients WHERE id IN
  (SELECT m.client_id FROM memberships m JOIN plans p ON p.id=m.plan_id WHERE p.audience='premium')
ORDER BY id LIMIT 10;

-- Q15 Подзапрос 4 коррелированный: зал выше средней цены своей городской зоны.
SELECT g.name, g.city_zone, p.price_kzt FROM gyms g
JOIN plans p ON p.gym_id=g.id AND p.audience='adult' AND p.duration_days=30
WHERE p.price_kzt>(SELECT avg(p2.price_kzt) FROM gyms g2 JOIN plans p2 ON p2.gym_id=g2.id
                   WHERE g2.city_zone=g.city_zone AND p2.audience='adult' AND p2.duration_days=30)
ORDER BY p.price_kzt DESC LIMIT 10;

-- Q16 Подзапрос 5 FROM: агрегат оплат по залам.
SELECT g.name, x.payments, x.total_kzt FROM gyms g JOIN
  (SELECT p.gym_id, count(*) AS payments, sum(pay.amount_kzt) AS total_kzt
   FROM payments pay JOIN memberships m ON m.id=pay.membership_id
   JOIN plans p ON p.id=m.plan_id WHERE pay.status='paid' GROUP BY p.gym_id) x
ON x.gym_id=g.id ORDER BY x.total_kzt DESC LIMIT 10;

-- Q17 VIEW: компактное сравнение трёх учебных ценовых категорий.
SELECT gym_id,name,city_zone,price_band,student_month_kzt,adult_month_kzt,premium_month_kzt
FROM v_gym_prices ORDER BY adult_month_kzt,gym_id LIMIT 10;

-- Q18 VIEW: географические зоны являются приблизительными учебными метками.
SELECT * FROM v_zone_summary ORDER BY city_zone,price_band;
