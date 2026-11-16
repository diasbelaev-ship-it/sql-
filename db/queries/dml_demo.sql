-- INSERT, UPDATE, DELETE: две демонстрации каждого действия. Всё откатывается.
SET search_path = almaty_gym, public;
BEGIN;
-- D01 INSERT №1
INSERT INTO gyms (name,address,latitude,longitude,geo_accuracy_m,city_zone,price_band,source_url,source_checked_on)
VALUES ('Учебный временный зал','Учебный адрес',43.250000,76.900000,8000,'center','budget','https://example.test/demo',DATE '2026-11-09');
-- D02 INSERT №2
INSERT INTO clients (full_name,email,segment) VALUES ('Временный клиент','temporary@example.test','student');
-- D03 UPDATE №1
UPDATE gyms SET price_band='standard' WHERE name='Учебный временный зал';
-- D04 UPDATE №2
UPDATE clients SET segment='adult' WHERE email='temporary@example.test';
SELECT name,price_band FROM gyms WHERE name='Учебный временный зал';
SELECT full_name,segment FROM clients WHERE email='temporary@example.test';
-- D05 DELETE №1
DELETE FROM clients WHERE email='temporary@example.test';
-- D06 DELETE №2
DELETE FROM gyms WHERE name='Учебный временный зал';
ROLLBACK;
SELECT count(*) AS temporary_gyms_after_rollback FROM gyms WHERE name='Учебный временный зал';
