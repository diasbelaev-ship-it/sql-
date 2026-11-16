-- Verified direct venue pages. Coordinates are provider map points, not independent address geocoding.
-- Three out-of-range provider points (38, 46, 50) remain approximate and are excluded from distance/map UI.
DO $$
DECLARE changed integer;
BEGIN
  WITH verified(id, expected_name, source_url, latitude, longitude) AS (
    VALUES
    (1, 'Gym Point', 'https://1fit.app/ru/almaty/studios/736-gym-point', 43.236295, 76.851195),
    (2, 'ProGym', 'https://1fit.app/ru/almaty/studios/1679-progym', 43.261893, 76.956685),
    (3, 'FitnessBlitz', 'https://1fit.app/ru/almaty/studios/2916-fitnessblitz', 43.234845, 76.955769),
    (4, 'AYUMAN WORKOUT', 'https://1fit.app/ru/almaty/studios/4631-ayuman-workout', 43.287227, 76.990596),
    (5, 'Velvet Sport Villa', 'https://1fit.app/ru/almaty/studios/2044-velvet-sport-villa', 43.205846, 76.927643),
    (6, 'Aquastars на Навои', 'https://1fit.app/ru/almaty/studios/3049-aquastars-%D0%BD%D0%B0-%D0%BD%D0%B0%D0%B2%D0%BE%D0%B8', 43.205163, 76.885458),
    (7, 'Underground big на Абая', 'https://1fit.app/ru/almaty/studios/4953-underground-big-%D0%BD%D0%B0-%D0%B0%D0%B1%D0%B0%D1%8F', 43.237733, 76.884131),
    (8, 'ADRENALINE на Райымбека', 'https://1fit.app/ru/almaty/studios/5036-adrenaline-%D0%BD%D0%B0-%D1%80%D0%B0%D0%B9%D1%8B%D0%BC%D0%B1%D0%B5%D0%BA%D0%B0', 43.255165, 76.863670),
    (9, 'Aquastars на Яссауи', 'https://1fit.app/ru/almaty/studios/1282-aquastars-%D0%BD%D0%B0-%D1%8F%D1%81%D1%81%D0%B0%D1%83%D0%B8', 43.200885, 76.837846),
    (10, 'Erbil Grand Hotel', 'https://1fit.app/ru/almaty/studios/1476-erbil-grand-hotel', 43.336761, 76.948699),
    (11, 'BOSSTANGYM', 'https://1fit.app/ru/almaty/studios/1949-bosstangym', 43.267171, 76.933527),
    (12, 'King Fitness', 'https://1fit.app/ru/almaty/studios/3951-king-fitness', 43.211068, 76.794375),
    (13, 'Тренажерный зал IRONHOUSE.KZ', 'https://1fit.app/ru/almaty/studios/3861-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-ironhousekz', 43.245175, 76.933194),
    (14, 'Brooklyn Fitness Gym', 'https://1fit.app/ru/almaty/studios/68-brooklyn-fitness-gym', 43.236162, 76.938142),
    (15, 'FitnessBlitz Аксай', 'https://1fit.app/ru/almaty/studios/3359-fitnessblitz-%D0%B0%D0%BA%D1%81%D0%B0%D0%B9', 43.229550, 76.833167),
    (16, 'QFitness', 'https://1fit.app/ru/almaty/studios/754-qfitness', 43.238772, 76.943561),
    (17, 'Continental swimming club', 'https://1fit.app/ru/almaty/studios/1480-continental-swimming-club', 43.267853, 76.931504),
    (18, '100% Fitness Gym на Байзакова', 'https://1fit.app/ru/almaty/studios/4893-100-fitness-gym-%D0%BD%D0%B0-%D0%B1%D0%B0%D0%B9%D0%B7%D0%B0%D0%BA%D0%BE%D0%B2%D0%B0', 43.237248, 76.915066),
    (19, 'SK Boxing на Тимирязева', 'https://1fit.app/ru/almaty/studios/1263-sk-boxing-%D0%BD%D0%B0-%D1%82%D0%B8%D0%BC%D0%B8%D1%80%D1%8F%D0%B7%D0%B5%D0%B2%D0%B0', 43.225806, 76.890214),
    (20, 'Namys SK', 'https://1fit.app/ru/almaty/studios/670-namys-sk', 43.413644, 77.016458),
    (21, 'Фитнес-клуб "Тастак"', 'https://1fit.app/ru/almaty/studios/5208-%D1%84%D0%B8%D1%82%D0%BD%D0%B5%D1%81-%D0%BA%D0%BB%D1%83%D0%B1-%D1%82%D0%B0%D1%81%D1%82%D0%B0%D0%BA', 43.250474, 76.874431),
    (22, 'First Fitness Таугуль', 'https://1fit.app/ru/almaty/studios/48-first-fitness', 43.213792, 76.878593),
    (23, 'King Fitness Кайрат', 'https://1fit.app/ru/almaty/studios/5426-king-fitness-%D0%BA%D0%B0%D0%B9%D1%80%D0%B0%D1%82', 43.302327, 77.005437),
    (24, 'FitNova', 'https://1fit.app/ru/almaty/studios/5399-fitnova', 43.312312, 76.944675),
    (25, 'Baqgym', 'https://1fit.app/ru/almaty/studios/5367-baqgym', 43.224467, 76.828512),
    (26, 'Fitness Life Center', 'https://1fit.app/ru/almaty/studios/1754-fitness-life-center', 43.225754, 76.900163),
    (27, 'FitnessBlitz Искра', 'https://1fit.app/ru/almaty/studios/3358-fitnessblitz-%D0%B8%D1%81%D0%BA%D1%80%D0%B0', 43.255176, 76.932188),
    (28, 'Urban Gym', 'https://1fit.app/ru/almaty/studios/36-urban-gym', 43.232283, 76.948546),
    (29, 'Xan Gym', 'https://1fit.app/ru/almaty/studios/4396-xan-gym', 43.235991, 76.956369),
    (30, 'Тренажерный зал "HERMES"', 'https://1fit.app/ru/almaty/studios/2203-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-hermes', 43.325835, 76.923560),
    (31, 'Arena fitness hub', 'https://1fit.app/ru/almaty/studios/829-arena-fitness-hub', 43.264144, 76.817031),
    (32, 'First Fitness Коктем', 'https://1fit.app/ru/almaty/studios/5057-first-fitness-%D0%BA%D0%BE%D0%BA%D1%82%D0%B5%D0%BC', 43.232189, 76.923142),
    (33, 'BAZA sport club', 'https://1fit.app/ru/almaty/studios/4877-baza-sport-club', 43.300057, 77.002077),
    (34, 'Asyl Gym', 'https://1fit.app/ru/almaty/studios/1696-asyl-gym', 43.249884, 76.878954),
    (35, 'ProFitnessAMG', 'https://1fit.app/ru/almaty/studios/26-profitnessamg', 43.236742, 76.908627),
    (36, 'Titan Arms', 'https://1fit.app/ru/almaty/studios/4475-titan-arms', 43.224672, 76.781702),
    (37, 'Avantgarde Навои', 'https://1fit.app/ru/almaty/studios/2920-avantgarde-%D0%BD%D0%B0%D0%B2%D0%BE%D0%B8', 43.218749, 76.879970),
    (38, 'Hard Gym', 'https://1fit.app/ru/almaty/studios/4968-hard-gym', NULL, NULL),
    (39, '"Берлога" тренажерный зал', 'https://1fit.app/ru/almaty/studios/878-%D0%B1%D0%B5%D1%80%D0%BB%D0%BE%D0%B3%D0%B0-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB', 43.252156, 76.891041),
    (40, 'ТехноGym тренажерный зал', 'https://1fit.app/ru/almaty/studios/1455-%D1%82%D0%B5%D1%85%D0%BD%D0%BEgym-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB', 43.272317, 76.917743),
    (41, 'ADRENALINE на Арбате', 'https://1fit.app/ru/almaty/studios/1229-adrenaline-%D0%BD%D0%B0-%D0%B0%D1%80%D0%B1%D0%B0%D1%82%D0%B5', 43.262096, 76.949957),
    (42, 'ANGEL GYM', 'https://1fit.app/ru/almaty/studios/46-angel-gym', 43.237355, 76.842579),
    (43, 'Академия ЦСКА на Райымбека', 'https://1fit.app/ru/almaty/studios/2451-%D0%B0%D0%BA%D0%B0%D0%B4%D0%B5%D0%BC%D0%B8%D1%8F-%D1%86%D1%81%D0%BA%D0%B0-%D0%BD%D0%B0-%D1%80%D0%B0%D0%B9%D1%8B%D0%BC%D0%B1%D0%B5%D0%BA%D0%B0', 43.257356, 76.891342),
    (44, 'Gryphon Fitness', 'https://1fit.app/ru/almaty/studios/3803-gryphon-fitness', 43.265917, 76.967052),
    (45, '7GYM Fitness club ЖК Премьера', 'https://1fit.app/ru/almaty/studios/5429-7gym-fitness-club-%D0%B6%D0%BA-%D0%BF%D1%80%D0%B5%D0%BC%D1%8C%D0%B5%D1%80%D0%B0', 43.221930, 76.795734),
    (46, 'Orda', 'https://1fit.app/ru/almaty/studios/2312-orda', NULL, NULL),
    (47, 'НурФитнесс', 'https://1fit.app/ru/almaty/studios/2489-%D0%BD%D1%83%D1%80%D1%84%D0%B8%D1%82%D0%BD%D0%B5%D1%81%D1%81', 43.302550, 77.056964),
    (48, 'Тренажерный зал “AQONGYM”', 'https://1fit.app/ru/almaty/studios/2567-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-aqongym', 43.225872, 76.843866),
    (49, 'HARDWAY ЖК Теремки', 'https://1fit.app/ru/almaty/studios/2102-hardway-%D0%B6%D0%BA-%D1%82%D0%B5%D1%80%D0%B5%D0%BC%D0%BA%D0%B8', 43.328591, 76.940605),
    (50, 'Зал "Крепкий Орех" на Жамбыла', 'https://1fit.app/ru/almaty/studios/5368-%D0%B7%D0%B0%D0%BB-%D0%BA%D1%80%D0%B5%D0%BF%D0%BA%D0%B8%D0%B9-%D0%BE%D1%80%D0%B5%D1%85-%D0%BD%D0%B0-%D0%B6%D0%B0%D0%BC%D0%B1%D1%8B%D0%BB%D0%B0', NULL, NULL),
    (51, 'Тренажерный зал “AQONGYM AIR”', 'https://1fit.app/ru/almaty/studios/4922-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-aqongym-air', 43.317668, 76.973496),
    (52, 'Специализированный учебный центр "Меркурий Медет"', 'https://1fit.app/ru/almaty/studios/1159-%D1%81%D0%BF%D0%B5%D1%86%D0%B8%D0%B0%D0%BB%D0%B8%D0%B7%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%BD%D1%8B%D0%B9-%D1%83%D1%87%D0%B5%D0%B1%D0%BD%D1%8B%D0%B9-%D1%86%D0%B5%D0%BD%D1%82%D1%80-%D0%BC%D0%B5%D1%80%D0%BA%D1%83%D1%80%D0%B8%D0%B9-%D0%BC%D0%B5%D0%B4%D0%B5%D1%82', 43.267643, 76.969998),
    (53, 'BOSS FITNESS', 'https://1fit.app/ru/almaty/studios/724-boss-fitness', 43.376386, 76.991477),
    (54, 'Legion Fitness', 'https://1fit.app/ru/almaty/studios/106-legion-fitness', 43.267079, 76.869378),
    (55, 'NAUTILUS тренажерный зал Навои', 'https://1fit.app/ru/almaty/studios/719-nautilus-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-%D0%BD%D0%B0%D0%B2%D0%BE%D0%B8', 43.205163, 76.885458),
    (56, 'Ant Gym', 'https://1fit.app/ru/almaty/studios/4472-ant-gym', 43.208588, 76.912135),
    (57, '777 Fight Club & Gym', 'https://1fit.app/ru/almaty/studios/1772-777-fight-club-gym', 43.244184, 76.931460),
    (58, 'Gepard Sport Club', 'https://1fit.app/ru/almaty/studios/672-gepard-sport-club', 43.244120, 76.855805),
    (59, 'ProGym 3', 'https://1fit.app/ru/almaty/studios/3424-progym-3', 43.249811, 76.926951),
    (60, 'ADRENALINE на Достык', 'https://1fit.app/ru/almaty/studios/1230-adrenaline-%D0%BD%D0%B0-%D0%B4%D0%BE%D1%81%D1%82%D1%8B%D0%BA', 43.221727, 76.963647),
    (61, 'Invictus GO Abay', 'https://invictus.kz/ru-kz/clubs/go/go-abay', 43.239780, 76.884028),
    (62, 'Invictus GO Aport East', 'https://invictus.kz/ru-kz/clubs/go/go-aport-east', 43.314039, 77.025323),
    (63, 'Invictus GO Aqsay', 'https://invictus.kz/ru-kz/clubs/go/go-aqsay', 43.232391, 76.831656),
    (64, 'Invictus GO Arena', 'https://invictus.kz/ru-kz/clubs/go/go-arena', 43.275713, 76.816256),
    (65, 'Invictus GO Askarova', 'https://invictus.kz/ru-kz/clubs/go/go-askarova', 43.199714, 76.868029),
    (66, 'Invictus GO Atakent', 'https://invictus.kz/ru-kz/clubs/go/go-atakent', 43.224835, 76.910851),
    (67, 'Invictus GO Baitursynov', 'https://invictus.kz/ru-kz/clubs/go/go-baitursynov', 43.231028, 76.934520),
    (68, 'Invictus Girls Crystal', 'https://invictus.kz/ru-kz/clubs/girls/girls-crystal', 43.236715, 76.881630),
    (69, 'Invictus GO Fifty Four', 'https://invictus.kz/ru-kz/clubs/go/go-fifty-four', 43.266526, 76.935716),
    (70, 'Invictus Fitness Gagarin', 'https://invictus.kz/ru-kz/clubs/fitness/fitness-gagarin', 43.205254, 76.899298)
  )
  UPDATE almaty_gym.gyms AS g
     SET source_url = v.source_url,
         source_checked_on = DATE '2026-11-10',
         latitude = COALESCE(v.latitude, g.latitude),
         longitude = COALESCE(v.longitude, g.longitude),
         geo_accuracy_m = CASE WHEN v.latitude IS NULL THEN 8000 ELSE 1000 END,
         city_zone = CASE
           WHEN v.latitude IS NULL THEN g.city_zone
           WHEN v.longitude < 76.87 THEN 'west'
           WHEN v.latitude > 43.28 THEN 'north'
           WHEN v.latitude < 43.225 THEN 'south'
           ELSE 'center'
         END
    FROM verified AS v
   WHERE g.id = v.id AND g.name = v.expected_name;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 70 THEN
    RAISE EXCEPTION 'Expected 70 verified gym source updates, got %', changed;
  END IF;
END $$;

-- Published Invictus prices now link to the exact club page. Historical price checks remain unchanged.
UPDATE almaty_gym.plans AS p
   SET price_source_url = g.source_url
  FROM almaty_gym.gyms AS g
 WHERE p.gym_id = g.id AND g.id BETWEEN 61 AND 70
   AND p.price_basis = 'published';

-- Gagarin's direct club page displayed a 252 000 ₸ promotional annual price on 2026-11-10.
UPDATE almaty_gym.plans
   SET price_kzt = 252000,
       price_checked_on = DATE '2026-11-10'
 WHERE gym_id = 70 AND duration_days = 365 AND price_basis = 'published';

