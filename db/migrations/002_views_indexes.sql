-- Миграция 002. Индексы и представления для аналитики.
SET search_path = almaty_gym, public;
CREATE INDEX IF NOT EXISTS idx_gyms_zone_band ON gyms(city_zone, price_band);
CREATE INDEX IF NOT EXISTS idx_plans_audience_price ON plans(audience, price_kzt);
CREATE INDEX IF NOT EXISTS idx_plans_gym ON plans(gym_id);
CREATE INDEX IF NOT EXISTS idx_memberships_plan ON memberships(plan_id);
CREATE INDEX IF NOT EXISTS idx_classes_gym ON classes(gym_id);
CREATE INDEX IF NOT EXISTS idx_bookings_class ON bookings(class_id);
CREATE INDEX IF NOT EXISTS idx_reviews_gym ON reviews(gym_id);

CREATE OR REPLACE VIEW v_gym_prices AS
SELECT g.id AS gym_id, g.name, g.address, g.city_zone, g.price_band,
       g.latitude, g.longitude, g.geo_accuracy_m,
       MIN(p.price_kzt) FILTER (WHERE p.audience='student' AND p.duration_days=30) AS student_month_kzt,
       MIN(p.price_kzt) FILTER (WHERE p.audience='adult' AND p.duration_days=30) AS adult_month_kzt,
       MIN(p.price_kzt) FILTER (WHERE p.audience='premium' AND p.duration_days=30) AS premium_month_kzt,
       COUNT(*) FILTER (WHERE p.price_basis='published') AS published_plan_count
FROM gyms g LEFT JOIN plans p ON p.gym_id=g.id
GROUP BY g.id;

CREATE OR REPLACE VIEW v_zone_summary AS
SELECT city_zone, price_band, COUNT(*) AS gym_count,
       ROUND(AVG(adult_month_kzt))::integer AS avg_adult_month_kzt,
       ROUND(AVG(student_month_kzt))::integer AS avg_student_month_kzt
FROM v_gym_prices GROUP BY city_zone, price_band;
