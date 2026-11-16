-- Миграция 001. Изолированная схема учебного кейса, 10 связанных таблиц.
CREATE SCHEMA IF NOT EXISTS almaty_gym;
SET search_path = almaty_gym, public;

CREATE TABLE IF NOT EXISTS gyms (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  address text NOT NULL,
  latitude numeric(9,6) NOT NULL CHECK (latitude BETWEEN 43.10 AND 43.45),
  longitude numeric(9,6) NOT NULL CHECK (longitude BETWEEN 76.65 AND 77.20),
  geo_accuracy_m integer NOT NULL CHECK (geo_accuracy_m >= 1000),
  city_zone text NOT NULL CHECK (city_zone IN ('west','north','center','south')),
  price_band text NOT NULL CHECK (price_band IN ('budget','standard','premium')),
  source_url text NOT NULL CHECK (source_url LIKE 'https://%'),
  source_checked_on date NOT NULL,
  UNIQUE (name, address)
);

CREATE TABLE IF NOT EXISTS plans (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  gym_id bigint NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  name text NOT NULL,
  audience text NOT NULL CHECK (audience IN ('student','adult','premium')),
  duration_days integer NOT NULL CHECK (duration_days BETWEEN 1 AND 730),
  price_kzt integer NOT NULL CHECK (price_kzt > 0),
  price_basis text NOT NULL CHECK (price_basis IN ('published','model_estimate')),
  price_source_url text CHECK (price_source_url IS NULL OR price_source_url LIKE 'https://%'),
  price_checked_on date NOT NULL,
  UNIQUE (gym_id, audience, duration_days),
  CHECK (price_basis <> 'published' OR price_source_url IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS clients (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name text NOT NULL,
  email text NOT NULL UNIQUE CHECK (email LIKE '%@example.test'),
  segment text NOT NULL CHECK (segment IN ('student','adult','premium')),
  is_demo boolean NOT NULL DEFAULT true CHECK (is_demo)
);

CREATE TABLE IF NOT EXISTS trainers (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  gym_id bigint NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  specialty text NOT NULL,
  is_demo boolean NOT NULL DEFAULT true CHECK (is_demo),
  UNIQUE (id, gym_id)
);

CREATE TABLE IF NOT EXISTS classes (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  gym_id bigint NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  trainer_id bigint NOT NULL,
  title text NOT NULL,
  weekday smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),
  start_time time NOT NULL,
  capacity smallint NOT NULL CHECK (capacity BETWEEN 1 AND 50),
  FOREIGN KEY (trainer_id, gym_id) REFERENCES trainers(id, gym_id)
);

CREATE TABLE IF NOT EXISTS memberships (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id bigint NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  plan_id bigint NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  status text NOT NULL CHECK (status IN ('active','expired','cancelled')),
  price_paid_kzt integer NOT NULL CHECK (price_paid_kzt > 0),
  CHECK (ends_on > starts_on)
);

CREATE TABLE IF NOT EXISTS payments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  membership_id bigint NOT NULL REFERENCES memberships(id) ON DELETE CASCADE,
  amount_kzt integer NOT NULL CHECK (amount_kzt > 0),
  method text NOT NULL CHECK (method IN ('card','kaspi','cash')),
  status text NOT NULL CHECK (status IN ('paid','refunded','failed')),
  paid_at timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS reviews (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id bigint NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  gym_id bigint NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  rating smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text NOT NULL,
  is_demo boolean NOT NULL DEFAULT true CHECK (is_demo),
  UNIQUE (client_id, gym_id)
);

CREATE TABLE IF NOT EXISTS bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id bigint NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  class_id bigint NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  booked_for date NOT NULL,
  status text NOT NULL CHECK (status IN ('booked','attended','cancelled')),
  UNIQUE (client_id, class_id, booked_for)
);

CREATE TABLE IF NOT EXISTS gym_amenities (
  gym_id bigint NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  amenity_code text NOT NULL CHECK (amenity_code IN ('cardio','weights','showers','parking','group_classes','sauna')),
  is_demo boolean NOT NULL DEFAULT true CHECK (is_demo),
  PRIMARY KEY (gym_id, amenity_code)
);

COMMENT ON SCHEMA almaty_gym IS 'Учебный кейс: реальные названия и адреса залов Алматы; другие данные помечены как тестовые';
COMMENT ON COLUMN gyms.latitude IS 'Учебная приблизительная координата по району, не точка входа';
COMMENT ON COLUMN plans.price_basis IS 'published — указан в источнике; model_estimate — учебная оценка, не оферта клуба';
