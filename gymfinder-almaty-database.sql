--
-- PostgreSQL database dump
--

\restrict u0nS2xFqOFeXPsoKbRjTGGrF8IxjXkvzthfoaOGfDZezKbmhxNmXoAXm9DW2Fbo

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: almaty_gym; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA almaty_gym;


--
-- Name: SCHEMA almaty_gym; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA almaty_gym IS 'Учебный кейс: реальные названия и адреса залов Алматы; другие данные помечены как тестовые';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bookings; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.bookings (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    class_id bigint NOT NULL,
    booked_for date NOT NULL,
    status text NOT NULL,
    CONSTRAINT bookings_status_check CHECK ((status = ANY (ARRAY['booked'::text, 'attended'::text, 'cancelled'::text])))
);


--
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.bookings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.bookings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: classes; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.classes (
    id bigint NOT NULL,
    gym_id bigint NOT NULL,
    trainer_id bigint NOT NULL,
    title text NOT NULL,
    weekday smallint NOT NULL,
    start_time time without time zone NOT NULL,
    capacity smallint NOT NULL,
    CONSTRAINT classes_capacity_check CHECK (((capacity >= 1) AND (capacity <= 50))),
    CONSTRAINT classes_weekday_check CHECK (((weekday >= 1) AND (weekday <= 7)))
);


--
-- Name: classes_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.classes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: clients; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.clients (
    id bigint NOT NULL,
    full_name text NOT NULL,
    email text NOT NULL,
    segment text NOT NULL,
    is_demo boolean DEFAULT true NOT NULL,
    CONSTRAINT clients_email_check CHECK ((email ~~ '%@example.test'::text)),
    CONSTRAINT clients_is_demo_check CHECK (is_demo),
    CONSTRAINT clients_segment_check CHECK ((segment = ANY (ARRAY['student'::text, 'adult'::text, 'premium'::text])))
);


--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.clients ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: gym_amenities; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.gym_amenities (
    gym_id bigint NOT NULL,
    amenity_code text NOT NULL,
    is_demo boolean DEFAULT true NOT NULL,
    CONSTRAINT gym_amenities_amenity_code_check CHECK ((amenity_code = ANY (ARRAY['cardio'::text, 'weights'::text, 'showers'::text, 'parking'::text, 'group_classes'::text, 'sauna'::text]))),
    CONSTRAINT gym_amenities_is_demo_check CHECK (is_demo)
);


--
-- Name: gyms; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.gyms (
    id bigint NOT NULL,
    name text NOT NULL,
    address text NOT NULL,
    latitude numeric(9,6) NOT NULL,
    longitude numeric(9,6) NOT NULL,
    geo_accuracy_m integer NOT NULL,
    city_zone text NOT NULL,
    price_band text NOT NULL,
    source_url text NOT NULL,
    source_checked_on date NOT NULL,
    CONSTRAINT gyms_city_zone_check CHECK ((city_zone = ANY (ARRAY['west'::text, 'north'::text, 'center'::text, 'south'::text]))),
    CONSTRAINT gyms_geo_accuracy_m_check CHECK ((geo_accuracy_m >= 1000)),
    CONSTRAINT gyms_latitude_check CHECK (((latitude >= 43.10) AND (latitude <= 43.45))),
    CONSTRAINT gyms_longitude_check CHECK (((longitude >= 76.65) AND (longitude <= 77.20))),
    CONSTRAINT gyms_price_band_check CHECK ((price_band = ANY (ARRAY['budget'::text, 'standard'::text, 'premium'::text]))),
    CONSTRAINT gyms_source_url_check CHECK ((source_url ~~ 'https://%'::text))
);


--
-- Name: COLUMN gyms.latitude; Type: COMMENT; Schema: almaty_gym; Owner: -
--

COMMENT ON COLUMN almaty_gym.gyms.latitude IS 'Учебная приблизительная координата по району, не точка входа';


--
-- Name: gyms_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.gyms ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.gyms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: memberships; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.memberships (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    plan_id bigint NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    status text NOT NULL,
    price_paid_kzt integer NOT NULL,
    CONSTRAINT memberships_check CHECK ((ends_on > starts_on)),
    CONSTRAINT memberships_price_paid_kzt_check CHECK ((price_paid_kzt > 0)),
    CONSTRAINT memberships_status_check CHECK ((status = ANY (ARRAY['active'::text, 'expired'::text, 'cancelled'::text])))
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.memberships ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: payments; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.payments (
    id bigint NOT NULL,
    membership_id bigint NOT NULL,
    amount_kzt integer NOT NULL,
    method text NOT NULL,
    status text NOT NULL,
    paid_at timestamp with time zone NOT NULL,
    CONSTRAINT payments_amount_kzt_check CHECK ((amount_kzt > 0)),
    CONSTRAINT payments_method_check CHECK ((method = ANY (ARRAY['card'::text, 'kaspi'::text, 'cash'::text]))),
    CONSTRAINT payments_status_check CHECK ((status = ANY (ARRAY['paid'::text, 'refunded'::text, 'failed'::text])))
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: plans; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.plans (
    id bigint NOT NULL,
    gym_id bigint NOT NULL,
    name text NOT NULL,
    audience text NOT NULL,
    duration_days integer NOT NULL,
    price_kzt integer NOT NULL,
    price_basis text NOT NULL,
    price_source_url text,
    price_checked_on date NOT NULL,
    CONSTRAINT plans_audience_check CHECK ((audience = ANY (ARRAY['student'::text, 'adult'::text, 'premium'::text]))),
    CONSTRAINT plans_check CHECK (((price_basis <> 'published'::text) OR (price_source_url IS NOT NULL))),
    CONSTRAINT plans_duration_days_check CHECK (((duration_days >= 1) AND (duration_days <= 730))),
    CONSTRAINT plans_price_basis_check CHECK ((price_basis = ANY (ARRAY['published'::text, 'model_estimate'::text]))),
    CONSTRAINT plans_price_kzt_check CHECK ((price_kzt > 0)),
    CONSTRAINT plans_price_source_url_check CHECK (((price_source_url IS NULL) OR (price_source_url ~~ 'https://%'::text)))
);


--
-- Name: COLUMN plans.price_basis; Type: COMMENT; Schema: almaty_gym; Owner: -
--

COMMENT ON COLUMN almaty_gym.plans.price_basis IS 'published — указан в источнике; model_estimate — учебная оценка, не оферта клуба';


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.plans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reviews; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.reviews (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    gym_id bigint NOT NULL,
    rating smallint NOT NULL,
    comment text NOT NULL,
    is_demo boolean DEFAULT true NOT NULL,
    CONSTRAINT reviews_is_demo_check CHECK (is_demo),
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.reviews ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: trainers; Type: TABLE; Schema: almaty_gym; Owner: -
--

CREATE TABLE almaty_gym.trainers (
    id bigint NOT NULL,
    gym_id bigint NOT NULL,
    full_name text NOT NULL,
    specialty text NOT NULL,
    is_demo boolean DEFAULT true NOT NULL,
    CONSTRAINT trainers_is_demo_check CHECK (is_demo)
);


--
-- Name: trainers_id_seq; Type: SEQUENCE; Schema: almaty_gym; Owner: -
--

ALTER TABLE almaty_gym.trainers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME almaty_gym.trainers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_gym_prices; Type: VIEW; Schema: almaty_gym; Owner: -
--

CREATE VIEW almaty_gym.v_gym_prices AS
SELECT
    NULL::bigint AS gym_id,
    NULL::text AS name,
    NULL::text AS address,
    NULL::text AS city_zone,
    NULL::text AS price_band,
    NULL::numeric(9,6) AS latitude,
    NULL::numeric(9,6) AS longitude,
    NULL::integer AS geo_accuracy_m,
    NULL::integer AS student_month_kzt,
    NULL::integer AS adult_month_kzt,
    NULL::integer AS premium_month_kzt,
    NULL::bigint AS published_plan_count;


--
-- Name: v_zone_summary; Type: VIEW; Schema: almaty_gym; Owner: -
--

CREATE VIEW almaty_gym.v_zone_summary AS
 SELECT city_zone,
    price_band,
    count(*) AS gym_count,
    (round(avg(adult_month_kzt)))::integer AS avg_adult_month_kzt,
    (round(avg(student_month_kzt)))::integer AS avg_student_month_kzt
   FROM almaty_gym.v_gym_prices
  GROUP BY city_zone, price_band;


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.bookings (id, client_id, class_id, booked_for, status) FROM stdin;
1	1	1	2026-11-09	booked
2	2	2	2026-11-11	booked
3	4	3	2026-11-09	booked
4	5	4	2026-11-11	booked
5	7	5	2026-11-09	booked
6	8	6	2026-11-11	booked
7	10	7	2026-11-09	booked
8	11	8	2026-11-11	booked
9	13	9	2026-11-09	booked
10	14	10	2026-11-11	booked
11	16	11	2026-11-09	booked
12	17	12	2026-11-11	booked
13	19	13	2026-11-09	booked
14	20	14	2026-11-11	booked
15	22	15	2026-11-09	booked
16	23	16	2026-11-11	booked
17	25	17	2026-11-09	booked
18	26	18	2026-11-11	booked
19	28	19	2026-11-09	booked
20	29	20	2026-11-11	booked
21	31	21	2026-11-09	booked
22	32	22	2026-11-11	booked
23	34	23	2026-11-09	booked
24	35	24	2026-11-11	booked
25	37	25	2026-11-09	booked
26	38	26	2026-11-11	booked
27	40	27	2026-11-09	booked
28	41	28	2026-11-11	booked
29	43	29	2026-11-09	booked
30	44	30	2026-11-11	booked
31	46	31	2026-11-09	booked
32	47	32	2026-11-11	booked
33	49	33	2026-11-09	booked
34	50	34	2026-11-11	booked
35	52	35	2026-11-09	booked
36	53	36	2026-11-11	booked
37	55	37	2026-11-09	booked
38	56	38	2026-11-11	booked
39	58	39	2026-11-09	booked
40	59	40	2026-11-11	booked
41	61	41	2026-11-09	booked
42	62	42	2026-11-11	booked
43	64	43	2026-11-09	booked
44	65	44	2026-11-11	booked
45	67	45	2026-11-09	booked
46	68	46	2026-11-11	booked
47	70	47	2026-11-09	booked
48	71	48	2026-11-11	booked
49	73	49	2026-11-09	booked
50	74	50	2026-11-11	booked
51	76	51	2026-11-09	booked
52	77	52	2026-11-11	booked
53	79	53	2026-11-09	booked
54	80	54	2026-11-11	booked
55	82	55	2026-11-09	booked
56	83	56	2026-11-11	booked
57	85	57	2026-11-09	booked
58	86	58	2026-11-11	booked
59	88	59	2026-11-09	booked
60	89	60	2026-11-11	booked
61	91	61	2026-11-09	booked
62	92	62	2026-11-11	booked
63	94	63	2026-11-09	booked
64	95	64	2026-11-11	booked
65	97	65	2026-11-09	booked
66	98	66	2026-11-11	booked
67	100	67	2026-11-09	booked
68	101	68	2026-11-11	booked
69	103	69	2026-11-09	booked
70	104	70	2026-11-11	booked
71	106	71	2026-11-09	booked
72	107	72	2026-11-11	booked
73	109	73	2026-11-09	booked
74	110	74	2026-11-11	booked
75	112	75	2026-11-09	booked
76	113	76	2026-11-11	booked
77	115	77	2026-11-09	booked
78	116	78	2026-11-11	booked
79	118	79	2026-11-09	booked
80	119	80	2026-11-11	booked
81	121	81	2026-11-09	booked
82	122	82	2026-11-11	booked
83	124	83	2026-11-09	booked
84	125	84	2026-11-11	booked
85	127	85	2026-11-09	booked
86	128	86	2026-11-11	booked
87	130	87	2026-11-09	booked
88	131	88	2026-11-11	booked
89	133	89	2026-11-09	booked
90	134	90	2026-11-11	booked
91	136	91	2026-11-09	booked
92	137	92	2026-11-11	booked
93	139	93	2026-11-09	booked
94	140	94	2026-11-11	booked
95	142	95	2026-11-09	booked
96	143	96	2026-11-11	booked
97	145	97	2026-11-09	booked
98	146	98	2026-11-11	booked
99	148	99	2026-11-09	booked
100	149	100	2026-11-11	booked
101	151	101	2026-11-09	booked
102	152	102	2026-11-11	booked
103	154	103	2026-11-09	booked
104	155	104	2026-11-11	booked
105	157	105	2026-11-09	booked
106	158	106	2026-11-11	booked
107	160	107	2026-11-09	booked
108	161	108	2026-11-11	booked
109	163	109	2026-11-09	booked
110	164	110	2026-11-11	booked
111	166	111	2026-11-09	booked
112	167	112	2026-11-11	booked
113	169	113	2026-11-09	booked
114	170	114	2026-11-11	booked
115	172	115	2026-11-09	booked
116	173	116	2026-11-11	booked
117	175	117	2026-11-09	booked
118	176	118	2026-11-11	booked
119	178	119	2026-11-09	booked
120	179	120	2026-11-11	booked
121	181	121	2026-11-09	booked
122	182	122	2026-11-11	booked
123	184	123	2026-11-09	booked
124	185	124	2026-11-11	booked
125	187	125	2026-11-09	booked
126	188	126	2026-11-11	booked
127	190	127	2026-11-09	booked
128	191	128	2026-11-11	booked
129	193	129	2026-11-09	booked
130	194	130	2026-11-11	booked
131	196	131	2026-11-09	booked
132	197	132	2026-11-11	booked
133	199	133	2026-11-09	booked
134	200	134	2026-11-11	booked
135	202	135	2026-11-09	booked
136	203	136	2026-11-11	booked
137	205	137	2026-11-09	booked
138	206	138	2026-11-11	booked
139	208	139	2026-11-09	booked
140	209	140	2026-11-11	booked
\.


--
-- Data for Name: classes; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.classes (id, gym_id, trainer_id, title, weekday, start_time, capacity) FROM stdin;
1	1	1	Силовая тренировка	1	18:00:00	12
2	1	1	Функциональная тренировка	3	19:00:00	12
3	2	2	Силовая тренировка	1	18:00:00	12
4	2	2	Функциональная тренировка	3	19:00:00	12
5	3	3	Силовая тренировка	1	18:00:00	12
6	3	3	Функциональная тренировка	3	19:00:00	12
7	4	4	Силовая тренировка	1	18:00:00	12
8	4	4	Функциональная тренировка	3	19:00:00	12
9	5	5	Силовая тренировка	1	18:00:00	12
10	5	5	Функциональная тренировка	3	19:00:00	12
11	6	6	Силовая тренировка	1	18:00:00	12
12	6	6	Функциональная тренировка	3	19:00:00	12
13	7	7	Силовая тренировка	1	18:00:00	12
14	7	7	Функциональная тренировка	3	19:00:00	12
15	8	8	Силовая тренировка	1	18:00:00	12
16	8	8	Функциональная тренировка	3	19:00:00	12
17	9	9	Силовая тренировка	1	18:00:00	12
18	9	9	Функциональная тренировка	3	19:00:00	12
19	10	10	Силовая тренировка	1	18:00:00	12
20	10	10	Функциональная тренировка	3	19:00:00	12
21	11	11	Силовая тренировка	1	18:00:00	12
22	11	11	Функциональная тренировка	3	19:00:00	12
23	12	12	Силовая тренировка	1	18:00:00	12
24	12	12	Функциональная тренировка	3	19:00:00	12
25	13	13	Силовая тренировка	1	18:00:00	12
26	13	13	Функциональная тренировка	3	19:00:00	12
27	14	14	Силовая тренировка	1	18:00:00	12
28	14	14	Функциональная тренировка	3	19:00:00	12
29	15	15	Силовая тренировка	1	18:00:00	12
30	15	15	Функциональная тренировка	3	19:00:00	12
31	16	16	Силовая тренировка	1	18:00:00	12
32	16	16	Функциональная тренировка	3	19:00:00	12
33	17	17	Силовая тренировка	1	18:00:00	12
34	17	17	Функциональная тренировка	3	19:00:00	12
35	18	18	Силовая тренировка	1	18:00:00	12
36	18	18	Функциональная тренировка	3	19:00:00	12
37	19	19	Силовая тренировка	1	18:00:00	12
38	19	19	Функциональная тренировка	3	19:00:00	12
39	20	20	Силовая тренировка	1	18:00:00	12
40	20	20	Функциональная тренировка	3	19:00:00	12
41	21	21	Силовая тренировка	1	18:00:00	12
42	21	21	Функциональная тренировка	3	19:00:00	12
43	22	22	Силовая тренировка	1	18:00:00	12
44	22	22	Функциональная тренировка	3	19:00:00	12
45	23	23	Силовая тренировка	1	18:00:00	12
46	23	23	Функциональная тренировка	3	19:00:00	12
47	24	24	Силовая тренировка	1	18:00:00	12
48	24	24	Функциональная тренировка	3	19:00:00	12
49	25	25	Силовая тренировка	1	18:00:00	12
50	25	25	Функциональная тренировка	3	19:00:00	12
51	26	26	Силовая тренировка	1	18:00:00	12
52	26	26	Функциональная тренировка	3	19:00:00	12
53	27	27	Силовая тренировка	1	18:00:00	12
54	27	27	Функциональная тренировка	3	19:00:00	12
55	28	28	Силовая тренировка	1	18:00:00	12
56	28	28	Функциональная тренировка	3	19:00:00	12
57	29	29	Силовая тренировка	1	18:00:00	12
58	29	29	Функциональная тренировка	3	19:00:00	12
59	30	30	Силовая тренировка	1	18:00:00	12
60	30	30	Функциональная тренировка	3	19:00:00	12
61	31	31	Силовая тренировка	1	18:00:00	12
62	31	31	Функциональная тренировка	3	19:00:00	12
63	32	32	Силовая тренировка	1	18:00:00	12
64	32	32	Функциональная тренировка	3	19:00:00	12
65	33	33	Силовая тренировка	1	18:00:00	12
66	33	33	Функциональная тренировка	3	19:00:00	12
67	34	34	Силовая тренировка	1	18:00:00	12
68	34	34	Функциональная тренировка	3	19:00:00	12
69	35	35	Силовая тренировка	1	18:00:00	12
70	35	35	Функциональная тренировка	3	19:00:00	12
71	36	36	Силовая тренировка	1	18:00:00	12
72	36	36	Функциональная тренировка	3	19:00:00	12
73	37	37	Силовая тренировка	1	18:00:00	12
74	37	37	Функциональная тренировка	3	19:00:00	12
75	38	38	Силовая тренировка	1	18:00:00	12
76	38	38	Функциональная тренировка	3	19:00:00	12
77	39	39	Силовая тренировка	1	18:00:00	12
78	39	39	Функциональная тренировка	3	19:00:00	12
79	40	40	Силовая тренировка	1	18:00:00	12
80	40	40	Функциональная тренировка	3	19:00:00	12
81	41	41	Силовая тренировка	1	18:00:00	12
82	41	41	Функциональная тренировка	3	19:00:00	12
83	42	42	Силовая тренировка	1	18:00:00	12
84	42	42	Функциональная тренировка	3	19:00:00	12
85	43	43	Силовая тренировка	1	18:00:00	12
86	43	43	Функциональная тренировка	3	19:00:00	12
87	44	44	Силовая тренировка	1	18:00:00	12
88	44	44	Функциональная тренировка	3	19:00:00	12
89	45	45	Силовая тренировка	1	18:00:00	12
90	45	45	Функциональная тренировка	3	19:00:00	12
91	46	46	Силовая тренировка	1	18:00:00	12
92	46	46	Функциональная тренировка	3	19:00:00	12
93	47	47	Силовая тренировка	1	18:00:00	12
94	47	47	Функциональная тренировка	3	19:00:00	12
95	48	48	Силовая тренировка	1	18:00:00	12
96	48	48	Функциональная тренировка	3	19:00:00	12
97	49	49	Силовая тренировка	1	18:00:00	12
98	49	49	Функциональная тренировка	3	19:00:00	12
99	50	50	Силовая тренировка	1	18:00:00	12
100	50	50	Функциональная тренировка	3	19:00:00	12
101	51	51	Силовая тренировка	1	18:00:00	12
102	51	51	Функциональная тренировка	3	19:00:00	12
103	52	52	Силовая тренировка	1	18:00:00	12
104	52	52	Функциональная тренировка	3	19:00:00	12
105	53	53	Силовая тренировка	1	18:00:00	12
106	53	53	Функциональная тренировка	3	19:00:00	12
107	54	54	Силовая тренировка	1	18:00:00	12
108	54	54	Функциональная тренировка	3	19:00:00	12
109	55	55	Силовая тренировка	1	18:00:00	12
110	55	55	Функциональная тренировка	3	19:00:00	12
111	56	56	Силовая тренировка	1	18:00:00	12
112	56	56	Функциональная тренировка	3	19:00:00	12
113	57	57	Силовая тренировка	1	18:00:00	12
114	57	57	Функциональная тренировка	3	19:00:00	12
115	58	58	Силовая тренировка	1	18:00:00	12
116	58	58	Функциональная тренировка	3	19:00:00	12
117	59	59	Силовая тренировка	1	18:00:00	12
118	59	59	Функциональная тренировка	3	19:00:00	12
119	60	60	Силовая тренировка	1	18:00:00	12
120	60	60	Функциональная тренировка	3	19:00:00	12
121	61	61	Силовая тренировка	1	18:00:00	12
122	61	61	Функциональная тренировка	3	19:00:00	12
123	62	62	Силовая тренировка	1	18:00:00	12
124	62	62	Функциональная тренировка	3	19:00:00	12
125	63	63	Силовая тренировка	1	18:00:00	12
126	63	63	Функциональная тренировка	3	19:00:00	12
127	64	64	Силовая тренировка	1	18:00:00	12
128	64	64	Функциональная тренировка	3	19:00:00	12
129	65	65	Силовая тренировка	1	18:00:00	12
130	65	65	Функциональная тренировка	3	19:00:00	12
131	66	66	Силовая тренировка	1	18:00:00	12
132	66	66	Функциональная тренировка	3	19:00:00	12
133	67	67	Силовая тренировка	1	18:00:00	12
134	67	67	Функциональная тренировка	3	19:00:00	12
135	68	68	Силовая тренировка	1	18:00:00	12
136	68	68	Функциональная тренировка	3	19:00:00	12
137	69	69	Силовая тренировка	1	18:00:00	12
138	69	69	Функциональная тренировка	3	19:00:00	12
139	70	70	Силовая тренировка	1	18:00:00	12
140	70	70	Функциональная тренировка	3	19:00:00	12
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.clients (id, full_name, email, segment, is_demo) FROM stdin;
1	Учебный клиент 001	client001@example.test	student	t
2	Учебный клиент 002	client002@example.test	adult	t
3	Учебный клиент 003	client003@example.test	premium	t
4	Учебный клиент 004	client004@example.test	student	t
5	Учебный клиент 005	client005@example.test	adult	t
6	Учебный клиент 006	client006@example.test	premium	t
7	Учебный клиент 007	client007@example.test	student	t
8	Учебный клиент 008	client008@example.test	adult	t
9	Учебный клиент 009	client009@example.test	premium	t
10	Учебный клиент 010	client010@example.test	student	t
11	Учебный клиент 011	client011@example.test	adult	t
12	Учебный клиент 012	client012@example.test	premium	t
13	Учебный клиент 013	client013@example.test	student	t
14	Учебный клиент 014	client014@example.test	adult	t
15	Учебный клиент 015	client015@example.test	premium	t
16	Учебный клиент 016	client016@example.test	student	t
17	Учебный клиент 017	client017@example.test	adult	t
18	Учебный клиент 018	client018@example.test	premium	t
19	Учебный клиент 019	client019@example.test	student	t
20	Учебный клиент 020	client020@example.test	adult	t
21	Учебный клиент 021	client021@example.test	premium	t
22	Учебный клиент 022	client022@example.test	student	t
23	Учебный клиент 023	client023@example.test	adult	t
24	Учебный клиент 024	client024@example.test	premium	t
25	Учебный клиент 025	client025@example.test	student	t
26	Учебный клиент 026	client026@example.test	adult	t
27	Учебный клиент 027	client027@example.test	premium	t
28	Учебный клиент 028	client028@example.test	student	t
29	Учебный клиент 029	client029@example.test	adult	t
30	Учебный клиент 030	client030@example.test	premium	t
31	Учебный клиент 031	client031@example.test	student	t
32	Учебный клиент 032	client032@example.test	adult	t
33	Учебный клиент 033	client033@example.test	premium	t
34	Учебный клиент 034	client034@example.test	student	t
35	Учебный клиент 035	client035@example.test	adult	t
36	Учебный клиент 036	client036@example.test	premium	t
37	Учебный клиент 037	client037@example.test	student	t
38	Учебный клиент 038	client038@example.test	adult	t
39	Учебный клиент 039	client039@example.test	premium	t
40	Учебный клиент 040	client040@example.test	student	t
41	Учебный клиент 041	client041@example.test	adult	t
42	Учебный клиент 042	client042@example.test	premium	t
43	Учебный клиент 043	client043@example.test	student	t
44	Учебный клиент 044	client044@example.test	adult	t
45	Учебный клиент 045	client045@example.test	premium	t
46	Учебный клиент 046	client046@example.test	student	t
47	Учебный клиент 047	client047@example.test	adult	t
48	Учебный клиент 048	client048@example.test	premium	t
49	Учебный клиент 049	client049@example.test	student	t
50	Учебный клиент 050	client050@example.test	adult	t
51	Учебный клиент 051	client051@example.test	premium	t
52	Учебный клиент 052	client052@example.test	student	t
53	Учебный клиент 053	client053@example.test	adult	t
54	Учебный клиент 054	client054@example.test	premium	t
55	Учебный клиент 055	client055@example.test	student	t
56	Учебный клиент 056	client056@example.test	adult	t
57	Учебный клиент 057	client057@example.test	premium	t
58	Учебный клиент 058	client058@example.test	student	t
59	Учебный клиент 059	client059@example.test	adult	t
60	Учебный клиент 060	client060@example.test	premium	t
61	Учебный клиент 061	client061@example.test	student	t
62	Учебный клиент 062	client062@example.test	adult	t
63	Учебный клиент 063	client063@example.test	premium	t
64	Учебный клиент 064	client064@example.test	student	t
65	Учебный клиент 065	client065@example.test	adult	t
66	Учебный клиент 066	client066@example.test	premium	t
67	Учебный клиент 067	client067@example.test	student	t
68	Учебный клиент 068	client068@example.test	adult	t
69	Учебный клиент 069	client069@example.test	premium	t
70	Учебный клиент 070	client070@example.test	student	t
71	Учебный клиент 071	client071@example.test	adult	t
72	Учебный клиент 072	client072@example.test	premium	t
73	Учебный клиент 073	client073@example.test	student	t
74	Учебный клиент 074	client074@example.test	adult	t
75	Учебный клиент 075	client075@example.test	premium	t
76	Учебный клиент 076	client076@example.test	student	t
77	Учебный клиент 077	client077@example.test	adult	t
78	Учебный клиент 078	client078@example.test	premium	t
79	Учебный клиент 079	client079@example.test	student	t
80	Учебный клиент 080	client080@example.test	adult	t
81	Учебный клиент 081	client081@example.test	premium	t
82	Учебный клиент 082	client082@example.test	student	t
83	Учебный клиент 083	client083@example.test	adult	t
84	Учебный клиент 084	client084@example.test	premium	t
85	Учебный клиент 085	client085@example.test	student	t
86	Учебный клиент 086	client086@example.test	adult	t
87	Учебный клиент 087	client087@example.test	premium	t
88	Учебный клиент 088	client088@example.test	student	t
89	Учебный клиент 089	client089@example.test	adult	t
90	Учебный клиент 090	client090@example.test	premium	t
91	Учебный клиент 091	client091@example.test	student	t
92	Учебный клиент 092	client092@example.test	adult	t
93	Учебный клиент 093	client093@example.test	premium	t
94	Учебный клиент 094	client094@example.test	student	t
95	Учебный клиент 095	client095@example.test	adult	t
96	Учебный клиент 096	client096@example.test	premium	t
97	Учебный клиент 097	client097@example.test	student	t
98	Учебный клиент 098	client098@example.test	adult	t
99	Учебный клиент 099	client099@example.test	premium	t
100	Учебный клиент 100	client100@example.test	student	t
101	Учебный клиент 101	client101@example.test	adult	t
102	Учебный клиент 102	client102@example.test	premium	t
103	Учебный клиент 103	client103@example.test	student	t
104	Учебный клиент 104	client104@example.test	adult	t
105	Учебный клиент 105	client105@example.test	premium	t
106	Учебный клиент 106	client106@example.test	student	t
107	Учебный клиент 107	client107@example.test	adult	t
108	Учебный клиент 108	client108@example.test	premium	t
109	Учебный клиент 109	client109@example.test	student	t
110	Учебный клиент 110	client110@example.test	adult	t
111	Учебный клиент 111	client111@example.test	premium	t
112	Учебный клиент 112	client112@example.test	student	t
113	Учебный клиент 113	client113@example.test	adult	t
114	Учебный клиент 114	client114@example.test	premium	t
115	Учебный клиент 115	client115@example.test	student	t
116	Учебный клиент 116	client116@example.test	adult	t
117	Учебный клиент 117	client117@example.test	premium	t
118	Учебный клиент 118	client118@example.test	student	t
119	Учебный клиент 119	client119@example.test	adult	t
120	Учебный клиент 120	client120@example.test	premium	t
121	Учебный клиент 121	client121@example.test	student	t
122	Учебный клиент 122	client122@example.test	adult	t
123	Учебный клиент 123	client123@example.test	premium	t
124	Учебный клиент 124	client124@example.test	student	t
125	Учебный клиент 125	client125@example.test	adult	t
126	Учебный клиент 126	client126@example.test	premium	t
127	Учебный клиент 127	client127@example.test	student	t
128	Учебный клиент 128	client128@example.test	adult	t
129	Учебный клиент 129	client129@example.test	premium	t
130	Учебный клиент 130	client130@example.test	student	t
131	Учебный клиент 131	client131@example.test	adult	t
132	Учебный клиент 132	client132@example.test	premium	t
133	Учебный клиент 133	client133@example.test	student	t
134	Учебный клиент 134	client134@example.test	adult	t
135	Учебный клиент 135	client135@example.test	premium	t
136	Учебный клиент 136	client136@example.test	student	t
137	Учебный клиент 137	client137@example.test	adult	t
138	Учебный клиент 138	client138@example.test	premium	t
139	Учебный клиент 139	client139@example.test	student	t
140	Учебный клиент 140	client140@example.test	adult	t
141	Учебный клиент 141	client141@example.test	premium	t
142	Учебный клиент 142	client142@example.test	student	t
143	Учебный клиент 143	client143@example.test	adult	t
144	Учебный клиент 144	client144@example.test	premium	t
145	Учебный клиент 145	client145@example.test	student	t
146	Учебный клиент 146	client146@example.test	adult	t
147	Учебный клиент 147	client147@example.test	premium	t
148	Учебный клиент 148	client148@example.test	student	t
149	Учебный клиент 149	client149@example.test	adult	t
150	Учебный клиент 150	client150@example.test	premium	t
151	Учебный клиент 151	client151@example.test	student	t
152	Учебный клиент 152	client152@example.test	adult	t
153	Учебный клиент 153	client153@example.test	premium	t
154	Учебный клиент 154	client154@example.test	student	t
155	Учебный клиент 155	client155@example.test	adult	t
156	Учебный клиент 156	client156@example.test	premium	t
157	Учебный клиент 157	client157@example.test	student	t
158	Учебный клиент 158	client158@example.test	adult	t
159	Учебный клиент 159	client159@example.test	premium	t
160	Учебный клиент 160	client160@example.test	student	t
161	Учебный клиент 161	client161@example.test	adult	t
162	Учебный клиент 162	client162@example.test	premium	t
163	Учебный клиент 163	client163@example.test	student	t
164	Учебный клиент 164	client164@example.test	adult	t
165	Учебный клиент 165	client165@example.test	premium	t
166	Учебный клиент 166	client166@example.test	student	t
167	Учебный клиент 167	client167@example.test	adult	t
168	Учебный клиент 168	client168@example.test	premium	t
169	Учебный клиент 169	client169@example.test	student	t
170	Учебный клиент 170	client170@example.test	adult	t
171	Учебный клиент 171	client171@example.test	premium	t
172	Учебный клиент 172	client172@example.test	student	t
173	Учебный клиент 173	client173@example.test	adult	t
174	Учебный клиент 174	client174@example.test	premium	t
175	Учебный клиент 175	client175@example.test	student	t
176	Учебный клиент 176	client176@example.test	adult	t
177	Учебный клиент 177	client177@example.test	premium	t
178	Учебный клиент 178	client178@example.test	student	t
179	Учебный клиент 179	client179@example.test	adult	t
180	Учебный клиент 180	client180@example.test	premium	t
181	Учебный клиент 181	client181@example.test	student	t
182	Учебный клиент 182	client182@example.test	adult	t
183	Учебный клиент 183	client183@example.test	premium	t
184	Учебный клиент 184	client184@example.test	student	t
185	Учебный клиент 185	client185@example.test	adult	t
186	Учебный клиент 186	client186@example.test	premium	t
187	Учебный клиент 187	client187@example.test	student	t
188	Учебный клиент 188	client188@example.test	adult	t
189	Учебный клиент 189	client189@example.test	premium	t
190	Учебный клиент 190	client190@example.test	student	t
191	Учебный клиент 191	client191@example.test	adult	t
192	Учебный клиент 192	client192@example.test	premium	t
193	Учебный клиент 193	client193@example.test	student	t
194	Учебный клиент 194	client194@example.test	adult	t
195	Учебный клиент 195	client195@example.test	premium	t
196	Учебный клиент 196	client196@example.test	student	t
197	Учебный клиент 197	client197@example.test	adult	t
198	Учебный клиент 198	client198@example.test	premium	t
199	Учебный клиент 199	client199@example.test	student	t
200	Учебный клиент 200	client200@example.test	adult	t
201	Учебный клиент 201	client201@example.test	premium	t
202	Учебный клиент 202	client202@example.test	student	t
203	Учебный клиент 203	client203@example.test	adult	t
204	Учебный клиент 204	client204@example.test	premium	t
205	Учебный клиент 205	client205@example.test	student	t
206	Учебный клиент 206	client206@example.test	adult	t
207	Учебный клиент 207	client207@example.test	premium	t
208	Учебный клиент 208	client208@example.test	student	t
209	Учебный клиент 209	client209@example.test	adult	t
210	Учебный клиент 210	client210@example.test	premium	t
\.


--
-- Data for Name: gym_amenities; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.gym_amenities (gym_id, amenity_code, is_demo) FROM stdin;
1	cardio	t
1	group_classes	t
1	showers	t
1	weights	t
2	cardio	t
2	group_classes	t
2	showers	t
2	weights	t
3	cardio	t
3	group_classes	t
3	showers	t
3	weights	t
4	cardio	t
4	group_classes	t
4	showers	t
4	weights	t
5	cardio	t
5	group_classes	t
5	showers	t
5	weights	t
6	cardio	t
6	group_classes	t
6	showers	t
6	weights	t
7	cardio	t
7	group_classes	t
7	showers	t
7	weights	t
8	cardio	t
8	group_classes	t
8	showers	t
8	weights	t
9	cardio	t
9	group_classes	t
9	showers	t
9	weights	t
10	cardio	t
10	group_classes	t
10	showers	t
10	weights	t
11	cardio	t
11	group_classes	t
11	showers	t
11	weights	t
12	cardio	t
12	group_classes	t
12	showers	t
12	weights	t
13	cardio	t
13	group_classes	t
13	showers	t
13	weights	t
14	cardio	t
14	group_classes	t
14	showers	t
14	weights	t
15	cardio	t
15	group_classes	t
15	showers	t
15	weights	t
16	cardio	t
16	group_classes	t
16	showers	t
16	weights	t
17	cardio	t
17	group_classes	t
17	showers	t
17	weights	t
18	cardio	t
18	group_classes	t
18	showers	t
18	weights	t
19	cardio	t
19	group_classes	t
19	showers	t
19	weights	t
20	cardio	t
20	group_classes	t
20	showers	t
20	weights	t
21	cardio	t
21	group_classes	t
21	showers	t
21	weights	t
22	cardio	t
22	group_classes	t
22	showers	t
22	weights	t
23	cardio	t
23	group_classes	t
23	showers	t
23	weights	t
24	cardio	t
24	group_classes	t
24	showers	t
24	weights	t
25	cardio	t
25	group_classes	t
25	showers	t
25	weights	t
26	cardio	t
26	group_classes	t
26	showers	t
26	weights	t
27	cardio	t
27	group_classes	t
27	showers	t
27	weights	t
28	cardio	t
28	group_classes	t
28	showers	t
28	weights	t
29	cardio	t
29	group_classes	t
29	showers	t
29	weights	t
30	cardio	t
30	group_classes	t
30	showers	t
30	weights	t
31	cardio	t
31	group_classes	t
31	showers	t
31	weights	t
32	cardio	t
32	group_classes	t
32	showers	t
32	weights	t
33	cardio	t
33	group_classes	t
33	showers	t
33	weights	t
34	cardio	t
34	group_classes	t
34	showers	t
34	weights	t
35	cardio	t
35	group_classes	t
35	showers	t
35	weights	t
36	cardio	t
36	group_classes	t
36	showers	t
36	weights	t
37	cardio	t
37	group_classes	t
37	showers	t
37	weights	t
38	cardio	t
38	group_classes	t
38	showers	t
38	weights	t
39	cardio	t
39	group_classes	t
39	showers	t
39	weights	t
40	cardio	t
40	group_classes	t
40	showers	t
40	weights	t
41	cardio	t
41	group_classes	t
41	showers	t
41	weights	t
42	cardio	t
42	group_classes	t
42	showers	t
42	weights	t
43	cardio	t
43	group_classes	t
43	showers	t
43	weights	t
44	cardio	t
44	group_classes	t
44	showers	t
44	weights	t
45	cardio	t
45	group_classes	t
45	showers	t
45	weights	t
46	cardio	t
46	group_classes	t
46	showers	t
46	weights	t
47	cardio	t
47	group_classes	t
47	showers	t
47	weights	t
48	cardio	t
48	group_classes	t
48	showers	t
48	weights	t
49	cardio	t
49	group_classes	t
49	showers	t
49	weights	t
50	cardio	t
50	group_classes	t
50	showers	t
50	weights	t
51	cardio	t
51	group_classes	t
51	showers	t
51	weights	t
52	cardio	t
52	group_classes	t
52	showers	t
52	weights	t
53	cardio	t
53	group_classes	t
53	showers	t
53	weights	t
54	cardio	t
54	group_classes	t
54	showers	t
54	weights	t
55	cardio	t
55	group_classes	t
55	showers	t
55	weights	t
56	cardio	t
56	group_classes	t
56	showers	t
56	weights	t
57	cardio	t
57	group_classes	t
57	showers	t
57	weights	t
58	cardio	t
58	group_classes	t
58	showers	t
58	weights	t
59	cardio	t
59	group_classes	t
59	showers	t
59	weights	t
60	cardio	t
60	group_classes	t
60	showers	t
60	weights	t
61	cardio	t
61	group_classes	t
61	showers	t
61	weights	t
62	cardio	t
62	group_classes	t
62	showers	t
62	weights	t
63	cardio	t
63	group_classes	t
63	showers	t
63	weights	t
64	cardio	t
64	group_classes	t
64	showers	t
64	weights	t
65	cardio	t
65	group_classes	t
65	showers	t
65	weights	t
66	cardio	t
66	group_classes	t
66	showers	t
66	weights	t
67	cardio	t
67	group_classes	t
67	showers	t
67	weights	t
68	cardio	t
68	group_classes	t
68	showers	t
68	weights	t
69	cardio	t
69	group_classes	t
69	showers	t
69	weights	t
70	cardio	t
70	group_classes	t
70	showers	t
70	weights	t
\.


--
-- Data for Name: gyms; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.gyms (id, name, address, latitude, longitude, geo_accuracy_m, city_zone, price_band, source_url, source_checked_on) FROM stdin;
1	Gym Point	улица Кабдолова, 16	43.236295	76.851195	1000	west	standard	https://1fit.app/ru/almaty/studios/736-gym-point	2026-11-10
2	ProGym	улица Калдаякова, 17	43.261893	76.956685	1000	center	standard	https://1fit.app/ru/almaty/studios/1679-progym	2026-11-10
3	FitnessBlitz	улица Жолдасбекова, 9А	43.234845	76.955769	1000	center	standard	https://1fit.app/ru/almaty/studios/2916-fitnessblitz	2026-11-10
4	AYUMAN WORKOUT	Кульджинский тракт, 2Д	43.287227	76.990596	1000	north	standard	https://1fit.app/ru/almaty/studios/4631-ayuman-workout	2026-11-10
5	Velvet Sport Villa	микрорайон Ерменсай, 23	43.205846	76.927643	1000	south	premium	https://1fit.app/ru/almaty/studios/2044-velvet-sport-villa	2026-11-10
6	Aquastars на Навои	улица Алишера Навои, 208/6	43.205163	76.885458	1000	south	premium	https://1fit.app/ru/almaty/studios/3049-aquastars-%D0%BD%D0%B0-%D0%BD%D0%B0%D0%B2%D0%BE%D0%B8	2026-11-10
7	Underground big на Абая	проспект Абая, 150/230блок7	43.237733	76.884131	1000	center	standard	https://1fit.app/ru/almaty/studios/4953-underground-big-%D0%BD%D0%B0-%D0%B0%D0%B1%D0%B0%D1%8F	2026-11-10
8	ADRENALINE на Райымбека	проспект Райымбека, 348/1	43.255165	76.863670	1000	west	standard	https://1fit.app/ru/almaty/studios/5036-adrenaline-%D0%BD%D0%B0-%D1%80%D0%B0%D0%B9%D1%8B%D0%BC%D0%B1%D0%B5%D0%BA%D0%B0	2026-11-10
9	Aquastars на Яссауи	улица Яссауи, 1Б/2	43.200885	76.837846	1000	west	premium	https://1fit.app/ru/almaty/studios/1282-aquastars-%D0%BD%D0%B0-%D1%8F%D1%81%D1%81%D0%B0%D1%83%D0%B8	2026-11-10
10	Erbil Grand Hotel	улица Тлеуберды Сауранбаева, 5	43.336761	76.948699	1000	north	premium	https://1fit.app/ru/almaty/studios/1476-erbil-grand-hotel	2026-11-10
11	BOSSTANGYM	улица Маметовой, 67	43.267171	76.933527	1000	center	standard	https://1fit.app/ru/almaty/studios/1949-bosstangym	2026-11-10
12	King Fitness	микрорайон Шугыла	43.211068	76.794375	1000	west	budget	https://1fit.app/ru/almaty/studios/3951-king-fitness	2026-11-10
13	Тренажерный зал IRONHOUSE.KZ	улица Шевченко, 100	43.245175	76.933194	1000	center	standard	https://1fit.app/ru/almaty/studios/3861-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-ironhousekz	2026-11-10
14	Brooklyn Fitness Gym	мкр-н Керемет, 7к42, цокольный этаж	43.236162	76.938142	1000	center	standard	https://1fit.app/ru/almaty/studios/68-brooklyn-fitness-gym	2026-11-10
15	FitnessBlitz Аксай	микрорайон Аксай-5, 3	43.229550	76.833167	1000	west	standard	https://1fit.app/ru/almaty/studios/3359-fitnessblitz-%D0%B0%D0%BA%D1%81%D0%B0%D0%B9	2026-11-10
36	Titan Arms	улица Жунисова, 2/23к7	43.224672	76.781702	1000	west	budget	https://1fit.app/ru/almaty/studios/4475-titan-arms	2026-11-10
37	Avantgarde Навои	улица Алишера Навои, 7	43.218749	76.879970	1000	south	standard	https://1fit.app/ru/almaty/studios/2920-avantgarde-%D0%BD%D0%B0%D0%B2%D0%BE%D0%B8	2026-11-10
38	Hard Gym	улица Абая, 90А	43.219200	76.900000	8000	south	budget	https://1fit.app/ru/almaty/studios/4968-hard-gym	2026-11-10
69	Invictus GO Fifty Four	улица Маметовой, 54	43.266526	76.935716	1000	center	budget	https://invictus.kz/ru-kz/clubs/go/go-fifty-four	2026-11-10
16	QFitness	площадь Республики, 15	43.238772	76.943561	1000	center	premium	https://1fit.app/ru/almaty/studios/754-qfitness	2026-11-10
17	Continental swimming club	проспект Сакена Сейфуллина, 404	43.267853	76.931504	1000	center	premium	https://1fit.app/ru/almaty/studios/1480-continental-swimming-club	2026-11-10
18	100% Fitness Gym на Байзакова	улица Байзакова, 280	43.237248	76.915066	1000	center	standard	https://1fit.app/ru/almaty/studios/4893-100-fitness-gym-%D0%BD%D0%B0-%D0%B1%D0%B0%D0%B9%D0%B7%D0%B0%D0%BA%D0%BE%D0%B2%D0%B0	2026-11-10
19	SK Boxing на Тимирязева	ЖК Импорио, ул. Тимирязева, 111а, 1-й этаж	43.225806	76.890214	1000	center	standard	https://1fit.app/ru/almaty/studios/1263-sk-boxing-%D0%BD%D0%B0-%D1%82%D0%B8%D0%BC%D0%B8%D1%80%D1%8F%D0%B7%D0%B5%D0%B2%D0%B0	2026-11-10
20	Namys SK	ул. Титова, 6а	43.413644	77.016458	1000	north	standard	https://1fit.app/ru/almaty/studios/670-namys-sk	2026-11-10
21	Фитнес-клуб "Тастак"	улица Толе би, 249	43.250474	76.874431	1000	center	standard	https://1fit.app/ru/almaty/studios/5208-%D1%84%D0%B8%D1%82%D0%BD%D0%B5%D1%81-%D0%BA%D0%BB%D1%83%D0%B1-%D1%82%D0%B0%D1%81%D1%82%D0%B0%D0%BA	2026-11-10
22	First Fitness Таугуль	микрорайон Таугуль-1, 22/1	43.213792	76.878593	1000	south	standard	https://1fit.app/ru/almaty/studios/48-first-fitness	2026-11-10
23	King Fitness Кайрат	микрорайон Кайрат, 182	43.302327	77.005437	1000	north	budget	https://1fit.app/ru/almaty/studios/5426-king-fitness-%D0%BA%D0%B0%D0%B9%D1%80%D0%B0%D1%82	2026-11-10
24	FitNova	улица Акан Серы, 138	43.312312	76.944675	1000	north	standard	https://1fit.app/ru/almaty/studios/5399-fitnova	2026-11-10
25	Baqgym	улица Яссауи, 66	43.224467	76.828512	1000	west	budget	https://1fit.app/ru/almaty/studios/5367-baqgym	2026-11-10
26	Fitness Life Center	улица Жандарбекова, 238	43.225754	76.900163	1000	center	standard	https://1fit.app/ru/almaty/studios/1754-fitness-life-center	2026-11-10
27	FitnessBlitz Искра	проспект Сакена Сейфуллина, 533	43.255176	76.932188	1000	center	standard	https://1fit.app/ru/almaty/studios/3358-fitnessblitz-%D0%B8%D1%81%D0%BA%D1%80%D0%B0	2026-11-10
28	Urban Gym	проспект Назарбаева, 223	43.232283	76.948546	1000	center	premium	https://1fit.app/ru/almaty/studios/36-urban-gym	2026-11-10
29	Xan Gym	микрорайон Самал-1, 10	43.235991	76.956369	1000	center	standard	https://1fit.app/ru/almaty/studios/4396-xan-gym	2026-11-10
30	Тренажерный зал "HERMES"	микрорайон Айнабулак-3, 129	43.325835	76.923560	1000	north	standard	https://1fit.app/ru/almaty/studios/2203-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-hermes	2026-11-10
31	Arena fitness hub	микрорайон Нуркент, 7	43.264144	76.817031	1000	west	standard	https://1fit.app/ru/almaty/studios/829-arena-fitness-hub	2026-11-10
32	First Fitness Коктем	бульвар Бухар Жырау, 26/1	43.232189	76.923142	1000	center	standard	https://1fit.app/ru/almaty/studios/5057-first-fitness-%D0%BA%D0%BE%D0%BA%D1%82%D0%B5%D0%BC	2026-11-10
33	BAZA sport club	микрорайон Кайрат, 181-182к2	43.300057	77.002077	1000	north	standard	https://1fit.app/ru/almaty/studios/4877-baza-sport-club	2026-11-10
34	Asyl Gym	улица Айтжана Туркебаева, 92	43.249884	76.878954	1000	center	budget	https://1fit.app/ru/almaty/studios/1696-asyl-gym	2026-11-10
35	ProFitnessAMG	улица Манаса, 51	43.236742	76.908627	1000	center	standard	https://1fit.app/ru/almaty/studios/26-profitnessamg	2026-11-10
39	"Берлога" тренажерный зал	Толе би, 189д, 2 этаж,	43.252156	76.891041	1000	center	standard	https://1fit.app/ru/almaty/studios/878-%D0%B1%D0%B5%D1%80%D0%BB%D0%BE%D0%B3%D0%B0-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB	2026-11-10
40	ТехноGym тренажерный зал	проспект Райымбека, 221ж	43.272317	76.917743	1000	center	budget	https://1fit.app/ru/almaty/studios/1455-%D1%82%D0%B5%D1%85%D0%BD%D0%BEgym-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB	2026-11-10
41	ADRENALINE на Арбате	проспект Жибек Жолы, 66	43.262096	76.949957	1000	center	standard	https://1fit.app/ru/almaty/studios/1229-adrenaline-%D0%BD%D0%B0-%D0%B0%D1%80%D0%B1%D0%B0%D1%82%D0%B5	2026-11-10
42	ANGEL GYM	улица Саина, 20Б	43.237355	76.842579	1000	west	budget	https://1fit.app/ru/almaty/studios/46-angel-gym	2026-11-10
43	Академия ЦСКА на Райымбека	проспект Райымбека, 212А/5	43.257356	76.891342	1000	center	standard	https://1fit.app/ru/almaty/studios/2451-%D0%B0%D0%BA%D0%B0%D0%B4%D0%B5%D0%BC%D0%B8%D1%8F-%D1%86%D1%81%D0%BA%D0%B0-%D0%BD%D0%B0-%D1%80%D0%B0%D0%B9%D1%8B%D0%BC%D0%B1%D0%B5%D0%BA%D0%B0	2026-11-10
44	Gryphon Fitness	улица Мукагали Макатаева, 1	43.265917	76.967052	1000	center	standard	https://1fit.app/ru/almaty/studios/3803-gryphon-fitness	2026-11-10
45	7GYM Fitness club ЖК Премьера	улица Жуалы, 155	43.221930	76.795734	1000	west	standard	https://1fit.app/ru/almaty/studios/5429-7gym-fitness-club-%D0%B6%D0%BA-%D0%BF%D1%80%D0%B5%D0%BC%D1%8C%D0%B5%D1%80%D0%B0	2026-11-10
46	Orda	улица Д. Кунаева, 169	43.256200	76.946300	8000	center	standard	https://1fit.app/ru/almaty/studios/2312-orda	2026-11-10
47	НурФитнесс	улица Амангельды, 2	43.302550	77.056964	1000	north	budget	https://1fit.app/ru/almaty/studios/2489-%D0%BD%D1%83%D1%80%D1%84%D0%B8%D1%82%D0%BD%D0%B5%D1%81%D1%81	2026-11-10
48	Тренажерный зал “AQONGYM”	микрорайон Жетысу-2, 11/1	43.225872	76.843866	1000	west	budget	https://1fit.app/ru/almaty/studios/2567-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-aqongym	2026-11-10
49	HARDWAY ЖК Теремки	проспект Сакена Сейфуллина, 51/6	43.328591	76.940605	1000	north	standard	https://1fit.app/ru/almaty/studios/2102-hardway-%D0%B6%D0%BA-%D1%82%D0%B5%D1%80%D0%B5%D0%BC%D0%BA%D0%B8	2026-11-10
50	Зал "Крепкий Орех" на Жамбыла	улица Жамбыла, 9А	43.248600	76.914900	8000	center	standard	https://1fit.app/ru/almaty/studios/5368-%D0%B7%D0%B0%D0%BB-%D0%BA%D1%80%D0%B5%D0%BF%D0%BA%D0%B8%D0%B9-%D0%BE%D1%80%D0%B5%D1%85-%D0%BD%D0%B0-%D0%B6%D0%B0%D0%BC%D0%B1%D1%8B%D0%BB%D0%B0	2026-11-10
51	Тренажерный зал “AQONGYM AIR”	улица Федосеева, 38В	43.317668	76.973496	1000	north	budget	https://1fit.app/ru/almaty/studios/4922-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-aqongym-air	2026-11-10
52	Специализированный учебный центр "Меркурий Медет"	ул. Коперника, 130	43.267643	76.969998	1000	center	standard	https://1fit.app/ru/almaty/studios/1159-%D1%81%D0%BF%D0%B5%D1%86%D0%B8%D0%B0%D0%BB%D0%B8%D0%B7%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%BD%D1%8B%D0%B9-%D1%83%D1%87%D0%B5%D0%B1%D0%BD%D1%8B%D0%B9-%D1%86%D0%B5%D0%BD%D1%82%D1%80-%D0%BC%D0%B5%D1%80%D0%BA%D1%83%D1%80%D0%B8%D0%B9-%D0%BC%D0%B5%D0%B4%D0%B5%D1%82	2026-11-10
53	BOSS FITNESS	13-й Военный городок, 21Б	43.376386	76.991477	1000	north	budget	https://1fit.app/ru/almaty/studios/724-boss-fitness	2026-11-10
54	Legion Fitness	проспект Турара Рыскулова, 103/3	43.267079	76.869378	1000	west	standard	https://1fit.app/ru/almaty/studios/106-legion-fitness	2026-11-10
55	NAUTILUS тренажерный зал Навои	улица Алишера Навои, 208/6	43.205163	76.885458	1000	south	standard	https://1fit.app/ru/almaty/studios/719-nautilus-%D1%82%D1%80%D0%B5%D0%BD%D0%B0%D0%B6%D0%B5%D1%80%D0%BD%D1%8B%D0%B9-%D0%B7%D0%B0%D0%BB-%D0%BD%D0%B0%D0%B2%D0%BE%D0%B8	2026-11-10
56	Ant Gym	улица Едила Ергожина, 4/3	43.208588	76.912135	1000	south	budget	https://1fit.app/ru/almaty/studios/4472-ant-gym	2026-11-10
57	777 Fight Club & Gym	улица Курмангазы, 97	43.244184	76.931460	1000	center	standard	https://1fit.app/ru/almaty/studios/1772-777-fight-club-gym	2026-11-10
58	Gepard Sport Club	улица Утеген Батыра, 11А	43.244120	76.855805	1000	west	budget	https://1fit.app/ru/almaty/studios/672-gepard-sport-club	2026-11-10
59	ProGym 3	улица Карасай батыра, 88Б	43.249811	76.926951	1000	center	standard	https://1fit.app/ru/almaty/studios/3424-progym-3	2026-11-10
60	ADRENALINE на Достык	проспект Достык, 250	43.221727	76.963647	1000	south	standard	https://1fit.app/ru/almaty/studios/1230-adrenaline-%D0%BD%D0%B0-%D0%B4%D0%BE%D1%81%D1%82%D1%8B%D0%BA	2026-11-10
61	Invictus GO Abay	проспект Абая, 165	43.239780	76.884028	1000	center	budget	https://invictus.kz/ru-kz/clubs/go/go-abay	2026-11-10
62	Invictus GO Aport East	Кульджинский тракт, 106	43.314039	77.025323	1000	north	budget	https://invictus.kz/ru-kz/clubs/go/go-aport-east	2026-11-10
63	Invictus GO Aqsay	микрорайон Аксай-5, 25	43.232391	76.831656	1000	west	budget	https://invictus.kz/ru-kz/clubs/go/go-aqsay	2026-11-10
64	Invictus GO Arena	микрорайон Гажайып, 11/1 блок 6	43.275713	76.816256	1000	west	budget	https://invictus.kz/ru-kz/clubs/go/go-arena	2026-11-10
65	Invictus GO Askarova	улица Аскарова, 4/3	43.199714	76.868029	1000	west	budget	https://invictus.kz/ru-kz/clubs/go/go-askarova	2026-11-10
66	Invictus GO Atakent	улица Тимирязева, 42	43.224835	76.910851	1000	south	budget	https://invictus.kz/ru-kz/clubs/go/go-atakent	2026-11-10
67	Invictus GO Baitursynov	улица Байтурсынова, 179 блок 2	43.231028	76.934520	1000	center	budget	https://invictus.kz/ru-kz/clubs/go/go-baitursynov	2026-11-10
68	Invictus Girls Crystal	проспект Абая, 160 корпус 3	43.236715	76.881630	1000	center	premium	https://invictus.kz/ru-kz/clubs/girls/girls-crystal	2026-11-10
70	Invictus Fitness Gagarin	проспект Гагарина, 286	43.205254	76.899298	1000	south	premium	https://invictus.kz/ru-kz/clubs/fitness/fitness-gagarin	2026-11-10
\.


--
-- Data for Name: memberships; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.memberships (id, client_id, plan_id, starts_on, ends_on, status, price_paid_kzt) FROM stdin;
1	1	1	2026-11-09	2026-12-09	active	20000
2	2	2	2026-11-09	2026-12-09	active	25500
3	3	3	2026-11-09	2026-12-09	active	38000
4	4	4	2026-11-09	2026-12-09	active	21500
5	5	5	2026-11-09	2026-12-09	active	27000
6	6	6	2026-11-09	2026-12-09	active	41000
7	7	7	2026-11-09	2026-12-09	active	22500
8	8	8	2026-11-09	2026-12-09	active	28500
9	9	9	2026-11-09	2026-12-09	active	43000
10	10	10	2026-11-09	2026-12-09	active	24000
11	11	11	2026-11-09	2026-12-09	active	30000
12	12	12	2026-11-09	2026-12-09	active	45000
13	13	13	2026-11-09	2026-12-09	active	32000
14	14	14	2026-11-09	2026-12-09	active	40000
15	15	15	2026-11-09	2026-12-09	active	60000
16	16	16	2026-11-09	2026-12-09	active	34000
17	17	17	2026-11-09	2026-12-09	active	43000
18	18	18	2026-11-09	2026-12-09	active	65000
19	19	19	2026-11-09	2026-12-09	active	21500
20	20	20	2026-11-09	2026-12-09	active	27000
21	21	21	2026-11-09	2026-12-09	active	41000
22	22	22	2026-11-09	2026-12-09	active	22500
23	23	23	2026-11-09	2026-12-09	active	28500
24	24	24	2026-11-09	2026-12-09	active	43000
25	25	25	2026-11-09	2026-12-09	active	41500
26	26	26	2026-11-09	2026-12-09	active	52000
27	27	27	2026-11-09	2026-12-09	active	78000
28	28	28	2026-11-09	2026-12-09	active	32000
29	29	29	2026-11-09	2026-12-09	active	40000
30	30	30	2026-11-09	2026-12-09	active	60000
31	31	31	2026-11-09	2026-12-09	active	20000
32	32	32	2026-11-09	2026-12-09	active	25500
33	33	33	2026-11-09	2026-12-09	active	38000
34	34	34	2026-11-09	2026-12-09	active	12000
35	35	35	2026-11-09	2026-12-09	active	15000
36	36	36	2026-11-09	2026-12-09	active	23000
37	37	37	2026-11-09	2026-12-09	active	22500
38	38	38	2026-11-09	2026-12-09	active	28500
39	39	39	2026-11-09	2026-12-09	active	43000
40	40	40	2026-11-09	2026-12-09	active	24000
41	41	41	2026-11-09	2026-12-09	active	30000
42	42	42	2026-11-09	2026-12-09	active	45000
43	43	43	2026-11-09	2026-12-09	active	19000
44	44	44	2026-11-09	2026-12-09	active	24000
45	45	45	2026-11-09	2026-12-09	active	36000
46	46	46	2026-11-09	2026-12-09	active	34000
47	47	47	2026-11-09	2026-12-09	active	43000
48	48	48	2026-11-09	2026-12-09	active	65000
49	49	49	2026-11-09	2026-12-09	active	36500
50	50	50	2026-11-09	2026-12-09	active	46000
51	51	51	2026-11-09	2026-12-09	active	69000
52	52	52	2026-11-09	2026-12-09	active	22500
53	53	53	2026-11-09	2026-12-09	active	28500
54	54	54	2026-11-09	2026-12-09	active	43000
55	55	55	2026-11-09	2026-12-09	active	24000
56	56	56	2026-11-09	2026-12-09	active	30000
57	57	57	2026-11-09	2026-12-09	active	45000
58	58	58	2026-11-09	2026-12-09	active	19000
59	59	59	2026-11-09	2026-12-09	active	24000
60	60	60	2026-11-09	2026-12-09	active	36000
61	61	61	2026-11-09	2026-12-09	active	24500
62	62	62	2026-11-09	2026-12-09	active	31000
63	63	63	2026-11-09	2026-12-09	active	46000
64	64	64	2026-11-09	2026-12-09	active	20000
65	65	65	2026-11-09	2026-12-09	active	26000
66	66	66	2026-11-09	2026-12-09	active	39000
67	67	67	2026-11-09	2026-12-09	active	14000
68	68	68	2026-11-09	2026-12-09	active	18000
69	69	69	2026-11-09	2026-12-09	active	27000
70	70	70	2026-11-09	2026-12-09	active	24000
71	71	71	2026-11-09	2026-12-09	active	30000
72	72	72	2026-11-09	2026-12-09	active	45000
73	73	73	2026-11-09	2026-12-09	active	12500
74	74	74	2026-11-09	2026-12-09	active	16000
75	75	75	2026-11-09	2026-12-09	active	24000
76	76	76	2026-11-09	2026-12-09	active	20000
77	77	77	2026-11-09	2026-12-09	active	25500
78	78	78	2026-11-09	2026-12-09	active	38000
79	79	79	2026-11-09	2026-12-09	active	21500
80	80	80	2026-11-09	2026-12-09	active	27000
81	81	81	2026-11-09	2026-12-09	active	41000
82	82	82	2026-11-09	2026-12-09	active	39000
83	83	83	2026-11-09	2026-12-09	active	49000
84	84	84	2026-11-09	2026-12-09	active	74000
85	85	85	2026-11-09	2026-12-09	active	24000
86	86	86	2026-11-09	2026-12-09	active	30000
87	87	87	2026-11-09	2026-12-09	active	45000
88	88	88	2026-11-09	2026-12-09	active	19000
89	89	89	2026-11-09	2026-12-09	active	24000
90	90	90	2026-11-09	2026-12-09	active	36000
91	91	91	2026-11-09	2026-12-09	active	20000
92	92	92	2026-11-09	2026-12-09	active	25500
93	93	93	2026-11-09	2026-12-09	active	38000
94	94	94	2026-11-09	2026-12-09	active	21500
95	95	95	2026-11-09	2026-12-09	active	27000
96	96	96	2026-11-09	2026-12-09	active	41000
97	97	97	2026-11-09	2026-12-09	active	22500
98	98	98	2026-11-09	2026-12-09	active	28500
99	99	99	2026-11-09	2026-12-09	active	43000
100	100	100	2026-11-09	2026-12-09	active	13500
101	101	101	2026-11-09	2026-12-09	active	17000
102	102	102	2026-11-09	2026-12-09	active	26000
103	103	103	2026-11-09	2026-12-09	active	19000
104	104	104	2026-11-09	2026-12-09	active	24000
105	105	105	2026-11-09	2026-12-09	active	36000
106	106	106	2026-11-09	2026-12-09	active	12000
107	107	107	2026-11-09	2026-12-09	active	15000
108	108	108	2026-11-09	2026-12-09	active	23000
109	109	109	2026-11-09	2026-12-09	active	21500
110	110	110	2026-11-09	2026-12-09	active	27000
111	111	111	2026-11-09	2026-12-09	active	41000
112	112	112	2026-11-09	2026-12-09	active	13500
113	113	113	2026-11-09	2026-12-09	active	17000
114	114	114	2026-11-09	2026-12-09	active	26000
115	115	115	2026-11-09	2026-12-09	active	24000
116	116	116	2026-11-09	2026-12-09	active	30000
117	117	117	2026-11-09	2026-12-09	active	45000
118	118	118	2026-11-09	2026-12-09	active	12000
119	119	119	2026-11-09	2026-12-09	active	15000
120	120	120	2026-11-09	2026-12-09	active	23000
121	121	121	2026-11-09	2026-12-09	active	20000
122	122	122	2026-11-09	2026-12-09	active	25500
123	123	123	2026-11-09	2026-12-09	active	38000
124	124	124	2026-11-09	2026-12-09	active	13500
125	125	125	2026-11-09	2026-12-09	active	17000
126	126	126	2026-11-09	2026-12-09	active	26000
127	127	127	2026-11-09	2026-12-09	active	22500
128	128	128	2026-11-09	2026-12-09	active	28500
129	129	129	2026-11-09	2026-12-09	active	43000
130	130	130	2026-11-09	2026-12-09	active	24000
131	131	131	2026-11-09	2026-12-09	active	30000
132	132	132	2026-11-09	2026-12-09	active	45000
133	133	133	2026-11-09	2026-12-09	active	19000
134	134	134	2026-11-09	2026-12-09	active	24000
135	135	135	2026-11-09	2026-12-09	active	36000
136	136	136	2026-11-09	2026-12-09	active	20000
137	137	137	2026-11-09	2026-12-09	active	25500
138	138	138	2026-11-09	2026-12-09	active	38000
139	139	139	2026-11-09	2026-12-09	active	14000
140	140	140	2026-11-09	2026-12-09	active	18000
141	141	141	2026-11-09	2026-12-09	active	27000
142	142	142	2026-11-09	2026-12-09	active	12000
143	143	143	2026-11-09	2026-12-09	active	15000
144	144	144	2026-11-09	2026-12-09	active	23000
145	145	145	2026-11-09	2026-12-09	active	24000
146	146	146	2026-11-09	2026-12-09	active	30000
147	147	147	2026-11-09	2026-12-09	active	45000
148	148	148	2026-11-09	2026-12-09	active	19000
149	149	149	2026-11-09	2026-12-09	active	24000
150	150	150	2026-11-09	2026-12-09	active	36000
151	151	151	2026-11-09	2026-12-09	active	14000
152	152	152	2026-11-09	2026-12-09	active	18000
153	153	153	2026-11-09	2026-12-09	active	27000
154	154	154	2026-11-09	2026-12-09	active	21500
155	155	155	2026-11-09	2026-12-09	active	27000
156	156	156	2026-11-09	2026-12-09	active	41000
157	157	157	2026-11-09	2026-12-09	active	12500
158	158	158	2026-11-09	2026-12-09	active	16000
159	159	159	2026-11-09	2026-12-09	active	24000
160	160	160	2026-11-09	2026-12-09	active	24000
161	161	161	2026-11-09	2026-12-09	active	30000
162	162	162	2026-11-09	2026-12-09	active	45000
163	163	163	2026-11-09	2026-12-09	active	19000
164	164	164	2026-11-09	2026-12-09	active	24000
165	165	165	2026-11-09	2026-12-09	active	36000
166	166	166	2026-11-09	2026-12-09	active	12000
167	167	167	2026-11-09	2026-12-09	active	15000
168	168	168	2026-11-09	2026-12-09	active	23000
169	169	169	2026-11-09	2026-12-09	active	21500
170	170	170	2026-11-09	2026-12-09	active	27000
171	171	171	2026-11-09	2026-12-09	active	41000
172	172	172	2026-11-09	2026-12-09	active	13500
173	173	173	2026-11-09	2026-12-09	active	17000
174	174	174	2026-11-09	2026-12-09	active	26000
175	175	175	2026-11-09	2026-12-09	active	24000
176	176	176	2026-11-09	2026-12-09	active	30000
177	177	177	2026-11-09	2026-12-09	active	45000
178	178	178	2026-11-09	2026-12-09	active	19000
179	179	179	2026-11-09	2026-12-09	active	24000
180	180	180	2026-11-09	2026-12-09	active	36000
181	181	181	2026-11-09	2026-12-09	active	12500
182	182	182	2026-11-09	2026-12-09	active	16000
183	183	183	2026-11-09	2026-12-09	active	24000
184	184	184	2026-11-09	2026-12-09	active	13500
185	185	185	2026-11-09	2026-12-09	active	17000
186	186	186	2026-11-09	2026-12-09	active	26000
187	187	187	2026-11-09	2026-12-09	active	14000
188	188	188	2026-11-09	2026-12-09	active	18000
189	189	189	2026-11-09	2026-12-09	active	27000
190	190	190	2026-11-09	2026-12-09	active	12000
191	191	191	2026-11-09	2026-12-09	active	15000
192	192	192	2026-11-09	2026-12-09	active	23000
193	193	193	2026-11-09	2026-12-09	active	12500
194	194	194	2026-11-09	2026-12-09	active	16000
195	195	195	2026-11-09	2026-12-09	active	24000
196	196	196	2026-11-09	2026-12-09	active	13500
197	197	197	2026-11-09	2026-12-09	active	17000
198	198	198	2026-11-09	2026-12-09	active	26000
199	199	199	2026-11-09	2026-12-09	active	14000
200	200	200	2026-11-09	2026-12-09	active	18000
201	201	201	2026-11-09	2026-12-09	active	27000
202	202	202	2026-11-09	2026-12-09	active	39000
203	203	203	2026-11-09	2026-12-09	active	49000
204	204	204	2026-11-09	2026-12-09	active	74000
205	205	205	2026-11-09	2026-12-09	active	12500
206	206	206	2026-11-09	2026-12-09	active	16000
207	207	207	2026-11-09	2026-12-09	active	24000
208	208	208	2026-11-09	2026-12-09	active	32000
209	209	209	2026-11-09	2026-12-09	active	40000
210	210	210	2026-11-09	2026-12-09	active	60000
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.payments (id, membership_id, amount_kzt, method, status, paid_at) FROM stdin;
1	1	20000	card	paid	2026-11-09 09:00:00+05
2	2	25500	cash	paid	2026-11-09 09:00:00+05
3	3	38000	kaspi	paid	2026-11-09 09:00:00+05
4	4	21500	card	paid	2026-11-09 09:00:00+05
5	5	27000	cash	paid	2026-11-09 09:00:00+05
6	6	41000	kaspi	paid	2026-11-09 09:00:00+05
7	7	22500	card	paid	2026-11-09 09:00:00+05
8	8	28500	cash	paid	2026-11-09 09:00:00+05
9	9	43000	kaspi	paid	2026-11-09 09:00:00+05
10	10	24000	card	paid	2026-11-09 09:00:00+05
11	11	30000	cash	paid	2026-11-09 09:00:00+05
12	12	45000	kaspi	paid	2026-11-09 09:00:00+05
13	13	32000	card	paid	2026-11-09 09:00:00+05
14	14	40000	cash	paid	2026-11-09 09:00:00+05
15	15	60000	kaspi	paid	2026-11-09 09:00:00+05
16	16	34000	card	paid	2026-11-09 09:00:00+05
17	17	43000	cash	paid	2026-11-09 09:00:00+05
18	18	65000	kaspi	paid	2026-11-09 09:00:00+05
19	19	21500	card	paid	2026-11-09 09:00:00+05
20	20	27000	cash	paid	2026-11-09 09:00:00+05
21	21	41000	kaspi	paid	2026-11-09 09:00:00+05
22	22	22500	card	paid	2026-11-09 09:00:00+05
23	23	28500	cash	paid	2026-11-09 09:00:00+05
24	24	43000	kaspi	paid	2026-11-09 09:00:00+05
25	25	41500	card	paid	2026-11-09 09:00:00+05
26	26	52000	cash	paid	2026-11-09 09:00:00+05
27	27	78000	kaspi	paid	2026-11-09 09:00:00+05
28	28	32000	card	paid	2026-11-09 09:00:00+05
29	29	40000	cash	paid	2026-11-09 09:00:00+05
30	30	60000	kaspi	paid	2026-11-09 09:00:00+05
31	31	20000	card	paid	2026-11-09 09:00:00+05
32	32	25500	cash	paid	2026-11-09 09:00:00+05
33	33	38000	kaspi	paid	2026-11-09 09:00:00+05
34	34	12000	card	paid	2026-11-09 09:00:00+05
35	35	15000	cash	paid	2026-11-09 09:00:00+05
36	36	23000	kaspi	paid	2026-11-09 09:00:00+05
37	37	22500	card	paid	2026-11-09 09:00:00+05
38	38	28500	cash	paid	2026-11-09 09:00:00+05
39	39	43000	kaspi	paid	2026-11-09 09:00:00+05
40	40	24000	card	paid	2026-11-09 09:00:00+05
41	41	30000	cash	paid	2026-11-09 09:00:00+05
42	42	45000	kaspi	paid	2026-11-09 09:00:00+05
43	43	19000	card	paid	2026-11-09 09:00:00+05
44	44	24000	cash	paid	2026-11-09 09:00:00+05
45	45	36000	kaspi	paid	2026-11-09 09:00:00+05
46	46	34000	card	paid	2026-11-09 09:00:00+05
47	47	43000	cash	paid	2026-11-09 09:00:00+05
48	48	65000	kaspi	paid	2026-11-09 09:00:00+05
49	49	36500	card	paid	2026-11-09 09:00:00+05
50	50	46000	cash	paid	2026-11-09 09:00:00+05
51	51	69000	kaspi	paid	2026-11-09 09:00:00+05
52	52	22500	card	paid	2026-11-09 09:00:00+05
53	53	28500	cash	paid	2026-11-09 09:00:00+05
54	54	43000	kaspi	paid	2026-11-09 09:00:00+05
55	55	24000	card	paid	2026-11-09 09:00:00+05
56	56	30000	cash	paid	2026-11-09 09:00:00+05
57	57	45000	kaspi	paid	2026-11-09 09:00:00+05
58	58	19000	card	paid	2026-11-09 09:00:00+05
59	59	24000	cash	paid	2026-11-09 09:00:00+05
60	60	36000	kaspi	paid	2026-11-09 09:00:00+05
61	61	24500	card	paid	2026-11-09 09:00:00+05
62	62	31000	cash	paid	2026-11-09 09:00:00+05
63	63	46000	kaspi	paid	2026-11-09 09:00:00+05
64	64	20000	card	paid	2026-11-09 09:00:00+05
65	65	26000	cash	paid	2026-11-09 09:00:00+05
66	66	39000	kaspi	paid	2026-11-09 09:00:00+05
67	67	14000	card	paid	2026-11-09 09:00:00+05
68	68	18000	cash	paid	2026-11-09 09:00:00+05
69	69	27000	kaspi	paid	2026-11-09 09:00:00+05
70	70	24000	card	paid	2026-11-09 09:00:00+05
71	71	30000	cash	paid	2026-11-09 09:00:00+05
72	72	45000	kaspi	paid	2026-11-09 09:00:00+05
73	73	12500	card	paid	2026-11-09 09:00:00+05
74	74	16000	cash	paid	2026-11-09 09:00:00+05
75	75	24000	kaspi	paid	2026-11-09 09:00:00+05
76	76	20000	card	paid	2026-11-09 09:00:00+05
77	77	25500	cash	paid	2026-11-09 09:00:00+05
78	78	38000	kaspi	paid	2026-11-09 09:00:00+05
79	79	21500	card	paid	2026-11-09 09:00:00+05
80	80	27000	cash	paid	2026-11-09 09:00:00+05
81	81	41000	kaspi	paid	2026-11-09 09:00:00+05
82	82	39000	card	paid	2026-11-09 09:00:00+05
83	83	49000	cash	paid	2026-11-09 09:00:00+05
84	84	74000	kaspi	paid	2026-11-09 09:00:00+05
85	85	24000	card	paid	2026-11-09 09:00:00+05
86	86	30000	cash	paid	2026-11-09 09:00:00+05
87	87	45000	kaspi	paid	2026-11-09 09:00:00+05
88	88	19000	card	paid	2026-11-09 09:00:00+05
89	89	24000	cash	paid	2026-11-09 09:00:00+05
90	90	36000	kaspi	paid	2026-11-09 09:00:00+05
91	91	20000	card	paid	2026-11-09 09:00:00+05
92	92	25500	cash	paid	2026-11-09 09:00:00+05
93	93	38000	kaspi	paid	2026-11-09 09:00:00+05
94	94	21500	card	paid	2026-11-09 09:00:00+05
95	95	27000	cash	paid	2026-11-09 09:00:00+05
96	96	41000	kaspi	paid	2026-11-09 09:00:00+05
97	97	22500	card	paid	2026-11-09 09:00:00+05
98	98	28500	cash	paid	2026-11-09 09:00:00+05
99	99	43000	kaspi	paid	2026-11-09 09:00:00+05
100	100	13500	card	paid	2026-11-09 09:00:00+05
101	101	17000	cash	paid	2026-11-09 09:00:00+05
102	102	26000	kaspi	paid	2026-11-09 09:00:00+05
103	103	19000	card	paid	2026-11-09 09:00:00+05
104	104	24000	cash	paid	2026-11-09 09:00:00+05
105	105	36000	kaspi	paid	2026-11-09 09:00:00+05
106	106	12000	card	paid	2026-11-09 09:00:00+05
107	107	15000	cash	paid	2026-11-09 09:00:00+05
108	108	23000	kaspi	paid	2026-11-09 09:00:00+05
109	109	21500	card	paid	2026-11-09 09:00:00+05
110	110	27000	cash	paid	2026-11-09 09:00:00+05
111	111	41000	kaspi	paid	2026-11-09 09:00:00+05
112	112	13500	card	paid	2026-11-09 09:00:00+05
113	113	17000	cash	paid	2026-11-09 09:00:00+05
114	114	26000	kaspi	paid	2026-11-09 09:00:00+05
115	115	24000	card	paid	2026-11-09 09:00:00+05
116	116	30000	cash	paid	2026-11-09 09:00:00+05
117	117	45000	kaspi	paid	2026-11-09 09:00:00+05
118	118	12000	card	paid	2026-11-09 09:00:00+05
119	119	15000	cash	paid	2026-11-09 09:00:00+05
120	120	23000	kaspi	paid	2026-11-09 09:00:00+05
121	121	20000	card	paid	2026-11-09 09:00:00+05
122	122	25500	cash	paid	2026-11-09 09:00:00+05
123	123	38000	kaspi	paid	2026-11-09 09:00:00+05
124	124	13500	card	paid	2026-11-09 09:00:00+05
125	125	17000	cash	paid	2026-11-09 09:00:00+05
126	126	26000	kaspi	paid	2026-11-09 09:00:00+05
127	127	22500	card	paid	2026-11-09 09:00:00+05
128	128	28500	cash	paid	2026-11-09 09:00:00+05
129	129	43000	kaspi	paid	2026-11-09 09:00:00+05
130	130	24000	card	paid	2026-11-09 09:00:00+05
131	131	30000	cash	paid	2026-11-09 09:00:00+05
132	132	45000	kaspi	paid	2026-11-09 09:00:00+05
133	133	19000	card	paid	2026-11-09 09:00:00+05
134	134	24000	cash	paid	2026-11-09 09:00:00+05
135	135	36000	kaspi	paid	2026-11-09 09:00:00+05
136	136	20000	card	paid	2026-11-09 09:00:00+05
137	137	25500	cash	paid	2026-11-09 09:00:00+05
138	138	38000	kaspi	paid	2026-11-09 09:00:00+05
139	139	14000	card	paid	2026-11-09 09:00:00+05
140	140	18000	cash	paid	2026-11-09 09:00:00+05
141	141	27000	kaspi	paid	2026-11-09 09:00:00+05
142	142	12000	card	paid	2026-11-09 09:00:00+05
143	143	15000	cash	paid	2026-11-09 09:00:00+05
144	144	23000	kaspi	paid	2026-11-09 09:00:00+05
145	145	24000	card	paid	2026-11-09 09:00:00+05
146	146	30000	cash	paid	2026-11-09 09:00:00+05
147	147	45000	kaspi	paid	2026-11-09 09:00:00+05
148	148	19000	card	paid	2026-11-09 09:00:00+05
149	149	24000	cash	paid	2026-11-09 09:00:00+05
150	150	36000	kaspi	paid	2026-11-09 09:00:00+05
151	151	14000	card	paid	2026-11-09 09:00:00+05
152	152	18000	cash	paid	2026-11-09 09:00:00+05
153	153	27000	kaspi	paid	2026-11-09 09:00:00+05
154	154	21500	card	paid	2026-11-09 09:00:00+05
155	155	27000	cash	paid	2026-11-09 09:00:00+05
156	156	41000	kaspi	paid	2026-11-09 09:00:00+05
157	157	12500	card	paid	2026-11-09 09:00:00+05
158	158	16000	cash	paid	2026-11-09 09:00:00+05
159	159	24000	kaspi	paid	2026-11-09 09:00:00+05
160	160	24000	card	paid	2026-11-09 09:00:00+05
161	161	30000	cash	paid	2026-11-09 09:00:00+05
162	162	45000	kaspi	paid	2026-11-09 09:00:00+05
163	163	19000	card	paid	2026-11-09 09:00:00+05
164	164	24000	cash	paid	2026-11-09 09:00:00+05
165	165	36000	kaspi	paid	2026-11-09 09:00:00+05
166	166	12000	card	paid	2026-11-09 09:00:00+05
167	167	15000	cash	paid	2026-11-09 09:00:00+05
168	168	23000	kaspi	paid	2026-11-09 09:00:00+05
169	169	21500	card	paid	2026-11-09 09:00:00+05
170	170	27000	cash	paid	2026-11-09 09:00:00+05
171	171	41000	kaspi	paid	2026-11-09 09:00:00+05
172	172	13500	card	paid	2026-11-09 09:00:00+05
173	173	17000	cash	paid	2026-11-09 09:00:00+05
174	174	26000	kaspi	paid	2026-11-09 09:00:00+05
175	175	24000	card	paid	2026-11-09 09:00:00+05
176	176	30000	cash	paid	2026-11-09 09:00:00+05
177	177	45000	kaspi	paid	2026-11-09 09:00:00+05
178	178	19000	card	paid	2026-11-09 09:00:00+05
179	179	24000	cash	paid	2026-11-09 09:00:00+05
180	180	36000	kaspi	paid	2026-11-09 09:00:00+05
181	181	12500	card	paid	2026-11-09 09:00:00+05
182	182	16000	cash	paid	2026-11-09 09:00:00+05
183	183	24000	kaspi	paid	2026-11-09 09:00:00+05
184	184	13500	card	paid	2026-11-09 09:00:00+05
185	185	17000	cash	paid	2026-11-09 09:00:00+05
186	186	26000	kaspi	paid	2026-11-09 09:00:00+05
187	187	14000	card	paid	2026-11-09 09:00:00+05
188	188	18000	cash	paid	2026-11-09 09:00:00+05
189	189	27000	kaspi	paid	2026-11-09 09:00:00+05
190	190	12000	card	paid	2026-11-09 09:00:00+05
191	191	15000	cash	paid	2026-11-09 09:00:00+05
192	192	23000	kaspi	paid	2026-11-09 09:00:00+05
193	193	12500	card	paid	2026-11-09 09:00:00+05
194	194	16000	cash	paid	2026-11-09 09:00:00+05
195	195	24000	kaspi	paid	2026-11-09 09:00:00+05
196	196	13500	card	paid	2026-11-09 09:00:00+05
197	197	17000	cash	paid	2026-11-09 09:00:00+05
198	198	26000	kaspi	paid	2026-11-09 09:00:00+05
199	199	14000	card	paid	2026-11-09 09:00:00+05
200	200	18000	cash	paid	2026-11-09 09:00:00+05
201	201	27000	kaspi	paid	2026-11-09 09:00:00+05
202	202	39000	card	paid	2026-11-09 09:00:00+05
203	203	49000	cash	paid	2026-11-09 09:00:00+05
204	204	74000	kaspi	paid	2026-11-09 09:00:00+05
205	205	12500	card	paid	2026-11-09 09:00:00+05
206	206	16000	cash	paid	2026-11-09 09:00:00+05
207	207	24000	kaspi	paid	2026-11-09 09:00:00+05
208	208	32000	card	paid	2026-11-09 09:00:00+05
209	209	40000	cash	paid	2026-11-09 09:00:00+05
210	210	60000	kaspi	paid	2026-11-09 09:00:00+05
\.


--
-- Data for Name: plans; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.plans (id, gym_id, name, audience, duration_days, price_kzt, price_basis, price_source_url, price_checked_on) FROM stdin;
1	1	Учебный студенческий — 30 дней	student	30	20000	model_estimate	\N	2026-11-09
2	1	Базовый — 30 дней	adult	30	25500	model_estimate	\N	2026-11-09
3	1	Учебный расширенный — 30 дней	premium	30	38000	model_estimate	\N	2026-11-09
4	2	Учебный студенческий — 30 дней	student	30	21500	model_estimate	\N	2026-11-09
5	2	Базовый — 30 дней	adult	30	27000	model_estimate	\N	2026-11-09
6	2	Учебный расширенный — 30 дней	premium	30	41000	model_estimate	\N	2026-11-09
7	3	Учебный студенческий — 30 дней	student	30	22500	model_estimate	\N	2026-11-09
8	3	Базовый — 30 дней	adult	30	28500	model_estimate	\N	2026-11-09
9	3	Учебный расширенный — 30 дней	premium	30	43000	model_estimate	\N	2026-11-09
10	4	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
11	4	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
12	4	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
13	5	Учебный студенческий — 30 дней	student	30	32000	model_estimate	\N	2026-11-09
14	5	Базовый — 30 дней	adult	30	40000	model_estimate	\N	2026-11-09
15	5	Учебный расширенный — 30 дней	premium	30	60000	model_estimate	\N	2026-11-09
16	6	Учебный студенческий — 30 дней	student	30	34000	model_estimate	\N	2026-11-09
17	6	Базовый — 30 дней	adult	30	43000	model_estimate	\N	2026-11-09
18	6	Учебный расширенный — 30 дней	premium	30	65000	model_estimate	\N	2026-11-09
19	7	Учебный студенческий — 30 дней	student	30	21500	model_estimate	\N	2026-11-09
20	7	Базовый — 30 дней	adult	30	27000	model_estimate	\N	2026-11-09
21	7	Учебный расширенный — 30 дней	premium	30	41000	model_estimate	\N	2026-11-09
22	8	Учебный студенческий — 30 дней	student	30	22500	model_estimate	\N	2026-11-09
23	8	Базовый — 30 дней	adult	30	28500	model_estimate	\N	2026-11-09
24	8	Учебный расширенный — 30 дней	premium	30	43000	model_estimate	\N	2026-11-09
25	9	Учебный студенческий — 30 дней	student	30	41500	model_estimate	\N	2026-11-09
26	9	Базовый — 30 дней	adult	30	52000	model_estimate	\N	2026-11-09
27	9	Учебный расширенный — 30 дней	premium	30	78000	model_estimate	\N	2026-11-09
28	10	Учебный студенческий — 30 дней	student	30	32000	model_estimate	\N	2026-11-09
29	10	Базовый — 30 дней	adult	30	40000	model_estimate	\N	2026-11-09
30	10	Учебный расширенный — 30 дней	premium	30	60000	model_estimate	\N	2026-11-09
31	11	Учебный студенческий — 30 дней	student	30	20000	model_estimate	\N	2026-11-09
32	11	Базовый — 30 дней	adult	30	25500	model_estimate	\N	2026-11-09
33	11	Учебный расширенный — 30 дней	premium	30	38000	model_estimate	\N	2026-11-09
34	12	Учебный студенческий — 30 дней	student	30	12000	model_estimate	\N	2026-11-09
35	12	Базовый — 30 дней	adult	30	15000	model_estimate	\N	2026-11-09
36	12	Учебный расширенный — 30 дней	premium	30	23000	model_estimate	\N	2026-11-09
37	13	Учебный студенческий — 30 дней	student	30	22500	model_estimate	\N	2026-11-09
38	13	Базовый — 30 дней	adult	30	28500	model_estimate	\N	2026-11-09
39	13	Учебный расширенный — 30 дней	premium	30	43000	model_estimate	\N	2026-11-09
40	14	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
41	14	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
42	14	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
43	15	Учебный студенческий — 30 дней	student	30	19000	model_estimate	\N	2026-11-09
44	15	Базовый — 30 дней	adult	30	24000	model_estimate	\N	2026-11-09
45	15	Учебный расширенный — 30 дней	premium	30	36000	model_estimate	\N	2026-11-09
46	16	Учебный студенческий — 30 дней	student	30	34000	model_estimate	\N	2026-11-09
47	16	Базовый — 30 дней	adult	30	43000	model_estimate	\N	2026-11-09
48	16	Учебный расширенный — 30 дней	premium	30	65000	model_estimate	\N	2026-11-09
49	17	Учебный студенческий — 30 дней	student	30	36500	model_estimate	\N	2026-11-09
50	17	Базовый — 30 дней	adult	30	46000	model_estimate	\N	2026-11-09
51	17	Учебный расширенный — 30 дней	premium	30	69000	model_estimate	\N	2026-11-09
52	18	Учебный студенческий — 30 дней	student	30	22500	model_estimate	\N	2026-11-09
53	18	Базовый — 30 дней	adult	30	28500	model_estimate	\N	2026-11-09
54	18	Учебный расширенный — 30 дней	premium	30	43000	model_estimate	\N	2026-11-09
55	19	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
56	19	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
57	19	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
58	20	Учебный студенческий — 30 дней	student	30	19000	model_estimate	\N	2026-11-09
59	20	Базовый — 30 дней	adult	30	24000	model_estimate	\N	2026-11-09
60	20	Учебный расширенный — 30 дней	premium	30	36000	model_estimate	\N	2026-11-09
61	21	Учебный студенческий — 30 дней	student	30	24500	model_estimate	\N	2026-11-09
62	21	Базовый — 30 дней	adult	30	31000	published	https://fitnestastak.kz/ru/page/klubnaya-karta	2026-11-09
63	21	Учебный расширенный — 30 дней	premium	30	46000	published	https://fitnestastak.kz/ru/page/klubnaya-karta	2026-11-09
64	22	Учебный студенческий — 30 дней	student	30	20000	published	https://www.firstfitness.kz/	2026-11-09
65	22	Базовый — 30 дней	adult	30	26000	published	https://www.firstfitness.kz/	2026-11-09
66	22	Учебный расширенный — 30 дней	premium	30	39000	model_estimate	\N	2026-11-09
67	23	Учебный студенческий — 30 дней	student	30	14000	model_estimate	\N	2026-11-09
68	23	Базовый — 30 дней	adult	30	18000	model_estimate	\N	2026-11-09
69	23	Учебный расширенный — 30 дней	premium	30	27000	model_estimate	\N	2026-11-09
70	24	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
71	24	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
72	24	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
73	25	Учебный студенческий — 30 дней	student	30	12500	model_estimate	\N	2026-11-09
74	25	Базовый — 30 дней	adult	30	16000	model_estimate	\N	2026-11-09
75	25	Учебный расширенный — 30 дней	premium	30	24000	model_estimate	\N	2026-11-09
76	26	Учебный студенческий — 30 дней	student	30	20000	model_estimate	\N	2026-11-09
77	26	Базовый — 30 дней	adult	30	25500	model_estimate	\N	2026-11-09
78	26	Учебный расширенный — 30 дней	premium	30	38000	model_estimate	\N	2026-11-09
79	27	Учебный студенческий — 30 дней	student	30	21500	model_estimate	\N	2026-11-09
80	27	Базовый — 30 дней	adult	30	27000	model_estimate	\N	2026-11-09
81	27	Учебный расширенный — 30 дней	premium	30	41000	model_estimate	\N	2026-11-09
82	28	Учебный студенческий — 30 дней	student	30	39000	model_estimate	\N	2026-11-09
83	28	Базовый — 30 дней	adult	30	49000	model_estimate	\N	2026-11-09
84	28	Учебный расширенный — 30 дней	premium	30	74000	model_estimate	\N	2026-11-09
85	29	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
86	29	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
87	29	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
88	30	Учебный студенческий — 30 дней	student	30	19000	model_estimate	\N	2026-11-09
89	30	Базовый — 30 дней	adult	30	24000	model_estimate	\N	2026-11-09
90	30	Учебный расширенный — 30 дней	premium	30	36000	model_estimate	\N	2026-11-09
91	31	Учебный студенческий — 30 дней	student	30	20000	model_estimate	\N	2026-11-09
92	31	Базовый — 30 дней	adult	30	25500	model_estimate	\N	2026-11-09
93	31	Учебный расширенный — 30 дней	premium	30	38000	model_estimate	\N	2026-11-09
94	32	Учебный студенческий — 30 дней	student	30	21500	model_estimate	\N	2026-11-09
95	32	Базовый — 30 дней	adult	30	27000	model_estimate	\N	2026-11-09
96	32	Учебный расширенный — 30 дней	premium	30	41000	model_estimate	\N	2026-11-09
97	33	Учебный студенческий — 30 дней	student	30	22500	model_estimate	\N	2026-11-09
98	33	Базовый — 30 дней	adult	30	28500	model_estimate	\N	2026-11-09
99	33	Учебный расширенный — 30 дней	premium	30	43000	model_estimate	\N	2026-11-09
100	34	Учебный студенческий — 30 дней	student	30	13500	model_estimate	\N	2026-11-09
101	34	Базовый — 30 дней	adult	30	17000	model_estimate	\N	2026-11-09
102	34	Учебный расширенный — 30 дней	premium	30	26000	model_estimate	\N	2026-11-09
103	35	Учебный студенческий — 30 дней	student	30	19000	model_estimate	\N	2026-11-09
104	35	Базовый — 30 дней	adult	30	24000	model_estimate	\N	2026-11-09
105	35	Учебный расширенный — 30 дней	premium	30	36000	model_estimate	\N	2026-11-09
106	36	Учебный студенческий — 30 дней	student	30	12000	model_estimate	\N	2026-11-09
107	36	Базовый — 30 дней	adult	30	15000	model_estimate	\N	2026-11-09
108	36	Учебный расширенный — 30 дней	premium	30	23000	model_estimate	\N	2026-11-09
109	37	Учебный студенческий — 30 дней	student	30	21500	model_estimate	\N	2026-11-09
110	37	Базовый — 30 дней	adult	30	27000	model_estimate	\N	2026-11-09
111	37	Учебный расширенный — 30 дней	premium	30	41000	model_estimate	\N	2026-11-09
112	38	Учебный студенческий — 30 дней	student	30	13500	model_estimate	\N	2026-11-09
113	38	Базовый — 30 дней	adult	30	17000	model_estimate	\N	2026-11-09
114	38	Учебный расширенный — 30 дней	premium	30	26000	model_estimate	\N	2026-11-09
115	39	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
116	39	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
117	39	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
118	40	Учебный студенческий — 30 дней	student	30	12000	model_estimate	\N	2026-11-09
119	40	Базовый — 30 дней	adult	30	15000	model_estimate	\N	2026-11-09
120	40	Учебный расширенный — 30 дней	premium	30	23000	model_estimate	\N	2026-11-09
121	41	Учебный студенческий — 30 дней	student	30	20000	model_estimate	\N	2026-11-09
122	41	Базовый — 30 дней	adult	30	25500	model_estimate	\N	2026-11-09
123	41	Учебный расширенный — 30 дней	premium	30	38000	model_estimate	\N	2026-11-09
124	42	Учебный студенческий — 30 дней	student	30	13500	model_estimate	\N	2026-11-09
125	42	Базовый — 30 дней	adult	30	17000	model_estimate	\N	2026-11-09
126	42	Учебный расширенный — 30 дней	premium	30	26000	model_estimate	\N	2026-11-09
127	43	Учебный студенческий — 30 дней	student	30	22500	model_estimate	\N	2026-11-09
128	43	Базовый — 30 дней	adult	30	28500	model_estimate	\N	2026-11-09
129	43	Учебный расширенный — 30 дней	premium	30	43000	model_estimate	\N	2026-11-09
130	44	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
131	44	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
132	44	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
133	45	Учебный студенческий — 30 дней	student	30	19000	model_estimate	\N	2026-11-09
134	45	Базовый — 30 дней	adult	30	24000	model_estimate	\N	2026-11-09
135	45	Учебный расширенный — 30 дней	premium	30	36000	model_estimate	\N	2026-11-09
136	46	Учебный студенческий — 30 дней	student	30	20000	model_estimate	\N	2026-11-09
137	46	Базовый — 30 дней	adult	30	25500	model_estimate	\N	2026-11-09
138	46	Учебный расширенный — 30 дней	premium	30	38000	model_estimate	\N	2026-11-09
139	47	Учебный студенческий — 30 дней	student	30	14000	model_estimate	\N	2026-11-09
140	47	Базовый — 30 дней	adult	30	18000	model_estimate	\N	2026-11-09
141	47	Учебный расширенный — 30 дней	premium	30	27000	model_estimate	\N	2026-11-09
142	48	Учебный студенческий — 30 дней	student	30	12000	model_estimate	\N	2026-11-09
143	48	Базовый — 30 дней	adult	30	15000	model_estimate	\N	2026-11-09
144	48	Учебный расширенный — 30 дней	premium	30	23000	model_estimate	\N	2026-11-09
145	49	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
146	49	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
147	49	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
148	50	Учебный студенческий — 30 дней	student	30	19000	model_estimate	\N	2026-11-09
149	50	Базовый — 30 дней	adult	30	24000	model_estimate	\N	2026-11-09
150	50	Учебный расширенный — 30 дней	premium	30	36000	model_estimate	\N	2026-11-09
151	51	Учебный студенческий — 30 дней	student	30	14000	model_estimate	\N	2026-11-09
152	51	Базовый — 30 дней	adult	30	18000	model_estimate	\N	2026-11-09
153	51	Учебный расширенный — 30 дней	premium	30	27000	model_estimate	\N	2026-11-09
154	52	Учебный студенческий — 30 дней	student	30	21500	model_estimate	\N	2026-11-09
155	52	Базовый — 30 дней	adult	30	27000	model_estimate	\N	2026-11-09
156	52	Учебный расширенный — 30 дней	premium	30	41000	model_estimate	\N	2026-11-09
157	53	Учебный студенческий — 30 дней	student	30	12500	model_estimate	\N	2026-11-09
158	53	Базовый — 30 дней	adult	30	16000	model_estimate	\N	2026-11-09
159	53	Учебный расширенный — 30 дней	premium	30	24000	model_estimate	\N	2026-11-09
160	54	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
161	54	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
162	54	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
163	55	Учебный студенческий — 30 дней	student	30	19000	model_estimate	\N	2026-11-09
164	55	Базовый — 30 дней	adult	30	24000	model_estimate	\N	2026-11-09
165	55	Учебный расширенный — 30 дней	premium	30	36000	model_estimate	\N	2026-11-09
166	56	Учебный студенческий — 30 дней	student	30	12000	model_estimate	\N	2026-11-09
167	56	Базовый — 30 дней	adult	30	15000	model_estimate	\N	2026-11-09
168	56	Учебный расширенный — 30 дней	premium	30	23000	model_estimate	\N	2026-11-09
169	57	Учебный студенческий — 30 дней	student	30	21500	model_estimate	\N	2026-11-09
170	57	Базовый — 30 дней	adult	30	27000	model_estimate	\N	2026-11-09
171	57	Учебный расширенный — 30 дней	premium	30	41000	model_estimate	\N	2026-11-09
172	58	Учебный студенческий — 30 дней	student	30	13500	model_estimate	\N	2026-11-09
173	58	Базовый — 30 дней	adult	30	17000	model_estimate	\N	2026-11-09
174	58	Учебный расширенный — 30 дней	premium	30	26000	model_estimate	\N	2026-11-09
175	59	Учебный студенческий — 30 дней	student	30	24000	model_estimate	\N	2026-11-09
176	59	Базовый — 30 дней	adult	30	30000	model_estimate	\N	2026-11-09
177	59	Учебный расширенный — 30 дней	premium	30	45000	model_estimate	\N	2026-11-09
178	60	Учебный студенческий — 30 дней	student	30	19000	model_estimate	\N	2026-11-09
179	60	Базовый — 30 дней	adult	30	24000	model_estimate	\N	2026-11-09
180	60	Учебный расширенный — 30 дней	premium	30	36000	model_estimate	\N	2026-11-09
181	61	Учебный студенческий — 30 дней	student	30	12500	model_estimate	\N	2026-11-09
182	61	Базовый — 30 дней	adult	30	16000	model_estimate	\N	2026-11-09
183	61	Учебный расширенный — 30 дней	premium	30	24000	model_estimate	\N	2026-11-09
184	62	Учебный студенческий — 30 дней	student	30	13500	model_estimate	\N	2026-11-09
185	62	Базовый — 30 дней	adult	30	17000	model_estimate	\N	2026-11-09
186	62	Учебный расширенный — 30 дней	premium	30	26000	model_estimate	\N	2026-11-09
187	63	Учебный студенческий — 30 дней	student	30	14000	model_estimate	\N	2026-11-09
188	63	Базовый — 30 дней	adult	30	18000	model_estimate	\N	2026-11-09
189	63	Учебный расширенный — 30 дней	premium	30	27000	model_estimate	\N	2026-11-09
190	64	Учебный студенческий — 30 дней	student	30	12000	model_estimate	\N	2026-11-09
191	64	Базовый — 30 дней	adult	30	15000	model_estimate	\N	2026-11-09
192	64	Учебный расширенный — 30 дней	premium	30	23000	model_estimate	\N	2026-11-09
193	65	Учебный студенческий — 30 дней	student	30	12500	model_estimate	\N	2026-11-09
194	65	Базовый — 30 дней	adult	30	16000	model_estimate	\N	2026-11-09
195	65	Учебный расширенный — 30 дней	premium	30	24000	model_estimate	\N	2026-11-09
196	66	Учебный студенческий — 30 дней	student	30	13500	model_estimate	\N	2026-11-09
197	66	Базовый — 30 дней	adult	30	17000	model_estimate	\N	2026-11-09
198	66	Учебный расширенный — 30 дней	premium	30	26000	model_estimate	\N	2026-11-09
199	67	Учебный студенческий — 30 дней	student	30	14000	model_estimate	\N	2026-11-09
200	67	Базовый — 30 дней	adult	30	18000	model_estimate	\N	2026-11-09
201	67	Учебный расширенный — 30 дней	premium	30	27000	model_estimate	\N	2026-11-09
202	68	Учебный студенческий — 30 дней	student	30	39000	model_estimate	\N	2026-11-09
203	68	Базовый — 30 дней	adult	30	49000	model_estimate	\N	2026-11-09
204	68	Учебный расширенный — 30 дней	premium	30	74000	model_estimate	\N	2026-11-09
205	69	Учебный студенческий — 30 дней	student	30	12500	model_estimate	\N	2026-11-09
206	69	Базовый — 30 дней	adult	30	16000	model_estimate	\N	2026-11-09
207	69	Учебный расширенный — 30 дней	premium	30	24000	model_estimate	\N	2026-11-09
208	70	Учебный студенческий — 30 дней	student	30	32000	model_estimate	\N	2026-11-09
209	70	Базовый — 30 дней	adult	30	40000	model_estimate	\N	2026-11-09
210	70	Учебный расширенный — 30 дней	premium	30	60000	model_estimate	\N	2026-11-09
221	1	Учебный расчёт — 2 месяца (60 дней)	adult	60	51000	model_estimate	\N	2026-11-10
222	1	Учебный расчёт — 3 месяца (90 дней)	adult	90	76500	model_estimate	\N	2026-11-10
223	1	Учебный расчёт — 6 месяцев (180 дней)	adult	180	153000	model_estimate	\N	2026-11-10
224	1	Учебный расчёт — 9 месяцев (270 дней)	adult	270	229500	model_estimate	\N	2026-11-10
225	1	Учебный расчёт — 2 месяца (60 дней)	premium	60	76000	model_estimate	\N	2026-11-10
226	1	Учебный расчёт — 3 месяца (90 дней)	premium	90	114000	model_estimate	\N	2026-11-10
227	1	Учебный расчёт — 6 месяцев (180 дней)	premium	180	228000	model_estimate	\N	2026-11-10
228	1	Учебный расчёт — 9 месяцев (270 дней)	premium	270	342000	model_estimate	\N	2026-11-10
229	1	Учебный расчёт — 2 месяца (60 дней)	student	60	40000	model_estimate	\N	2026-11-10
230	1	Учебный расчёт — 3 месяца (90 дней)	student	90	60000	model_estimate	\N	2026-11-10
231	1	Учебный расчёт — 6 месяцев (180 дней)	student	180	120000	model_estimate	\N	2026-11-10
232	1	Учебный расчёт — 9 месяцев (270 дней)	student	270	180000	model_estimate	\N	2026-11-10
233	2	Учебный расчёт — 2 месяца (60 дней)	adult	60	54000	model_estimate	\N	2026-11-10
234	2	Учебный расчёт — 3 месяца (90 дней)	adult	90	81000	model_estimate	\N	2026-11-10
235	2	Учебный расчёт — 6 месяцев (180 дней)	adult	180	162000	model_estimate	\N	2026-11-10
236	2	Учебный расчёт — 9 месяцев (270 дней)	adult	270	243000	model_estimate	\N	2026-11-10
237	2	Учебный расчёт — 2 месяца (60 дней)	premium	60	82000	model_estimate	\N	2026-11-10
238	2	Учебный расчёт — 3 месяца (90 дней)	premium	90	123000	model_estimate	\N	2026-11-10
239	2	Учебный расчёт — 6 месяцев (180 дней)	premium	180	246000	model_estimate	\N	2026-11-10
240	2	Учебный расчёт — 9 месяцев (270 дней)	premium	270	369000	model_estimate	\N	2026-11-10
241	2	Учебный расчёт — 2 месяца (60 дней)	student	60	43000	model_estimate	\N	2026-11-10
242	2	Учебный расчёт — 3 месяца (90 дней)	student	90	64500	model_estimate	\N	2026-11-10
243	2	Учебный расчёт — 6 месяцев (180 дней)	student	180	129000	model_estimate	\N	2026-11-10
244	2	Учебный расчёт — 9 месяцев (270 дней)	student	270	193500	model_estimate	\N	2026-11-10
245	3	Учебный расчёт — 2 месяца (60 дней)	adult	60	57000	model_estimate	\N	2026-11-10
246	3	Учебный расчёт — 3 месяца (90 дней)	adult	90	85500	model_estimate	\N	2026-11-10
247	3	Учебный расчёт — 6 месяцев (180 дней)	adult	180	171000	model_estimate	\N	2026-11-10
248	3	Учебный расчёт — 9 месяцев (270 дней)	adult	270	256500	model_estimate	\N	2026-11-10
249	3	Учебный расчёт — 2 месяца (60 дней)	premium	60	86000	model_estimate	\N	2026-11-10
250	3	Учебный расчёт — 3 месяца (90 дней)	premium	90	129000	model_estimate	\N	2026-11-10
251	3	Учебный расчёт — 6 месяцев (180 дней)	premium	180	258000	model_estimate	\N	2026-11-10
252	3	Учебный расчёт — 9 месяцев (270 дней)	premium	270	387000	model_estimate	\N	2026-11-10
253	3	Учебный расчёт — 2 месяца (60 дней)	student	60	45000	model_estimate	\N	2026-11-10
254	3	Учебный расчёт — 3 месяца (90 дней)	student	90	67500	model_estimate	\N	2026-11-10
255	3	Учебный расчёт — 6 месяцев (180 дней)	student	180	135000	model_estimate	\N	2026-11-10
256	3	Учебный расчёт — 9 месяцев (270 дней)	student	270	202500	model_estimate	\N	2026-11-10
257	4	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
258	4	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
259	4	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
260	4	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
261	4	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
262	4	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
263	4	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
264	4	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
265	4	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
266	4	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
267	4	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
268	4	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
269	5	Учебный расчёт — 2 месяца (60 дней)	adult	60	80000	model_estimate	\N	2026-11-10
270	5	Учебный расчёт — 3 месяца (90 дней)	adult	90	120000	model_estimate	\N	2026-11-10
271	5	Учебный расчёт — 6 месяцев (180 дней)	adult	180	240000	model_estimate	\N	2026-11-10
272	5	Учебный расчёт — 9 месяцев (270 дней)	adult	270	360000	model_estimate	\N	2026-11-10
273	5	Учебный расчёт — 2 месяца (60 дней)	premium	60	120000	model_estimate	\N	2026-11-10
274	5	Учебный расчёт — 3 месяца (90 дней)	premium	90	180000	model_estimate	\N	2026-11-10
275	5	Учебный расчёт — 6 месяцев (180 дней)	premium	180	360000	model_estimate	\N	2026-11-10
276	5	Учебный расчёт — 9 месяцев (270 дней)	premium	270	540000	model_estimate	\N	2026-11-10
277	5	Учебный расчёт — 2 месяца (60 дней)	student	60	64000	model_estimate	\N	2026-11-10
278	5	Учебный расчёт — 3 месяца (90 дней)	student	90	96000	model_estimate	\N	2026-11-10
279	5	Учебный расчёт — 6 месяцев (180 дней)	student	180	192000	model_estimate	\N	2026-11-10
280	5	Учебный расчёт — 9 месяцев (270 дней)	student	270	288000	model_estimate	\N	2026-11-10
281	6	Учебный расчёт — 2 месяца (60 дней)	adult	60	86000	model_estimate	\N	2026-11-10
282	6	Учебный расчёт — 3 месяца (90 дней)	adult	90	129000	model_estimate	\N	2026-11-10
283	6	Учебный расчёт — 6 месяцев (180 дней)	adult	180	258000	model_estimate	\N	2026-11-10
284	6	Учебный расчёт — 9 месяцев (270 дней)	adult	270	387000	model_estimate	\N	2026-11-10
285	6	Учебный расчёт — 2 месяца (60 дней)	premium	60	130000	model_estimate	\N	2026-11-10
286	6	Учебный расчёт — 3 месяца (90 дней)	premium	90	195000	model_estimate	\N	2026-11-10
287	6	Учебный расчёт — 6 месяцев (180 дней)	premium	180	390000	model_estimate	\N	2026-11-10
288	6	Учебный расчёт — 9 месяцев (270 дней)	premium	270	585000	model_estimate	\N	2026-11-10
289	6	Учебный расчёт — 2 месяца (60 дней)	student	60	68000	model_estimate	\N	2026-11-10
290	6	Учебный расчёт — 3 месяца (90 дней)	student	90	102000	model_estimate	\N	2026-11-10
291	6	Учебный расчёт — 6 месяцев (180 дней)	student	180	204000	model_estimate	\N	2026-11-10
292	6	Учебный расчёт — 9 месяцев (270 дней)	student	270	306000	model_estimate	\N	2026-11-10
293	7	Учебный расчёт — 2 месяца (60 дней)	adult	60	54000	model_estimate	\N	2026-11-10
294	7	Учебный расчёт — 3 месяца (90 дней)	adult	90	81000	model_estimate	\N	2026-11-10
295	7	Учебный расчёт — 6 месяцев (180 дней)	adult	180	162000	model_estimate	\N	2026-11-10
296	7	Учебный расчёт — 9 месяцев (270 дней)	adult	270	243000	model_estimate	\N	2026-11-10
297	7	Учебный расчёт — 2 месяца (60 дней)	premium	60	82000	model_estimate	\N	2026-11-10
298	7	Учебный расчёт — 3 месяца (90 дней)	premium	90	123000	model_estimate	\N	2026-11-10
299	7	Учебный расчёт — 6 месяцев (180 дней)	premium	180	246000	model_estimate	\N	2026-11-10
300	7	Учебный расчёт — 9 месяцев (270 дней)	premium	270	369000	model_estimate	\N	2026-11-10
301	7	Учебный расчёт — 2 месяца (60 дней)	student	60	43000	model_estimate	\N	2026-11-10
302	7	Учебный расчёт — 3 месяца (90 дней)	student	90	64500	model_estimate	\N	2026-11-10
303	7	Учебный расчёт — 6 месяцев (180 дней)	student	180	129000	model_estimate	\N	2026-11-10
304	7	Учебный расчёт — 9 месяцев (270 дней)	student	270	193500	model_estimate	\N	2026-11-10
305	8	Учебный расчёт — 2 месяца (60 дней)	adult	60	57000	model_estimate	\N	2026-11-10
306	8	Учебный расчёт — 3 месяца (90 дней)	adult	90	85500	model_estimate	\N	2026-11-10
307	8	Учебный расчёт — 6 месяцев (180 дней)	adult	180	171000	model_estimate	\N	2026-11-10
308	8	Учебный расчёт — 9 месяцев (270 дней)	adult	270	256500	model_estimate	\N	2026-11-10
309	8	Учебный расчёт — 2 месяца (60 дней)	premium	60	86000	model_estimate	\N	2026-11-10
310	8	Учебный расчёт — 3 месяца (90 дней)	premium	90	129000	model_estimate	\N	2026-11-10
311	8	Учебный расчёт — 6 месяцев (180 дней)	premium	180	258000	model_estimate	\N	2026-11-10
312	8	Учебный расчёт — 9 месяцев (270 дней)	premium	270	387000	model_estimate	\N	2026-11-10
313	8	Учебный расчёт — 2 месяца (60 дней)	student	60	45000	model_estimate	\N	2026-11-10
314	8	Учебный расчёт — 3 месяца (90 дней)	student	90	67500	model_estimate	\N	2026-11-10
315	8	Учебный расчёт — 6 месяцев (180 дней)	student	180	135000	model_estimate	\N	2026-11-10
316	8	Учебный расчёт — 9 месяцев (270 дней)	student	270	202500	model_estimate	\N	2026-11-10
317	9	Учебный расчёт — 2 месяца (60 дней)	adult	60	104000	model_estimate	\N	2026-11-10
318	9	Учебный расчёт — 3 месяца (90 дней)	adult	90	156000	model_estimate	\N	2026-11-10
319	9	Учебный расчёт — 6 месяцев (180 дней)	adult	180	312000	model_estimate	\N	2026-11-10
320	9	Учебный расчёт — 9 месяцев (270 дней)	adult	270	468000	model_estimate	\N	2026-11-10
321	9	Учебный расчёт — 2 месяца (60 дней)	premium	60	156000	model_estimate	\N	2026-11-10
322	9	Учебный расчёт — 3 месяца (90 дней)	premium	90	234000	model_estimate	\N	2026-11-10
323	9	Учебный расчёт — 6 месяцев (180 дней)	premium	180	468000	model_estimate	\N	2026-11-10
324	9	Учебный расчёт — 9 месяцев (270 дней)	premium	270	702000	model_estimate	\N	2026-11-10
325	9	Учебный расчёт — 2 месяца (60 дней)	student	60	83000	model_estimate	\N	2026-11-10
326	9	Учебный расчёт — 3 месяца (90 дней)	student	90	124500	model_estimate	\N	2026-11-10
327	9	Учебный расчёт — 6 месяцев (180 дней)	student	180	249000	model_estimate	\N	2026-11-10
328	9	Учебный расчёт — 9 месяцев (270 дней)	student	270	373500	model_estimate	\N	2026-11-10
329	10	Учебный расчёт — 2 месяца (60 дней)	adult	60	80000	model_estimate	\N	2026-11-10
330	10	Учебный расчёт — 3 месяца (90 дней)	adult	90	120000	model_estimate	\N	2026-11-10
331	10	Учебный расчёт — 6 месяцев (180 дней)	adult	180	240000	model_estimate	\N	2026-11-10
332	10	Учебный расчёт — 9 месяцев (270 дней)	adult	270	360000	model_estimate	\N	2026-11-10
333	10	Учебный расчёт — 2 месяца (60 дней)	premium	60	120000	model_estimate	\N	2026-11-10
334	10	Учебный расчёт — 3 месяца (90 дней)	premium	90	180000	model_estimate	\N	2026-11-10
335	10	Учебный расчёт — 6 месяцев (180 дней)	premium	180	360000	model_estimate	\N	2026-11-10
336	10	Учебный расчёт — 9 месяцев (270 дней)	premium	270	540000	model_estimate	\N	2026-11-10
337	10	Учебный расчёт — 2 месяца (60 дней)	student	60	64000	model_estimate	\N	2026-11-10
338	10	Учебный расчёт — 3 месяца (90 дней)	student	90	96000	model_estimate	\N	2026-11-10
339	10	Учебный расчёт — 6 месяцев (180 дней)	student	180	192000	model_estimate	\N	2026-11-10
340	10	Учебный расчёт — 9 месяцев (270 дней)	student	270	288000	model_estimate	\N	2026-11-10
341	11	Учебный расчёт — 2 месяца (60 дней)	adult	60	51000	model_estimate	\N	2026-11-10
342	11	Учебный расчёт — 3 месяца (90 дней)	adult	90	76500	model_estimate	\N	2026-11-10
343	11	Учебный расчёт — 6 месяцев (180 дней)	adult	180	153000	model_estimate	\N	2026-11-10
344	11	Учебный расчёт — 9 месяцев (270 дней)	adult	270	229500	model_estimate	\N	2026-11-10
345	11	Учебный расчёт — 2 месяца (60 дней)	premium	60	76000	model_estimate	\N	2026-11-10
346	11	Учебный расчёт — 3 месяца (90 дней)	premium	90	114000	model_estimate	\N	2026-11-10
347	11	Учебный расчёт — 6 месяцев (180 дней)	premium	180	228000	model_estimate	\N	2026-11-10
348	11	Учебный расчёт — 9 месяцев (270 дней)	premium	270	342000	model_estimate	\N	2026-11-10
349	11	Учебный расчёт — 2 месяца (60 дней)	student	60	40000	model_estimate	\N	2026-11-10
350	11	Учебный расчёт — 3 месяца (90 дней)	student	90	60000	model_estimate	\N	2026-11-10
351	11	Учебный расчёт — 6 месяцев (180 дней)	student	180	120000	model_estimate	\N	2026-11-10
352	11	Учебный расчёт — 9 месяцев (270 дней)	student	270	180000	model_estimate	\N	2026-11-10
353	12	Учебный расчёт — 2 месяца (60 дней)	adult	60	30000	model_estimate	\N	2026-11-10
354	12	Учебный расчёт — 3 месяца (90 дней)	adult	90	45000	model_estimate	\N	2026-11-10
355	12	Учебный расчёт — 6 месяцев (180 дней)	adult	180	90000	model_estimate	\N	2026-11-10
356	12	Учебный расчёт — 9 месяцев (270 дней)	adult	270	135000	model_estimate	\N	2026-11-10
357	12	Учебный расчёт — 2 месяца (60 дней)	premium	60	46000	model_estimate	\N	2026-11-10
358	12	Учебный расчёт — 3 месяца (90 дней)	premium	90	69000	model_estimate	\N	2026-11-10
359	12	Учебный расчёт — 6 месяцев (180 дней)	premium	180	138000	model_estimate	\N	2026-11-10
360	12	Учебный расчёт — 9 месяцев (270 дней)	premium	270	207000	model_estimate	\N	2026-11-10
361	12	Учебный расчёт — 2 месяца (60 дней)	student	60	24000	model_estimate	\N	2026-11-10
362	12	Учебный расчёт — 3 месяца (90 дней)	student	90	36000	model_estimate	\N	2026-11-10
363	12	Учебный расчёт — 6 месяцев (180 дней)	student	180	72000	model_estimate	\N	2026-11-10
364	12	Учебный расчёт — 9 месяцев (270 дней)	student	270	108000	model_estimate	\N	2026-11-10
365	13	Учебный расчёт — 2 месяца (60 дней)	adult	60	57000	model_estimate	\N	2026-11-10
366	13	Учебный расчёт — 3 месяца (90 дней)	adult	90	85500	model_estimate	\N	2026-11-10
367	13	Учебный расчёт — 6 месяцев (180 дней)	adult	180	171000	model_estimate	\N	2026-11-10
368	13	Учебный расчёт — 9 месяцев (270 дней)	adult	270	256500	model_estimate	\N	2026-11-10
369	13	Учебный расчёт — 2 месяца (60 дней)	premium	60	86000	model_estimate	\N	2026-11-10
370	13	Учебный расчёт — 3 месяца (90 дней)	premium	90	129000	model_estimate	\N	2026-11-10
371	13	Учебный расчёт — 6 месяцев (180 дней)	premium	180	258000	model_estimate	\N	2026-11-10
372	13	Учебный расчёт — 9 месяцев (270 дней)	premium	270	387000	model_estimate	\N	2026-11-10
373	13	Учебный расчёт — 2 месяца (60 дней)	student	60	45000	model_estimate	\N	2026-11-10
374	13	Учебный расчёт — 3 месяца (90 дней)	student	90	67500	model_estimate	\N	2026-11-10
375	13	Учебный расчёт — 6 месяцев (180 дней)	student	180	135000	model_estimate	\N	2026-11-10
376	13	Учебный расчёт — 9 месяцев (270 дней)	student	270	202500	model_estimate	\N	2026-11-10
377	14	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
378	14	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
379	14	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
380	14	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
381	14	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
382	14	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
383	14	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
384	14	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
385	14	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
386	14	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
387	14	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
388	14	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
389	15	Учебный расчёт — 2 месяца (60 дней)	adult	60	48000	model_estimate	\N	2026-11-10
390	15	Учебный расчёт — 3 месяца (90 дней)	adult	90	72000	model_estimate	\N	2026-11-10
391	15	Учебный расчёт — 6 месяцев (180 дней)	adult	180	144000	model_estimate	\N	2026-11-10
392	15	Учебный расчёт — 9 месяцев (270 дней)	adult	270	216000	model_estimate	\N	2026-11-10
393	15	Учебный расчёт — 2 месяца (60 дней)	premium	60	72000	model_estimate	\N	2026-11-10
394	15	Учебный расчёт — 3 месяца (90 дней)	premium	90	108000	model_estimate	\N	2026-11-10
395	15	Учебный расчёт — 6 месяцев (180 дней)	premium	180	216000	model_estimate	\N	2026-11-10
396	15	Учебный расчёт — 9 месяцев (270 дней)	premium	270	324000	model_estimate	\N	2026-11-10
397	15	Учебный расчёт — 2 месяца (60 дней)	student	60	38000	model_estimate	\N	2026-11-10
398	15	Учебный расчёт — 3 месяца (90 дней)	student	90	57000	model_estimate	\N	2026-11-10
399	15	Учебный расчёт — 6 месяцев (180 дней)	student	180	114000	model_estimate	\N	2026-11-10
400	15	Учебный расчёт — 9 месяцев (270 дней)	student	270	171000	model_estimate	\N	2026-11-10
401	16	Учебный расчёт — 2 месяца (60 дней)	adult	60	86000	model_estimate	\N	2026-11-10
402	16	Учебный расчёт — 3 месяца (90 дней)	adult	90	129000	model_estimate	\N	2026-11-10
403	16	Учебный расчёт — 6 месяцев (180 дней)	adult	180	258000	model_estimate	\N	2026-11-10
404	16	Учебный расчёт — 9 месяцев (270 дней)	adult	270	387000	model_estimate	\N	2026-11-10
405	16	Учебный расчёт — 2 месяца (60 дней)	premium	60	130000	model_estimate	\N	2026-11-10
406	16	Учебный расчёт — 3 месяца (90 дней)	premium	90	195000	model_estimate	\N	2026-11-10
407	16	Учебный расчёт — 6 месяцев (180 дней)	premium	180	390000	model_estimate	\N	2026-11-10
408	16	Учебный расчёт — 9 месяцев (270 дней)	premium	270	585000	model_estimate	\N	2026-11-10
409	16	Учебный расчёт — 2 месяца (60 дней)	student	60	68000	model_estimate	\N	2026-11-10
410	16	Учебный расчёт — 3 месяца (90 дней)	student	90	102000	model_estimate	\N	2026-11-10
411	16	Учебный расчёт — 6 месяцев (180 дней)	student	180	204000	model_estimate	\N	2026-11-10
412	16	Учебный расчёт — 9 месяцев (270 дней)	student	270	306000	model_estimate	\N	2026-11-10
413	17	Учебный расчёт — 2 месяца (60 дней)	adult	60	92000	model_estimate	\N	2026-11-10
414	17	Учебный расчёт — 3 месяца (90 дней)	adult	90	138000	model_estimate	\N	2026-11-10
415	17	Учебный расчёт — 6 месяцев (180 дней)	adult	180	276000	model_estimate	\N	2026-11-10
416	17	Учебный расчёт — 9 месяцев (270 дней)	adult	270	414000	model_estimate	\N	2026-11-10
417	17	Учебный расчёт — 2 месяца (60 дней)	premium	60	138000	model_estimate	\N	2026-11-10
418	17	Учебный расчёт — 3 месяца (90 дней)	premium	90	207000	model_estimate	\N	2026-11-10
419	17	Учебный расчёт — 6 месяцев (180 дней)	premium	180	414000	model_estimate	\N	2026-11-10
420	17	Учебный расчёт — 9 месяцев (270 дней)	premium	270	621000	model_estimate	\N	2026-11-10
421	17	Учебный расчёт — 2 месяца (60 дней)	student	60	73000	model_estimate	\N	2026-11-10
422	17	Учебный расчёт — 3 месяца (90 дней)	student	90	109500	model_estimate	\N	2026-11-10
423	17	Учебный расчёт — 6 месяцев (180 дней)	student	180	219000	model_estimate	\N	2026-11-10
424	17	Учебный расчёт — 9 месяцев (270 дней)	student	270	328500	model_estimate	\N	2026-11-10
425	18	Учебный расчёт — 2 месяца (60 дней)	adult	60	57000	model_estimate	\N	2026-11-10
426	18	Учебный расчёт — 3 месяца (90 дней)	adult	90	85500	model_estimate	\N	2026-11-10
427	18	Учебный расчёт — 6 месяцев (180 дней)	adult	180	171000	model_estimate	\N	2026-11-10
428	18	Учебный расчёт — 9 месяцев (270 дней)	adult	270	256500	model_estimate	\N	2026-11-10
429	18	Учебный расчёт — 2 месяца (60 дней)	premium	60	86000	model_estimate	\N	2026-11-10
430	18	Учебный расчёт — 3 месяца (90 дней)	premium	90	129000	model_estimate	\N	2026-11-10
431	18	Учебный расчёт — 6 месяцев (180 дней)	premium	180	258000	model_estimate	\N	2026-11-10
432	18	Учебный расчёт — 9 месяцев (270 дней)	premium	270	387000	model_estimate	\N	2026-11-10
433	18	Учебный расчёт — 2 месяца (60 дней)	student	60	45000	model_estimate	\N	2026-11-10
434	18	Учебный расчёт — 3 месяца (90 дней)	student	90	67500	model_estimate	\N	2026-11-10
435	18	Учебный расчёт — 6 месяцев (180 дней)	student	180	135000	model_estimate	\N	2026-11-10
436	18	Учебный расчёт — 9 месяцев (270 дней)	student	270	202500	model_estimate	\N	2026-11-10
437	19	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
438	19	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
439	19	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
440	19	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
441	19	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
442	19	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
443	19	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
444	19	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
445	19	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
446	19	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
447	19	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
448	19	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
449	20	Учебный расчёт — 2 месяца (60 дней)	adult	60	48000	model_estimate	\N	2026-11-10
450	20	Учебный расчёт — 3 месяца (90 дней)	adult	90	72000	model_estimate	\N	2026-11-10
451	20	Учебный расчёт — 6 месяцев (180 дней)	adult	180	144000	model_estimate	\N	2026-11-10
452	20	Учебный расчёт — 9 месяцев (270 дней)	adult	270	216000	model_estimate	\N	2026-11-10
453	20	Учебный расчёт — 2 месяца (60 дней)	premium	60	72000	model_estimate	\N	2026-11-10
454	20	Учебный расчёт — 3 месяца (90 дней)	premium	90	108000	model_estimate	\N	2026-11-10
455	20	Учебный расчёт — 6 месяцев (180 дней)	premium	180	216000	model_estimate	\N	2026-11-10
456	20	Учебный расчёт — 9 месяцев (270 дней)	premium	270	324000	model_estimate	\N	2026-11-10
457	20	Учебный расчёт — 2 месяца (60 дней)	student	60	38000	model_estimate	\N	2026-11-10
458	20	Учебный расчёт — 3 месяца (90 дней)	student	90	57000	model_estimate	\N	2026-11-10
459	20	Учебный расчёт — 6 месяцев (180 дней)	student	180	114000	model_estimate	\N	2026-11-10
460	20	Учебный расчёт — 9 месяцев (270 дней)	student	270	171000	model_estimate	\N	2026-11-10
461	21	Учебный расчёт — 2 месяца (60 дней)	adult	60	62000	model_estimate	\N	2026-11-10
462	21	Учебный расчёт — 3 месяца (90 дней)	adult	90	93000	model_estimate	\N	2026-11-10
463	21	Учебный расчёт — 6 месяцев (180 дней)	adult	180	186000	model_estimate	\N	2026-11-10
464	21	Учебный расчёт — 9 месяцев (270 дней)	adult	270	279000	model_estimate	\N	2026-11-10
465	21	Учебный расчёт — 2 месяца (60 дней)	premium	60	92000	model_estimate	\N	2026-11-10
466	21	Учебный расчёт — 3 месяца (90 дней)	premium	90	138000	model_estimate	\N	2026-11-10
467	21	Учебный расчёт — 6 месяцев (180 дней)	premium	180	276000	model_estimate	\N	2026-11-10
468	21	Учебный расчёт — 9 месяцев (270 дней)	premium	270	414000	model_estimate	\N	2026-11-10
469	21	Учебный расчёт — 2 месяца (60 дней)	student	60	49000	model_estimate	\N	2026-11-10
470	21	Учебный расчёт — 3 месяца (90 дней)	student	90	73500	model_estimate	\N	2026-11-10
471	21	Учебный расчёт — 6 месяцев (180 дней)	student	180	147000	model_estimate	\N	2026-11-10
472	21	Учебный расчёт — 9 месяцев (270 дней)	student	270	220500	model_estimate	\N	2026-11-10
473	22	Учебный расчёт — 2 месяца (60 дней)	adult	60	52000	model_estimate	\N	2026-11-10
474	22	Учебный расчёт — 3 месяца (90 дней)	adult	90	78000	model_estimate	\N	2026-11-10
475	22	Учебный расчёт — 6 месяцев (180 дней)	adult	180	156000	model_estimate	\N	2026-11-10
476	22	Учебный расчёт — 9 месяцев (270 дней)	adult	270	234000	model_estimate	\N	2026-11-10
477	22	Учебный расчёт — 2 месяца (60 дней)	premium	60	78000	model_estimate	\N	2026-11-10
478	22	Учебный расчёт — 3 месяца (90 дней)	premium	90	117000	model_estimate	\N	2026-11-10
479	22	Учебный расчёт — 6 месяцев (180 дней)	premium	180	234000	model_estimate	\N	2026-11-10
480	22	Учебный расчёт — 9 месяцев (270 дней)	premium	270	351000	model_estimate	\N	2026-11-10
481	22	Учебный расчёт — 2 месяца (60 дней)	student	60	40000	model_estimate	\N	2026-11-10
482	22	Учебный расчёт — 3 месяца (90 дней)	student	90	60000	model_estimate	\N	2026-11-10
483	22	Учебный расчёт — 6 месяцев (180 дней)	student	180	120000	model_estimate	\N	2026-11-10
484	22	Учебный расчёт — 9 месяцев (270 дней)	student	270	180000	model_estimate	\N	2026-11-10
485	23	Учебный расчёт — 2 месяца (60 дней)	adult	60	36000	model_estimate	\N	2026-11-10
486	23	Учебный расчёт — 3 месяца (90 дней)	adult	90	54000	model_estimate	\N	2026-11-10
487	23	Учебный расчёт — 6 месяцев (180 дней)	adult	180	108000	model_estimate	\N	2026-11-10
488	23	Учебный расчёт — 9 месяцев (270 дней)	adult	270	162000	model_estimate	\N	2026-11-10
489	23	Учебный расчёт — 2 месяца (60 дней)	premium	60	54000	model_estimate	\N	2026-11-10
490	23	Учебный расчёт — 3 месяца (90 дней)	premium	90	81000	model_estimate	\N	2026-11-10
491	23	Учебный расчёт — 6 месяцев (180 дней)	premium	180	162000	model_estimate	\N	2026-11-10
492	23	Учебный расчёт — 9 месяцев (270 дней)	premium	270	243000	model_estimate	\N	2026-11-10
493	23	Учебный расчёт — 2 месяца (60 дней)	student	60	28000	model_estimate	\N	2026-11-10
494	23	Учебный расчёт — 3 месяца (90 дней)	student	90	42000	model_estimate	\N	2026-11-10
495	23	Учебный расчёт — 6 месяцев (180 дней)	student	180	84000	model_estimate	\N	2026-11-10
496	23	Учебный расчёт — 9 месяцев (270 дней)	student	270	126000	model_estimate	\N	2026-11-10
497	24	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
498	24	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
499	24	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
500	24	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
501	24	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
502	24	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
503	24	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
504	24	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
505	24	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
506	24	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
507	24	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
508	24	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
509	25	Учебный расчёт — 2 месяца (60 дней)	adult	60	32000	model_estimate	\N	2026-11-10
510	25	Учебный расчёт — 3 месяца (90 дней)	adult	90	48000	model_estimate	\N	2026-11-10
511	25	Учебный расчёт — 6 месяцев (180 дней)	adult	180	96000	model_estimate	\N	2026-11-10
512	25	Учебный расчёт — 9 месяцев (270 дней)	adult	270	144000	model_estimate	\N	2026-11-10
513	25	Учебный расчёт — 2 месяца (60 дней)	premium	60	48000	model_estimate	\N	2026-11-10
514	25	Учебный расчёт — 3 месяца (90 дней)	premium	90	72000	model_estimate	\N	2026-11-10
515	25	Учебный расчёт — 6 месяцев (180 дней)	premium	180	144000	model_estimate	\N	2026-11-10
516	25	Учебный расчёт — 9 месяцев (270 дней)	premium	270	216000	model_estimate	\N	2026-11-10
517	25	Учебный расчёт — 2 месяца (60 дней)	student	60	25000	model_estimate	\N	2026-11-10
518	25	Учебный расчёт — 3 месяца (90 дней)	student	90	37500	model_estimate	\N	2026-11-10
519	25	Учебный расчёт — 6 месяцев (180 дней)	student	180	75000	model_estimate	\N	2026-11-10
520	25	Учебный расчёт — 9 месяцев (270 дней)	student	270	112500	model_estimate	\N	2026-11-10
521	26	Учебный расчёт — 2 месяца (60 дней)	adult	60	51000	model_estimate	\N	2026-11-10
522	26	Учебный расчёт — 3 месяца (90 дней)	adult	90	76500	model_estimate	\N	2026-11-10
523	26	Учебный расчёт — 6 месяцев (180 дней)	adult	180	153000	model_estimate	\N	2026-11-10
524	26	Учебный расчёт — 9 месяцев (270 дней)	adult	270	229500	model_estimate	\N	2026-11-10
525	26	Учебный расчёт — 2 месяца (60 дней)	premium	60	76000	model_estimate	\N	2026-11-10
526	26	Учебный расчёт — 3 месяца (90 дней)	premium	90	114000	model_estimate	\N	2026-11-10
527	26	Учебный расчёт — 6 месяцев (180 дней)	premium	180	228000	model_estimate	\N	2026-11-10
528	26	Учебный расчёт — 9 месяцев (270 дней)	premium	270	342000	model_estimate	\N	2026-11-10
529	26	Учебный расчёт — 2 месяца (60 дней)	student	60	40000	model_estimate	\N	2026-11-10
530	26	Учебный расчёт — 3 месяца (90 дней)	student	90	60000	model_estimate	\N	2026-11-10
531	26	Учебный расчёт — 6 месяцев (180 дней)	student	180	120000	model_estimate	\N	2026-11-10
532	26	Учебный расчёт — 9 месяцев (270 дней)	student	270	180000	model_estimate	\N	2026-11-10
533	27	Учебный расчёт — 2 месяца (60 дней)	adult	60	54000	model_estimate	\N	2026-11-10
534	27	Учебный расчёт — 3 месяца (90 дней)	adult	90	81000	model_estimate	\N	2026-11-10
535	27	Учебный расчёт — 6 месяцев (180 дней)	adult	180	162000	model_estimate	\N	2026-11-10
536	27	Учебный расчёт — 9 месяцев (270 дней)	adult	270	243000	model_estimate	\N	2026-11-10
537	27	Учебный расчёт — 2 месяца (60 дней)	premium	60	82000	model_estimate	\N	2026-11-10
538	27	Учебный расчёт — 3 месяца (90 дней)	premium	90	123000	model_estimate	\N	2026-11-10
539	27	Учебный расчёт — 6 месяцев (180 дней)	premium	180	246000	model_estimate	\N	2026-11-10
540	27	Учебный расчёт — 9 месяцев (270 дней)	premium	270	369000	model_estimate	\N	2026-11-10
541	27	Учебный расчёт — 2 месяца (60 дней)	student	60	43000	model_estimate	\N	2026-11-10
542	27	Учебный расчёт — 3 месяца (90 дней)	student	90	64500	model_estimate	\N	2026-11-10
543	27	Учебный расчёт — 6 месяцев (180 дней)	student	180	129000	model_estimate	\N	2026-11-10
544	27	Учебный расчёт — 9 месяцев (270 дней)	student	270	193500	model_estimate	\N	2026-11-10
545	28	Учебный расчёт — 2 месяца (60 дней)	adult	60	98000	model_estimate	\N	2026-11-10
546	28	Учебный расчёт — 3 месяца (90 дней)	adult	90	147000	model_estimate	\N	2026-11-10
547	28	Учебный расчёт — 6 месяцев (180 дней)	adult	180	294000	model_estimate	\N	2026-11-10
548	28	Учебный расчёт — 9 месяцев (270 дней)	adult	270	441000	model_estimate	\N	2026-11-10
549	28	Учебный расчёт — 2 месяца (60 дней)	premium	60	148000	model_estimate	\N	2026-11-10
550	28	Учебный расчёт — 3 месяца (90 дней)	premium	90	222000	model_estimate	\N	2026-11-10
551	28	Учебный расчёт — 6 месяцев (180 дней)	premium	180	444000	model_estimate	\N	2026-11-10
552	28	Учебный расчёт — 9 месяцев (270 дней)	premium	270	666000	model_estimate	\N	2026-11-10
553	28	Учебный расчёт — 2 месяца (60 дней)	student	60	78000	model_estimate	\N	2026-11-10
554	28	Учебный расчёт — 3 месяца (90 дней)	student	90	117000	model_estimate	\N	2026-11-10
555	28	Учебный расчёт — 6 месяцев (180 дней)	student	180	234000	model_estimate	\N	2026-11-10
556	28	Учебный расчёт — 9 месяцев (270 дней)	student	270	351000	model_estimate	\N	2026-11-10
557	29	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
558	29	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
559	29	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
560	29	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
561	29	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
562	29	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
563	29	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
564	29	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
565	29	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
566	29	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
567	29	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
568	29	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
569	30	Учебный расчёт — 2 месяца (60 дней)	adult	60	48000	model_estimate	\N	2026-11-10
570	30	Учебный расчёт — 3 месяца (90 дней)	adult	90	72000	model_estimate	\N	2026-11-10
571	30	Учебный расчёт — 6 месяцев (180 дней)	adult	180	144000	model_estimate	\N	2026-11-10
572	30	Учебный расчёт — 9 месяцев (270 дней)	adult	270	216000	model_estimate	\N	2026-11-10
573	30	Учебный расчёт — 2 месяца (60 дней)	premium	60	72000	model_estimate	\N	2026-11-10
574	30	Учебный расчёт — 3 месяца (90 дней)	premium	90	108000	model_estimate	\N	2026-11-10
575	30	Учебный расчёт — 6 месяцев (180 дней)	premium	180	216000	model_estimate	\N	2026-11-10
576	30	Учебный расчёт — 9 месяцев (270 дней)	premium	270	324000	model_estimate	\N	2026-11-10
577	30	Учебный расчёт — 2 месяца (60 дней)	student	60	38000	model_estimate	\N	2026-11-10
578	30	Учебный расчёт — 3 месяца (90 дней)	student	90	57000	model_estimate	\N	2026-11-10
579	30	Учебный расчёт — 6 месяцев (180 дней)	student	180	114000	model_estimate	\N	2026-11-10
580	30	Учебный расчёт — 9 месяцев (270 дней)	student	270	171000	model_estimate	\N	2026-11-10
581	31	Учебный расчёт — 2 месяца (60 дней)	adult	60	51000	model_estimate	\N	2026-11-10
582	31	Учебный расчёт — 3 месяца (90 дней)	adult	90	76500	model_estimate	\N	2026-11-10
583	31	Учебный расчёт — 6 месяцев (180 дней)	adult	180	153000	model_estimate	\N	2026-11-10
584	31	Учебный расчёт — 9 месяцев (270 дней)	adult	270	229500	model_estimate	\N	2026-11-10
585	31	Учебный расчёт — 2 месяца (60 дней)	premium	60	76000	model_estimate	\N	2026-11-10
586	31	Учебный расчёт — 3 месяца (90 дней)	premium	90	114000	model_estimate	\N	2026-11-10
587	31	Учебный расчёт — 6 месяцев (180 дней)	premium	180	228000	model_estimate	\N	2026-11-10
588	31	Учебный расчёт — 9 месяцев (270 дней)	premium	270	342000	model_estimate	\N	2026-11-10
589	31	Учебный расчёт — 2 месяца (60 дней)	student	60	40000	model_estimate	\N	2026-11-10
590	31	Учебный расчёт — 3 месяца (90 дней)	student	90	60000	model_estimate	\N	2026-11-10
591	31	Учебный расчёт — 6 месяцев (180 дней)	student	180	120000	model_estimate	\N	2026-11-10
592	31	Учебный расчёт — 9 месяцев (270 дней)	student	270	180000	model_estimate	\N	2026-11-10
593	32	Учебный расчёт — 2 месяца (60 дней)	adult	60	54000	model_estimate	\N	2026-11-10
594	32	Учебный расчёт — 3 месяца (90 дней)	adult	90	81000	model_estimate	\N	2026-11-10
595	32	Учебный расчёт — 6 месяцев (180 дней)	adult	180	162000	model_estimate	\N	2026-11-10
596	32	Учебный расчёт — 9 месяцев (270 дней)	adult	270	243000	model_estimate	\N	2026-11-10
597	32	Учебный расчёт — 2 месяца (60 дней)	premium	60	82000	model_estimate	\N	2026-11-10
598	32	Учебный расчёт — 3 месяца (90 дней)	premium	90	123000	model_estimate	\N	2026-11-10
599	32	Учебный расчёт — 6 месяцев (180 дней)	premium	180	246000	model_estimate	\N	2026-11-10
600	32	Учебный расчёт — 9 месяцев (270 дней)	premium	270	369000	model_estimate	\N	2026-11-10
601	32	Учебный расчёт — 2 месяца (60 дней)	student	60	43000	model_estimate	\N	2026-11-10
602	32	Учебный расчёт — 3 месяца (90 дней)	student	90	64500	model_estimate	\N	2026-11-10
603	32	Учебный расчёт — 6 месяцев (180 дней)	student	180	129000	model_estimate	\N	2026-11-10
604	32	Учебный расчёт — 9 месяцев (270 дней)	student	270	193500	model_estimate	\N	2026-11-10
605	33	Учебный расчёт — 2 месяца (60 дней)	adult	60	57000	model_estimate	\N	2026-11-10
606	33	Учебный расчёт — 3 месяца (90 дней)	adult	90	85500	model_estimate	\N	2026-11-10
607	33	Учебный расчёт — 6 месяцев (180 дней)	adult	180	171000	model_estimate	\N	2026-11-10
608	33	Учебный расчёт — 9 месяцев (270 дней)	adult	270	256500	model_estimate	\N	2026-11-10
609	33	Учебный расчёт — 2 месяца (60 дней)	premium	60	86000	model_estimate	\N	2026-11-10
610	33	Учебный расчёт — 3 месяца (90 дней)	premium	90	129000	model_estimate	\N	2026-11-10
611	33	Учебный расчёт — 6 месяцев (180 дней)	premium	180	258000	model_estimate	\N	2026-11-10
612	33	Учебный расчёт — 9 месяцев (270 дней)	premium	270	387000	model_estimate	\N	2026-11-10
613	33	Учебный расчёт — 2 месяца (60 дней)	student	60	45000	model_estimate	\N	2026-11-10
614	33	Учебный расчёт — 3 месяца (90 дней)	student	90	67500	model_estimate	\N	2026-11-10
615	33	Учебный расчёт — 6 месяцев (180 дней)	student	180	135000	model_estimate	\N	2026-11-10
616	33	Учебный расчёт — 9 месяцев (270 дней)	student	270	202500	model_estimate	\N	2026-11-10
617	34	Учебный расчёт — 2 месяца (60 дней)	adult	60	34000	model_estimate	\N	2026-11-10
618	34	Учебный расчёт — 3 месяца (90 дней)	adult	90	51000	model_estimate	\N	2026-11-10
619	34	Учебный расчёт — 6 месяцев (180 дней)	adult	180	102000	model_estimate	\N	2026-11-10
620	34	Учебный расчёт — 9 месяцев (270 дней)	adult	270	153000	model_estimate	\N	2026-11-10
621	34	Учебный расчёт — 2 месяца (60 дней)	premium	60	52000	model_estimate	\N	2026-11-10
622	34	Учебный расчёт — 3 месяца (90 дней)	premium	90	78000	model_estimate	\N	2026-11-10
623	34	Учебный расчёт — 6 месяцев (180 дней)	premium	180	156000	model_estimate	\N	2026-11-10
624	34	Учебный расчёт — 9 месяцев (270 дней)	premium	270	234000	model_estimate	\N	2026-11-10
625	34	Учебный расчёт — 2 месяца (60 дней)	student	60	27000	model_estimate	\N	2026-11-10
626	34	Учебный расчёт — 3 месяца (90 дней)	student	90	40500	model_estimate	\N	2026-11-10
627	34	Учебный расчёт — 6 месяцев (180 дней)	student	180	81000	model_estimate	\N	2026-11-10
628	34	Учебный расчёт — 9 месяцев (270 дней)	student	270	121500	model_estimate	\N	2026-11-10
629	35	Учебный расчёт — 2 месяца (60 дней)	adult	60	48000	model_estimate	\N	2026-11-10
630	35	Учебный расчёт — 3 месяца (90 дней)	adult	90	72000	model_estimate	\N	2026-11-10
631	35	Учебный расчёт — 6 месяцев (180 дней)	adult	180	144000	model_estimate	\N	2026-11-10
632	35	Учебный расчёт — 9 месяцев (270 дней)	adult	270	216000	model_estimate	\N	2026-11-10
633	35	Учебный расчёт — 2 месяца (60 дней)	premium	60	72000	model_estimate	\N	2026-11-10
634	35	Учебный расчёт — 3 месяца (90 дней)	premium	90	108000	model_estimate	\N	2026-11-10
635	35	Учебный расчёт — 6 месяцев (180 дней)	premium	180	216000	model_estimate	\N	2026-11-10
636	35	Учебный расчёт — 9 месяцев (270 дней)	premium	270	324000	model_estimate	\N	2026-11-10
637	35	Учебный расчёт — 2 месяца (60 дней)	student	60	38000	model_estimate	\N	2026-11-10
638	35	Учебный расчёт — 3 месяца (90 дней)	student	90	57000	model_estimate	\N	2026-11-10
639	35	Учебный расчёт — 6 месяцев (180 дней)	student	180	114000	model_estimate	\N	2026-11-10
640	35	Учебный расчёт — 9 месяцев (270 дней)	student	270	171000	model_estimate	\N	2026-11-10
641	36	Учебный расчёт — 2 месяца (60 дней)	adult	60	30000	model_estimate	\N	2026-11-10
642	36	Учебный расчёт — 3 месяца (90 дней)	adult	90	45000	model_estimate	\N	2026-11-10
643	36	Учебный расчёт — 6 месяцев (180 дней)	adult	180	90000	model_estimate	\N	2026-11-10
644	36	Учебный расчёт — 9 месяцев (270 дней)	adult	270	135000	model_estimate	\N	2026-11-10
645	36	Учебный расчёт — 2 месяца (60 дней)	premium	60	46000	model_estimate	\N	2026-11-10
646	36	Учебный расчёт — 3 месяца (90 дней)	premium	90	69000	model_estimate	\N	2026-11-10
647	36	Учебный расчёт — 6 месяцев (180 дней)	premium	180	138000	model_estimate	\N	2026-11-10
648	36	Учебный расчёт — 9 месяцев (270 дней)	premium	270	207000	model_estimate	\N	2026-11-10
649	36	Учебный расчёт — 2 месяца (60 дней)	student	60	24000	model_estimate	\N	2026-11-10
650	36	Учебный расчёт — 3 месяца (90 дней)	student	90	36000	model_estimate	\N	2026-11-10
651	36	Учебный расчёт — 6 месяцев (180 дней)	student	180	72000	model_estimate	\N	2026-11-10
652	36	Учебный расчёт — 9 месяцев (270 дней)	student	270	108000	model_estimate	\N	2026-11-10
653	37	Учебный расчёт — 2 месяца (60 дней)	adult	60	54000	model_estimate	\N	2026-11-10
654	37	Учебный расчёт — 3 месяца (90 дней)	adult	90	81000	model_estimate	\N	2026-11-10
655	37	Учебный расчёт — 6 месяцев (180 дней)	adult	180	162000	model_estimate	\N	2026-11-10
656	37	Учебный расчёт — 9 месяцев (270 дней)	adult	270	243000	model_estimate	\N	2026-11-10
657	37	Учебный расчёт — 2 месяца (60 дней)	premium	60	82000	model_estimate	\N	2026-11-10
658	37	Учебный расчёт — 3 месяца (90 дней)	premium	90	123000	model_estimate	\N	2026-11-10
659	37	Учебный расчёт — 6 месяцев (180 дней)	premium	180	246000	model_estimate	\N	2026-11-10
660	37	Учебный расчёт — 9 месяцев (270 дней)	premium	270	369000	model_estimate	\N	2026-11-10
661	37	Учебный расчёт — 2 месяца (60 дней)	student	60	43000	model_estimate	\N	2026-11-10
662	37	Учебный расчёт — 3 месяца (90 дней)	student	90	64500	model_estimate	\N	2026-11-10
663	37	Учебный расчёт — 6 месяцев (180 дней)	student	180	129000	model_estimate	\N	2026-11-10
664	37	Учебный расчёт — 9 месяцев (270 дней)	student	270	193500	model_estimate	\N	2026-11-10
665	38	Учебный расчёт — 2 месяца (60 дней)	adult	60	34000	model_estimate	\N	2026-11-10
666	38	Учебный расчёт — 3 месяца (90 дней)	adult	90	51000	model_estimate	\N	2026-11-10
667	38	Учебный расчёт — 6 месяцев (180 дней)	adult	180	102000	model_estimate	\N	2026-11-10
668	38	Учебный расчёт — 9 месяцев (270 дней)	adult	270	153000	model_estimate	\N	2026-11-10
669	38	Учебный расчёт — 2 месяца (60 дней)	premium	60	52000	model_estimate	\N	2026-11-10
670	38	Учебный расчёт — 3 месяца (90 дней)	premium	90	78000	model_estimate	\N	2026-11-10
671	38	Учебный расчёт — 6 месяцев (180 дней)	premium	180	156000	model_estimate	\N	2026-11-10
672	38	Учебный расчёт — 9 месяцев (270 дней)	premium	270	234000	model_estimate	\N	2026-11-10
673	38	Учебный расчёт — 2 месяца (60 дней)	student	60	27000	model_estimate	\N	2026-11-10
674	38	Учебный расчёт — 3 месяца (90 дней)	student	90	40500	model_estimate	\N	2026-11-10
675	38	Учебный расчёт — 6 месяцев (180 дней)	student	180	81000	model_estimate	\N	2026-11-10
676	38	Учебный расчёт — 9 месяцев (270 дней)	student	270	121500	model_estimate	\N	2026-11-10
677	39	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
678	39	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
679	39	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
680	39	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
681	39	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
682	39	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
683	39	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
684	39	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
685	39	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
686	39	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
687	39	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
688	39	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
689	40	Учебный расчёт — 2 месяца (60 дней)	adult	60	30000	model_estimate	\N	2026-11-10
690	40	Учебный расчёт — 3 месяца (90 дней)	adult	90	45000	model_estimate	\N	2026-11-10
691	40	Учебный расчёт — 6 месяцев (180 дней)	adult	180	90000	model_estimate	\N	2026-11-10
692	40	Учебный расчёт — 9 месяцев (270 дней)	adult	270	135000	model_estimate	\N	2026-11-10
693	40	Учебный расчёт — 2 месяца (60 дней)	premium	60	46000	model_estimate	\N	2026-11-10
694	40	Учебный расчёт — 3 месяца (90 дней)	premium	90	69000	model_estimate	\N	2026-11-10
695	40	Учебный расчёт — 6 месяцев (180 дней)	premium	180	138000	model_estimate	\N	2026-11-10
696	40	Учебный расчёт — 9 месяцев (270 дней)	premium	270	207000	model_estimate	\N	2026-11-10
697	40	Учебный расчёт — 2 месяца (60 дней)	student	60	24000	model_estimate	\N	2026-11-10
698	40	Учебный расчёт — 3 месяца (90 дней)	student	90	36000	model_estimate	\N	2026-11-10
699	40	Учебный расчёт — 6 месяцев (180 дней)	student	180	72000	model_estimate	\N	2026-11-10
700	40	Учебный расчёт — 9 месяцев (270 дней)	student	270	108000	model_estimate	\N	2026-11-10
701	41	Учебный расчёт — 2 месяца (60 дней)	adult	60	51000	model_estimate	\N	2026-11-10
702	41	Учебный расчёт — 3 месяца (90 дней)	adult	90	76500	model_estimate	\N	2026-11-10
703	41	Учебный расчёт — 6 месяцев (180 дней)	adult	180	153000	model_estimate	\N	2026-11-10
704	41	Учебный расчёт — 9 месяцев (270 дней)	adult	270	229500	model_estimate	\N	2026-11-10
705	41	Учебный расчёт — 2 месяца (60 дней)	premium	60	76000	model_estimate	\N	2026-11-10
706	41	Учебный расчёт — 3 месяца (90 дней)	premium	90	114000	model_estimate	\N	2026-11-10
707	41	Учебный расчёт — 6 месяцев (180 дней)	premium	180	228000	model_estimate	\N	2026-11-10
708	41	Учебный расчёт — 9 месяцев (270 дней)	premium	270	342000	model_estimate	\N	2026-11-10
709	41	Учебный расчёт — 2 месяца (60 дней)	student	60	40000	model_estimate	\N	2026-11-10
710	41	Учебный расчёт — 3 месяца (90 дней)	student	90	60000	model_estimate	\N	2026-11-10
711	41	Учебный расчёт — 6 месяцев (180 дней)	student	180	120000	model_estimate	\N	2026-11-10
712	41	Учебный расчёт — 9 месяцев (270 дней)	student	270	180000	model_estimate	\N	2026-11-10
713	42	Учебный расчёт — 2 месяца (60 дней)	adult	60	34000	model_estimate	\N	2026-11-10
714	42	Учебный расчёт — 3 месяца (90 дней)	adult	90	51000	model_estimate	\N	2026-11-10
715	42	Учебный расчёт — 6 месяцев (180 дней)	adult	180	102000	model_estimate	\N	2026-11-10
716	42	Учебный расчёт — 9 месяцев (270 дней)	adult	270	153000	model_estimate	\N	2026-11-10
717	42	Учебный расчёт — 2 месяца (60 дней)	premium	60	52000	model_estimate	\N	2026-11-10
718	42	Учебный расчёт — 3 месяца (90 дней)	premium	90	78000	model_estimate	\N	2026-11-10
719	42	Учебный расчёт — 6 месяцев (180 дней)	premium	180	156000	model_estimate	\N	2026-11-10
720	42	Учебный расчёт — 9 месяцев (270 дней)	premium	270	234000	model_estimate	\N	2026-11-10
721	42	Учебный расчёт — 2 месяца (60 дней)	student	60	27000	model_estimate	\N	2026-11-10
722	42	Учебный расчёт — 3 месяца (90 дней)	student	90	40500	model_estimate	\N	2026-11-10
723	42	Учебный расчёт — 6 месяцев (180 дней)	student	180	81000	model_estimate	\N	2026-11-10
724	42	Учебный расчёт — 9 месяцев (270 дней)	student	270	121500	model_estimate	\N	2026-11-10
725	43	Учебный расчёт — 2 месяца (60 дней)	adult	60	57000	model_estimate	\N	2026-11-10
726	43	Учебный расчёт — 3 месяца (90 дней)	adult	90	85500	model_estimate	\N	2026-11-10
727	43	Учебный расчёт — 6 месяцев (180 дней)	adult	180	171000	model_estimate	\N	2026-11-10
728	43	Учебный расчёт — 9 месяцев (270 дней)	adult	270	256500	model_estimate	\N	2026-11-10
729	43	Учебный расчёт — 2 месяца (60 дней)	premium	60	86000	model_estimate	\N	2026-11-10
730	43	Учебный расчёт — 3 месяца (90 дней)	premium	90	129000	model_estimate	\N	2026-11-10
731	43	Учебный расчёт — 6 месяцев (180 дней)	premium	180	258000	model_estimate	\N	2026-11-10
732	43	Учебный расчёт — 9 месяцев (270 дней)	premium	270	387000	model_estimate	\N	2026-11-10
733	43	Учебный расчёт — 2 месяца (60 дней)	student	60	45000	model_estimate	\N	2026-11-10
734	43	Учебный расчёт — 3 месяца (90 дней)	student	90	67500	model_estimate	\N	2026-11-10
735	43	Учебный расчёт — 6 месяцев (180 дней)	student	180	135000	model_estimate	\N	2026-11-10
736	43	Учебный расчёт — 9 месяцев (270 дней)	student	270	202500	model_estimate	\N	2026-11-10
737	44	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
738	44	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
739	44	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
740	44	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
741	44	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
742	44	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
743	44	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
744	44	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
745	44	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
746	44	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
747	44	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
748	44	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
749	45	Учебный расчёт — 2 месяца (60 дней)	adult	60	48000	model_estimate	\N	2026-11-10
750	45	Учебный расчёт — 3 месяца (90 дней)	adult	90	72000	model_estimate	\N	2026-11-10
751	45	Учебный расчёт — 6 месяцев (180 дней)	adult	180	144000	model_estimate	\N	2026-11-10
752	45	Учебный расчёт — 9 месяцев (270 дней)	adult	270	216000	model_estimate	\N	2026-11-10
753	45	Учебный расчёт — 2 месяца (60 дней)	premium	60	72000	model_estimate	\N	2026-11-10
754	45	Учебный расчёт — 3 месяца (90 дней)	premium	90	108000	model_estimate	\N	2026-11-10
755	45	Учебный расчёт — 6 месяцев (180 дней)	premium	180	216000	model_estimate	\N	2026-11-10
756	45	Учебный расчёт — 9 месяцев (270 дней)	premium	270	324000	model_estimate	\N	2026-11-10
757	45	Учебный расчёт — 2 месяца (60 дней)	student	60	38000	model_estimate	\N	2026-11-10
758	45	Учебный расчёт — 3 месяца (90 дней)	student	90	57000	model_estimate	\N	2026-11-10
759	45	Учебный расчёт — 6 месяцев (180 дней)	student	180	114000	model_estimate	\N	2026-11-10
760	45	Учебный расчёт — 9 месяцев (270 дней)	student	270	171000	model_estimate	\N	2026-11-10
761	46	Учебный расчёт — 2 месяца (60 дней)	adult	60	51000	model_estimate	\N	2026-11-10
762	46	Учебный расчёт — 3 месяца (90 дней)	adult	90	76500	model_estimate	\N	2026-11-10
763	46	Учебный расчёт — 6 месяцев (180 дней)	adult	180	153000	model_estimate	\N	2026-11-10
764	46	Учебный расчёт — 9 месяцев (270 дней)	adult	270	229500	model_estimate	\N	2026-11-10
765	46	Учебный расчёт — 2 месяца (60 дней)	premium	60	76000	model_estimate	\N	2026-11-10
766	46	Учебный расчёт — 3 месяца (90 дней)	premium	90	114000	model_estimate	\N	2026-11-10
767	46	Учебный расчёт — 6 месяцев (180 дней)	premium	180	228000	model_estimate	\N	2026-11-10
768	46	Учебный расчёт — 9 месяцев (270 дней)	premium	270	342000	model_estimate	\N	2026-11-10
769	46	Учебный расчёт — 2 месяца (60 дней)	student	60	40000	model_estimate	\N	2026-11-10
770	46	Учебный расчёт — 3 месяца (90 дней)	student	90	60000	model_estimate	\N	2026-11-10
771	46	Учебный расчёт — 6 месяцев (180 дней)	student	180	120000	model_estimate	\N	2026-11-10
772	46	Учебный расчёт — 9 месяцев (270 дней)	student	270	180000	model_estimate	\N	2026-11-10
773	47	Учебный расчёт — 2 месяца (60 дней)	adult	60	36000	model_estimate	\N	2026-11-10
774	47	Учебный расчёт — 3 месяца (90 дней)	adult	90	54000	model_estimate	\N	2026-11-10
775	47	Учебный расчёт — 6 месяцев (180 дней)	adult	180	108000	model_estimate	\N	2026-11-10
776	47	Учебный расчёт — 9 месяцев (270 дней)	adult	270	162000	model_estimate	\N	2026-11-10
777	47	Учебный расчёт — 2 месяца (60 дней)	premium	60	54000	model_estimate	\N	2026-11-10
778	47	Учебный расчёт — 3 месяца (90 дней)	premium	90	81000	model_estimate	\N	2026-11-10
779	47	Учебный расчёт — 6 месяцев (180 дней)	premium	180	162000	model_estimate	\N	2026-11-10
780	47	Учебный расчёт — 9 месяцев (270 дней)	premium	270	243000	model_estimate	\N	2026-11-10
781	47	Учебный расчёт — 2 месяца (60 дней)	student	60	28000	model_estimate	\N	2026-11-10
782	47	Учебный расчёт — 3 месяца (90 дней)	student	90	42000	model_estimate	\N	2026-11-10
783	47	Учебный расчёт — 6 месяцев (180 дней)	student	180	84000	model_estimate	\N	2026-11-10
784	47	Учебный расчёт — 9 месяцев (270 дней)	student	270	126000	model_estimate	\N	2026-11-10
785	48	Учебный расчёт — 2 месяца (60 дней)	adult	60	30000	model_estimate	\N	2026-11-10
786	48	Учебный расчёт — 3 месяца (90 дней)	adult	90	45000	model_estimate	\N	2026-11-10
787	48	Учебный расчёт — 6 месяцев (180 дней)	adult	180	90000	model_estimate	\N	2026-11-10
788	48	Учебный расчёт — 9 месяцев (270 дней)	adult	270	135000	model_estimate	\N	2026-11-10
789	48	Учебный расчёт — 2 месяца (60 дней)	premium	60	46000	model_estimate	\N	2026-11-10
790	48	Учебный расчёт — 3 месяца (90 дней)	premium	90	69000	model_estimate	\N	2026-11-10
791	48	Учебный расчёт — 6 месяцев (180 дней)	premium	180	138000	model_estimate	\N	2026-11-10
792	48	Учебный расчёт — 9 месяцев (270 дней)	premium	270	207000	model_estimate	\N	2026-11-10
793	48	Учебный расчёт — 2 месяца (60 дней)	student	60	24000	model_estimate	\N	2026-11-10
794	48	Учебный расчёт — 3 месяца (90 дней)	student	90	36000	model_estimate	\N	2026-11-10
795	48	Учебный расчёт — 6 месяцев (180 дней)	student	180	72000	model_estimate	\N	2026-11-10
796	48	Учебный расчёт — 9 месяцев (270 дней)	student	270	108000	model_estimate	\N	2026-11-10
797	49	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
798	49	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
799	49	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
800	49	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
801	49	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
802	49	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
803	49	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
804	49	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
805	49	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
806	49	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
807	49	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
808	49	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
809	50	Учебный расчёт — 2 месяца (60 дней)	adult	60	48000	model_estimate	\N	2026-11-10
810	50	Учебный расчёт — 3 месяца (90 дней)	adult	90	72000	model_estimate	\N	2026-11-10
811	50	Учебный расчёт — 6 месяцев (180 дней)	adult	180	144000	model_estimate	\N	2026-11-10
812	50	Учебный расчёт — 9 месяцев (270 дней)	adult	270	216000	model_estimate	\N	2026-11-10
813	50	Учебный расчёт — 2 месяца (60 дней)	premium	60	72000	model_estimate	\N	2026-11-10
814	50	Учебный расчёт — 3 месяца (90 дней)	premium	90	108000	model_estimate	\N	2026-11-10
815	50	Учебный расчёт — 6 месяцев (180 дней)	premium	180	216000	model_estimate	\N	2026-11-10
816	50	Учебный расчёт — 9 месяцев (270 дней)	premium	270	324000	model_estimate	\N	2026-11-10
817	50	Учебный расчёт — 2 месяца (60 дней)	student	60	38000	model_estimate	\N	2026-11-10
818	50	Учебный расчёт — 3 месяца (90 дней)	student	90	57000	model_estimate	\N	2026-11-10
819	50	Учебный расчёт — 6 месяцев (180 дней)	student	180	114000	model_estimate	\N	2026-11-10
820	50	Учебный расчёт — 9 месяцев (270 дней)	student	270	171000	model_estimate	\N	2026-11-10
821	51	Учебный расчёт — 2 месяца (60 дней)	adult	60	36000	model_estimate	\N	2026-11-10
822	51	Учебный расчёт — 3 месяца (90 дней)	adult	90	54000	model_estimate	\N	2026-11-10
823	51	Учебный расчёт — 6 месяцев (180 дней)	adult	180	108000	model_estimate	\N	2026-11-10
824	51	Учебный расчёт — 9 месяцев (270 дней)	adult	270	162000	model_estimate	\N	2026-11-10
825	51	Учебный расчёт — 2 месяца (60 дней)	premium	60	54000	model_estimate	\N	2026-11-10
826	51	Учебный расчёт — 3 месяца (90 дней)	premium	90	81000	model_estimate	\N	2026-11-10
827	51	Учебный расчёт — 6 месяцев (180 дней)	premium	180	162000	model_estimate	\N	2026-11-10
828	51	Учебный расчёт — 9 месяцев (270 дней)	premium	270	243000	model_estimate	\N	2026-11-10
829	51	Учебный расчёт — 2 месяца (60 дней)	student	60	28000	model_estimate	\N	2026-11-10
830	51	Учебный расчёт — 3 месяца (90 дней)	student	90	42000	model_estimate	\N	2026-11-10
831	51	Учебный расчёт — 6 месяцев (180 дней)	student	180	84000	model_estimate	\N	2026-11-10
832	51	Учебный расчёт — 9 месяцев (270 дней)	student	270	126000	model_estimate	\N	2026-11-10
833	52	Учебный расчёт — 2 месяца (60 дней)	adult	60	54000	model_estimate	\N	2026-11-10
834	52	Учебный расчёт — 3 месяца (90 дней)	adult	90	81000	model_estimate	\N	2026-11-10
835	52	Учебный расчёт — 6 месяцев (180 дней)	adult	180	162000	model_estimate	\N	2026-11-10
836	52	Учебный расчёт — 9 месяцев (270 дней)	adult	270	243000	model_estimate	\N	2026-11-10
837	52	Учебный расчёт — 2 месяца (60 дней)	premium	60	82000	model_estimate	\N	2026-11-10
838	52	Учебный расчёт — 3 месяца (90 дней)	premium	90	123000	model_estimate	\N	2026-11-10
839	52	Учебный расчёт — 6 месяцев (180 дней)	premium	180	246000	model_estimate	\N	2026-11-10
840	52	Учебный расчёт — 9 месяцев (270 дней)	premium	270	369000	model_estimate	\N	2026-11-10
841	52	Учебный расчёт — 2 месяца (60 дней)	student	60	43000	model_estimate	\N	2026-11-10
842	52	Учебный расчёт — 3 месяца (90 дней)	student	90	64500	model_estimate	\N	2026-11-10
843	52	Учебный расчёт — 6 месяцев (180 дней)	student	180	129000	model_estimate	\N	2026-11-10
844	52	Учебный расчёт — 9 месяцев (270 дней)	student	270	193500	model_estimate	\N	2026-11-10
845	53	Учебный расчёт — 2 месяца (60 дней)	adult	60	32000	model_estimate	\N	2026-11-10
846	53	Учебный расчёт — 3 месяца (90 дней)	adult	90	48000	model_estimate	\N	2026-11-10
847	53	Учебный расчёт — 6 месяцев (180 дней)	adult	180	96000	model_estimate	\N	2026-11-10
848	53	Учебный расчёт — 9 месяцев (270 дней)	adult	270	144000	model_estimate	\N	2026-11-10
849	53	Учебный расчёт — 2 месяца (60 дней)	premium	60	48000	model_estimate	\N	2026-11-10
850	53	Учебный расчёт — 3 месяца (90 дней)	premium	90	72000	model_estimate	\N	2026-11-10
851	53	Учебный расчёт — 6 месяцев (180 дней)	premium	180	144000	model_estimate	\N	2026-11-10
852	53	Учебный расчёт — 9 месяцев (270 дней)	premium	270	216000	model_estimate	\N	2026-11-10
853	53	Учебный расчёт — 2 месяца (60 дней)	student	60	25000	model_estimate	\N	2026-11-10
854	53	Учебный расчёт — 3 месяца (90 дней)	student	90	37500	model_estimate	\N	2026-11-10
855	53	Учебный расчёт — 6 месяцев (180 дней)	student	180	75000	model_estimate	\N	2026-11-10
856	53	Учебный расчёт — 9 месяцев (270 дней)	student	270	112500	model_estimate	\N	2026-11-10
857	54	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
858	54	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
859	54	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
860	54	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
861	54	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
862	54	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
863	54	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
864	54	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
865	54	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
866	54	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
867	54	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
868	54	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
869	55	Учебный расчёт — 2 месяца (60 дней)	adult	60	48000	model_estimate	\N	2026-11-10
870	55	Учебный расчёт — 3 месяца (90 дней)	adult	90	72000	model_estimate	\N	2026-11-10
871	55	Учебный расчёт — 6 месяцев (180 дней)	adult	180	144000	model_estimate	\N	2026-11-10
872	55	Учебный расчёт — 9 месяцев (270 дней)	adult	270	216000	model_estimate	\N	2026-11-10
873	55	Учебный расчёт — 2 месяца (60 дней)	premium	60	72000	model_estimate	\N	2026-11-10
874	55	Учебный расчёт — 3 месяца (90 дней)	premium	90	108000	model_estimate	\N	2026-11-10
875	55	Учебный расчёт — 6 месяцев (180 дней)	premium	180	216000	model_estimate	\N	2026-11-10
876	55	Учебный расчёт — 9 месяцев (270 дней)	premium	270	324000	model_estimate	\N	2026-11-10
877	55	Учебный расчёт — 2 месяца (60 дней)	student	60	38000	model_estimate	\N	2026-11-10
878	55	Учебный расчёт — 3 месяца (90 дней)	student	90	57000	model_estimate	\N	2026-11-10
879	55	Учебный расчёт — 6 месяцев (180 дней)	student	180	114000	model_estimate	\N	2026-11-10
880	55	Учебный расчёт — 9 месяцев (270 дней)	student	270	171000	model_estimate	\N	2026-11-10
881	56	Учебный расчёт — 2 месяца (60 дней)	adult	60	30000	model_estimate	\N	2026-11-10
882	56	Учебный расчёт — 3 месяца (90 дней)	adult	90	45000	model_estimate	\N	2026-11-10
883	56	Учебный расчёт — 6 месяцев (180 дней)	adult	180	90000	model_estimate	\N	2026-11-10
884	56	Учебный расчёт — 9 месяцев (270 дней)	adult	270	135000	model_estimate	\N	2026-11-10
885	56	Учебный расчёт — 2 месяца (60 дней)	premium	60	46000	model_estimate	\N	2026-11-10
886	56	Учебный расчёт — 3 месяца (90 дней)	premium	90	69000	model_estimate	\N	2026-11-10
887	56	Учебный расчёт — 6 месяцев (180 дней)	premium	180	138000	model_estimate	\N	2026-11-10
888	56	Учебный расчёт — 9 месяцев (270 дней)	premium	270	207000	model_estimate	\N	2026-11-10
889	56	Учебный расчёт — 2 месяца (60 дней)	student	60	24000	model_estimate	\N	2026-11-10
890	56	Учебный расчёт — 3 месяца (90 дней)	student	90	36000	model_estimate	\N	2026-11-10
891	56	Учебный расчёт — 6 месяцев (180 дней)	student	180	72000	model_estimate	\N	2026-11-10
892	56	Учебный расчёт — 9 месяцев (270 дней)	student	270	108000	model_estimate	\N	2026-11-10
893	57	Учебный расчёт — 2 месяца (60 дней)	adult	60	54000	model_estimate	\N	2026-11-10
894	57	Учебный расчёт — 3 месяца (90 дней)	adult	90	81000	model_estimate	\N	2026-11-10
895	57	Учебный расчёт — 6 месяцев (180 дней)	adult	180	162000	model_estimate	\N	2026-11-10
896	57	Учебный расчёт — 9 месяцев (270 дней)	adult	270	243000	model_estimate	\N	2026-11-10
897	57	Учебный расчёт — 2 месяца (60 дней)	premium	60	82000	model_estimate	\N	2026-11-10
898	57	Учебный расчёт — 3 месяца (90 дней)	premium	90	123000	model_estimate	\N	2026-11-10
899	57	Учебный расчёт — 6 месяцев (180 дней)	premium	180	246000	model_estimate	\N	2026-11-10
900	57	Учебный расчёт — 9 месяцев (270 дней)	premium	270	369000	model_estimate	\N	2026-11-10
901	57	Учебный расчёт — 2 месяца (60 дней)	student	60	43000	model_estimate	\N	2026-11-10
902	57	Учебный расчёт — 3 месяца (90 дней)	student	90	64500	model_estimate	\N	2026-11-10
903	57	Учебный расчёт — 6 месяцев (180 дней)	student	180	129000	model_estimate	\N	2026-11-10
904	57	Учебный расчёт — 9 месяцев (270 дней)	student	270	193500	model_estimate	\N	2026-11-10
905	58	Учебный расчёт — 2 месяца (60 дней)	adult	60	34000	model_estimate	\N	2026-11-10
906	58	Учебный расчёт — 3 месяца (90 дней)	adult	90	51000	model_estimate	\N	2026-11-10
907	58	Учебный расчёт — 6 месяцев (180 дней)	adult	180	102000	model_estimate	\N	2026-11-10
908	58	Учебный расчёт — 9 месяцев (270 дней)	adult	270	153000	model_estimate	\N	2026-11-10
909	58	Учебный расчёт — 2 месяца (60 дней)	premium	60	52000	model_estimate	\N	2026-11-10
910	58	Учебный расчёт — 3 месяца (90 дней)	premium	90	78000	model_estimate	\N	2026-11-10
911	58	Учебный расчёт — 6 месяцев (180 дней)	premium	180	156000	model_estimate	\N	2026-11-10
912	58	Учебный расчёт — 9 месяцев (270 дней)	premium	270	234000	model_estimate	\N	2026-11-10
913	58	Учебный расчёт — 2 месяца (60 дней)	student	60	27000	model_estimate	\N	2026-11-10
914	58	Учебный расчёт — 3 месяца (90 дней)	student	90	40500	model_estimate	\N	2026-11-10
915	58	Учебный расчёт — 6 месяцев (180 дней)	student	180	81000	model_estimate	\N	2026-11-10
916	58	Учебный расчёт — 9 месяцев (270 дней)	student	270	121500	model_estimate	\N	2026-11-10
917	59	Учебный расчёт — 2 месяца (60 дней)	adult	60	60000	model_estimate	\N	2026-11-10
918	59	Учебный расчёт — 3 месяца (90 дней)	adult	90	90000	model_estimate	\N	2026-11-10
919	59	Учебный расчёт — 6 месяцев (180 дней)	adult	180	180000	model_estimate	\N	2026-11-10
920	59	Учебный расчёт — 9 месяцев (270 дней)	adult	270	270000	model_estimate	\N	2026-11-10
921	59	Учебный расчёт — 2 месяца (60 дней)	premium	60	90000	model_estimate	\N	2026-11-10
922	59	Учебный расчёт — 3 месяца (90 дней)	premium	90	135000	model_estimate	\N	2026-11-10
923	59	Учебный расчёт — 6 месяцев (180 дней)	premium	180	270000	model_estimate	\N	2026-11-10
924	59	Учебный расчёт — 9 месяцев (270 дней)	premium	270	405000	model_estimate	\N	2026-11-10
925	59	Учебный расчёт — 2 месяца (60 дней)	student	60	48000	model_estimate	\N	2026-11-10
926	59	Учебный расчёт — 3 месяца (90 дней)	student	90	72000	model_estimate	\N	2026-11-10
927	59	Учебный расчёт — 6 месяцев (180 дней)	student	180	144000	model_estimate	\N	2026-11-10
928	59	Учебный расчёт — 9 месяцев (270 дней)	student	270	216000	model_estimate	\N	2026-11-10
929	60	Учебный расчёт — 2 месяца (60 дней)	adult	60	48000	model_estimate	\N	2026-11-10
930	60	Учебный расчёт — 3 месяца (90 дней)	adult	90	72000	model_estimate	\N	2026-11-10
931	60	Учебный расчёт — 6 месяцев (180 дней)	adult	180	144000	model_estimate	\N	2026-11-10
932	60	Учебный расчёт — 9 месяцев (270 дней)	adult	270	216000	model_estimate	\N	2026-11-10
933	60	Учебный расчёт — 2 месяца (60 дней)	premium	60	72000	model_estimate	\N	2026-11-10
934	60	Учебный расчёт — 3 месяца (90 дней)	premium	90	108000	model_estimate	\N	2026-11-10
935	60	Учебный расчёт — 6 месяцев (180 дней)	premium	180	216000	model_estimate	\N	2026-11-10
936	60	Учебный расчёт — 9 месяцев (270 дней)	premium	270	324000	model_estimate	\N	2026-11-10
937	60	Учебный расчёт — 2 месяца (60 дней)	student	60	38000	model_estimate	\N	2026-11-10
938	60	Учебный расчёт — 3 месяца (90 дней)	student	90	57000	model_estimate	\N	2026-11-10
939	60	Учебный расчёт — 6 месяцев (180 дней)	student	180	114000	model_estimate	\N	2026-11-10
940	60	Учебный расчёт — 9 месяцев (270 дней)	student	270	171000	model_estimate	\N	2026-11-10
941	61	Учебный расчёт — 2 месяца (60 дней)	adult	60	32000	model_estimate	\N	2026-11-10
942	61	Учебный расчёт — 3 месяца (90 дней)	adult	90	48000	model_estimate	\N	2026-11-10
943	61	Учебный расчёт — 6 месяцев (180 дней)	adult	180	96000	model_estimate	\N	2026-11-10
944	61	Учебный расчёт — 9 месяцев (270 дней)	adult	270	144000	model_estimate	\N	2026-11-10
945	61	Учебный расчёт — 2 месяца (60 дней)	premium	60	48000	model_estimate	\N	2026-11-10
946	61	Учебный расчёт — 3 месяца (90 дней)	premium	90	72000	model_estimate	\N	2026-11-10
947	61	Учебный расчёт — 6 месяцев (180 дней)	premium	180	144000	model_estimate	\N	2026-11-10
948	61	Учебный расчёт — 9 месяцев (270 дней)	premium	270	216000	model_estimate	\N	2026-11-10
949	61	Учебный расчёт — 2 месяца (60 дней)	student	60	25000	model_estimate	\N	2026-11-10
950	61	Учебный расчёт — 3 месяца (90 дней)	student	90	37500	model_estimate	\N	2026-11-10
951	61	Учебный расчёт — 6 месяцев (180 дней)	student	180	75000	model_estimate	\N	2026-11-10
952	61	Учебный расчёт — 9 месяцев (270 дней)	student	270	112500	model_estimate	\N	2026-11-10
953	62	Учебный расчёт — 2 месяца (60 дней)	adult	60	34000	model_estimate	\N	2026-11-10
954	62	Учебный расчёт — 3 месяца (90 дней)	adult	90	51000	model_estimate	\N	2026-11-10
955	62	Учебный расчёт — 6 месяцев (180 дней)	adult	180	102000	model_estimate	\N	2026-11-10
956	62	Учебный расчёт — 9 месяцев (270 дней)	adult	270	153000	model_estimate	\N	2026-11-10
957	62	Учебный расчёт — 2 месяца (60 дней)	premium	60	52000	model_estimate	\N	2026-11-10
958	62	Учебный расчёт — 3 месяца (90 дней)	premium	90	78000	model_estimate	\N	2026-11-10
959	62	Учебный расчёт — 6 месяцев (180 дней)	premium	180	156000	model_estimate	\N	2026-11-10
960	62	Учебный расчёт — 9 месяцев (270 дней)	premium	270	234000	model_estimate	\N	2026-11-10
961	62	Учебный расчёт — 2 месяца (60 дней)	student	60	27000	model_estimate	\N	2026-11-10
962	62	Учебный расчёт — 3 месяца (90 дней)	student	90	40500	model_estimate	\N	2026-11-10
963	62	Учебный расчёт — 6 месяцев (180 дней)	student	180	81000	model_estimate	\N	2026-11-10
964	62	Учебный расчёт — 9 месяцев (270 дней)	student	270	121500	model_estimate	\N	2026-11-10
965	63	Учебный расчёт — 2 месяца (60 дней)	adult	60	36000	model_estimate	\N	2026-11-10
966	63	Учебный расчёт — 3 месяца (90 дней)	adult	90	54000	model_estimate	\N	2026-11-10
967	63	Учебный расчёт — 6 месяцев (180 дней)	adult	180	108000	model_estimate	\N	2026-11-10
968	63	Учебный расчёт — 9 месяцев (270 дней)	adult	270	162000	model_estimate	\N	2026-11-10
969	63	Учебный расчёт — 2 месяца (60 дней)	premium	60	54000	model_estimate	\N	2026-11-10
970	63	Учебный расчёт — 3 месяца (90 дней)	premium	90	81000	model_estimate	\N	2026-11-10
971	63	Учебный расчёт — 6 месяцев (180 дней)	premium	180	162000	model_estimate	\N	2026-11-10
972	63	Учебный расчёт — 9 месяцев (270 дней)	premium	270	243000	model_estimate	\N	2026-11-10
973	63	Учебный расчёт — 2 месяца (60 дней)	student	60	28000	model_estimate	\N	2026-11-10
974	63	Учебный расчёт — 3 месяца (90 дней)	student	90	42000	model_estimate	\N	2026-11-10
975	63	Учебный расчёт — 6 месяцев (180 дней)	student	180	84000	model_estimate	\N	2026-11-10
976	63	Учебный расчёт — 9 месяцев (270 дней)	student	270	126000	model_estimate	\N	2026-11-10
977	64	Учебный расчёт — 2 месяца (60 дней)	adult	60	30000	model_estimate	\N	2026-11-10
978	64	Учебный расчёт — 3 месяца (90 дней)	adult	90	45000	model_estimate	\N	2026-11-10
979	64	Учебный расчёт — 6 месяцев (180 дней)	adult	180	90000	model_estimate	\N	2026-11-10
980	64	Учебный расчёт — 9 месяцев (270 дней)	adult	270	135000	model_estimate	\N	2026-11-10
981	64	Учебный расчёт — 2 месяца (60 дней)	premium	60	46000	model_estimate	\N	2026-11-10
982	64	Учебный расчёт — 3 месяца (90 дней)	premium	90	69000	model_estimate	\N	2026-11-10
983	64	Учебный расчёт — 6 месяцев (180 дней)	premium	180	138000	model_estimate	\N	2026-11-10
984	64	Учебный расчёт — 9 месяцев (270 дней)	premium	270	207000	model_estimate	\N	2026-11-10
985	64	Учебный расчёт — 2 месяца (60 дней)	student	60	24000	model_estimate	\N	2026-11-10
986	64	Учебный расчёт — 3 месяца (90 дней)	student	90	36000	model_estimate	\N	2026-11-10
987	64	Учебный расчёт — 6 месяцев (180 дней)	student	180	72000	model_estimate	\N	2026-11-10
988	64	Учебный расчёт — 9 месяцев (270 дней)	student	270	108000	model_estimate	\N	2026-11-10
989	65	Учебный расчёт — 2 месяца (60 дней)	adult	60	32000	model_estimate	\N	2026-11-10
990	65	Учебный расчёт — 3 месяца (90 дней)	adult	90	48000	model_estimate	\N	2026-11-10
991	65	Учебный расчёт — 6 месяцев (180 дней)	adult	180	96000	model_estimate	\N	2026-11-10
992	65	Учебный расчёт — 9 месяцев (270 дней)	adult	270	144000	model_estimate	\N	2026-11-10
993	65	Учебный расчёт — 2 месяца (60 дней)	premium	60	48000	model_estimate	\N	2026-11-10
994	65	Учебный расчёт — 3 месяца (90 дней)	premium	90	72000	model_estimate	\N	2026-11-10
995	65	Учебный расчёт — 6 месяцев (180 дней)	premium	180	144000	model_estimate	\N	2026-11-10
996	65	Учебный расчёт — 9 месяцев (270 дней)	premium	270	216000	model_estimate	\N	2026-11-10
997	65	Учебный расчёт — 2 месяца (60 дней)	student	60	25000	model_estimate	\N	2026-11-10
998	65	Учебный расчёт — 3 месяца (90 дней)	student	90	37500	model_estimate	\N	2026-11-10
999	65	Учебный расчёт — 6 месяцев (180 дней)	student	180	75000	model_estimate	\N	2026-11-10
1000	65	Учебный расчёт — 9 месяцев (270 дней)	student	270	112500	model_estimate	\N	2026-11-10
1001	66	Учебный расчёт — 2 месяца (60 дней)	adult	60	34000	model_estimate	\N	2026-11-10
1002	66	Учебный расчёт — 3 месяца (90 дней)	adult	90	51000	model_estimate	\N	2026-11-10
1003	66	Учебный расчёт — 6 месяцев (180 дней)	adult	180	102000	model_estimate	\N	2026-11-10
1004	66	Учебный расчёт — 9 месяцев (270 дней)	adult	270	153000	model_estimate	\N	2026-11-10
1005	66	Учебный расчёт — 2 месяца (60 дней)	premium	60	52000	model_estimate	\N	2026-11-10
1006	66	Учебный расчёт — 3 месяца (90 дней)	premium	90	78000	model_estimate	\N	2026-11-10
1007	66	Учебный расчёт — 6 месяцев (180 дней)	premium	180	156000	model_estimate	\N	2026-11-10
1008	66	Учебный расчёт — 9 месяцев (270 дней)	premium	270	234000	model_estimate	\N	2026-11-10
1009	66	Учебный расчёт — 2 месяца (60 дней)	student	60	27000	model_estimate	\N	2026-11-10
1010	66	Учебный расчёт — 3 месяца (90 дней)	student	90	40500	model_estimate	\N	2026-11-10
1011	66	Учебный расчёт — 6 месяцев (180 дней)	student	180	81000	model_estimate	\N	2026-11-10
1012	66	Учебный расчёт — 9 месяцев (270 дней)	student	270	121500	model_estimate	\N	2026-11-10
1013	67	Учебный расчёт — 2 месяца (60 дней)	adult	60	36000	model_estimate	\N	2026-11-10
1014	67	Учебный расчёт — 3 месяца (90 дней)	adult	90	54000	model_estimate	\N	2026-11-10
1015	67	Учебный расчёт — 6 месяцев (180 дней)	adult	180	108000	model_estimate	\N	2026-11-10
1016	67	Учебный расчёт — 9 месяцев (270 дней)	adult	270	162000	model_estimate	\N	2026-11-10
1017	67	Учебный расчёт — 2 месяца (60 дней)	premium	60	54000	model_estimate	\N	2026-11-10
1018	67	Учебный расчёт — 3 месяца (90 дней)	premium	90	81000	model_estimate	\N	2026-11-10
1019	67	Учебный расчёт — 6 месяцев (180 дней)	premium	180	162000	model_estimate	\N	2026-11-10
1020	67	Учебный расчёт — 9 месяцев (270 дней)	premium	270	243000	model_estimate	\N	2026-11-10
1021	67	Учебный расчёт — 2 месяца (60 дней)	student	60	28000	model_estimate	\N	2026-11-10
1022	67	Учебный расчёт — 3 месяца (90 дней)	student	90	42000	model_estimate	\N	2026-11-10
1023	67	Учебный расчёт — 6 месяцев (180 дней)	student	180	84000	model_estimate	\N	2026-11-10
1024	67	Учебный расчёт — 9 месяцев (270 дней)	student	270	126000	model_estimate	\N	2026-11-10
1025	68	Учебный расчёт — 2 месяца (60 дней)	adult	60	98000	model_estimate	\N	2026-11-10
1026	68	Учебный расчёт — 3 месяца (90 дней)	adult	90	147000	model_estimate	\N	2026-11-10
1027	68	Учебный расчёт — 6 месяцев (180 дней)	adult	180	294000	model_estimate	\N	2026-11-10
1028	68	Учебный расчёт — 9 месяцев (270 дней)	adult	270	441000	model_estimate	\N	2026-11-10
1029	68	Учебный расчёт — 2 месяца (60 дней)	premium	60	148000	model_estimate	\N	2026-11-10
1030	68	Учебный расчёт — 3 месяца (90 дней)	premium	90	222000	model_estimate	\N	2026-11-10
1031	68	Учебный расчёт — 6 месяцев (180 дней)	premium	180	444000	model_estimate	\N	2026-11-10
1032	68	Учебный расчёт — 9 месяцев (270 дней)	premium	270	666000	model_estimate	\N	2026-11-10
1033	68	Учебный расчёт — 2 месяца (60 дней)	student	60	78000	model_estimate	\N	2026-11-10
1034	68	Учебный расчёт — 3 месяца (90 дней)	student	90	117000	model_estimate	\N	2026-11-10
1035	68	Учебный расчёт — 6 месяцев (180 дней)	student	180	234000	model_estimate	\N	2026-11-10
1036	68	Учебный расчёт — 9 месяцев (270 дней)	student	270	351000	model_estimate	\N	2026-11-10
1037	69	Учебный расчёт — 2 месяца (60 дней)	adult	60	32000	model_estimate	\N	2026-11-10
1038	69	Учебный расчёт — 3 месяца (90 дней)	adult	90	48000	model_estimate	\N	2026-11-10
1039	69	Учебный расчёт — 6 месяцев (180 дней)	adult	180	96000	model_estimate	\N	2026-11-10
1040	69	Учебный расчёт — 9 месяцев (270 дней)	adult	270	144000	model_estimate	\N	2026-11-10
1041	69	Учебный расчёт — 2 месяца (60 дней)	premium	60	48000	model_estimate	\N	2026-11-10
1042	69	Учебный расчёт — 3 месяца (90 дней)	premium	90	72000	model_estimate	\N	2026-11-10
1043	69	Учебный расчёт — 6 месяцев (180 дней)	premium	180	144000	model_estimate	\N	2026-11-10
1044	69	Учебный расчёт — 9 месяцев (270 дней)	premium	270	216000	model_estimate	\N	2026-11-10
1045	69	Учебный расчёт — 2 месяца (60 дней)	student	60	25000	model_estimate	\N	2026-11-10
1046	69	Учебный расчёт — 3 месяца (90 дней)	student	90	37500	model_estimate	\N	2026-11-10
1047	69	Учебный расчёт — 6 месяцев (180 дней)	student	180	75000	model_estimate	\N	2026-11-10
1048	69	Учебный расчёт — 9 месяцев (270 дней)	student	270	112500	model_estimate	\N	2026-11-10
1049	70	Учебный расчёт — 2 месяца (60 дней)	adult	60	80000	model_estimate	\N	2026-11-10
1050	70	Учебный расчёт — 3 месяца (90 дней)	adult	90	120000	model_estimate	\N	2026-11-10
1051	70	Учебный расчёт — 6 месяцев (180 дней)	adult	180	240000	model_estimate	\N	2026-11-10
1052	70	Учебный расчёт — 9 месяцев (270 дней)	adult	270	360000	model_estimate	\N	2026-11-10
1053	70	Учебный расчёт — 2 месяца (60 дней)	premium	60	120000	model_estimate	\N	2026-11-10
1054	70	Учебный расчёт — 3 месяца (90 дней)	premium	90	180000	model_estimate	\N	2026-11-10
1055	70	Учебный расчёт — 6 месяцев (180 дней)	premium	180	360000	model_estimate	\N	2026-11-10
1056	70	Учебный расчёт — 9 месяцев (270 дней)	premium	270	540000	model_estimate	\N	2026-11-10
1057	70	Учебный расчёт — 2 месяца (60 дней)	student	60	64000	model_estimate	\N	2026-11-10
1058	70	Учебный расчёт — 3 месяца (90 дней)	student	90	96000	model_estimate	\N	2026-11-10
1059	70	Учебный расчёт — 6 месяцев (180 дней)	student	180	192000	model_estimate	\N	2026-11-10
1060	70	Учебный расчёт — 9 месяцев (270 дней)	student	270	288000	model_estimate	\N	2026-11-10
211	61	Годовой тариф по каталогу Invictus	adult	365	219000	published	https://invictus.kz/ru-kz/clubs/go/go-abay	2026-11-09
212	62	Годовой тариф по каталогу Invictus	adult	365	219000	published	https://invictus.kz/ru-kz/clubs/go/go-aport-east	2026-11-09
213	63	Годовой тариф по каталогу Invictus	adult	365	219000	published	https://invictus.kz/ru-kz/clubs/go/go-aqsay	2026-11-09
214	64	Годовой тариф по каталогу Invictus	adult	365	219000	published	https://invictus.kz/ru-kz/clubs/go/go-arena	2026-11-09
215	65	Годовой тариф по каталогу Invictus	adult	365	219000	published	https://invictus.kz/ru-kz/clubs/go/go-askarova	2026-11-09
216	66	Годовой тариф по каталогу Invictus	adult	365	219000	published	https://invictus.kz/ru-kz/clubs/go/go-atakent	2026-11-09
217	67	Годовой тариф по каталогу Invictus	adult	365	219000	published	https://invictus.kz/ru-kz/clubs/go/go-baitursynov	2026-11-09
218	68	Годовой тариф по каталогу Invictus	adult	365	240000	published	https://invictus.kz/ru-kz/clubs/girls/girls-crystal	2026-11-09
219	69	Годовой тариф по каталогу Invictus	adult	365	219000	published	https://invictus.kz/ru-kz/clubs/go/go-fifty-four	2026-11-09
220	70	Годовой тариф по каталогу Invictus	adult	365	252000	published	https://invictus.kz/ru-kz/clubs/fitness/fitness-gagarin	2026-11-10
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.reviews (id, client_id, gym_id, rating, comment, is_demo) FROM stdin;
1	2	1	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
2	5	2	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
3	8	3	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
4	11	4	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
5	14	5	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
6	17	6	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
7	20	7	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
8	23	8	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
9	26	9	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
10	29	10	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
11	32	11	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
12	35	12	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
13	38	13	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
14	41	14	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
15	44	15	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
16	47	16	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
17	50	17	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
18	53	18	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
19	56	19	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
20	59	20	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
21	62	21	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
22	65	22	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
23	68	23	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
24	71	24	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
25	74	25	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
26	77	26	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
27	80	27	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
28	83	28	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
29	86	29	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
30	89	30	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
31	92	31	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
32	95	32	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
33	98	33	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
34	101	34	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
35	104	35	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
36	107	36	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
37	110	37	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
38	113	38	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
39	116	39	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
40	119	40	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
41	122	41	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
42	125	42	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
43	128	43	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
44	131	44	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
45	134	45	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
46	137	46	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
47	140	47	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
48	143	48	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
49	146	49	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
50	149	50	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
51	152	51	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
52	155	52	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
53	158	53	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
54	161	54	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
55	164	55	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
56	167	56	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
57	170	57	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
58	173	58	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
59	176	59	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
60	179	60	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
61	182	61	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
62	185	62	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
63	188	63	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
64	191	64	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
65	194	65	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
66	197	66	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
67	200	67	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
68	203	68	5	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
69	206	69	3	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
70	209	70	4	Учебный отзыв для проверки SQL; не является отзывом посетителя.	t
\.


--
-- Data for Name: trainers; Type: TABLE DATA; Schema: almaty_gym; Owner: -
--

COPY almaty_gym.trainers (id, gym_id, full_name, specialty, is_demo) FROM stdin;
1	1	Учебный тренер 01	Функциональный тренинг	t
2	2	Учебный тренер 02	Силовой тренинг	t
3	3	Учебный тренер 03	Функциональный тренинг	t
4	4	Учебный тренер 04	Силовой тренинг	t
5	5	Учебный тренер 05	Функциональный тренинг	t
6	6	Учебный тренер 06	Силовой тренинг	t
7	7	Учебный тренер 07	Функциональный тренинг	t
8	8	Учебный тренер 08	Силовой тренинг	t
9	9	Учебный тренер 09	Функциональный тренинг	t
10	10	Учебный тренер 10	Силовой тренинг	t
11	11	Учебный тренер 11	Функциональный тренинг	t
12	12	Учебный тренер 12	Силовой тренинг	t
13	13	Учебный тренер 13	Функциональный тренинг	t
14	14	Учебный тренер 14	Силовой тренинг	t
15	15	Учебный тренер 15	Функциональный тренинг	t
16	16	Учебный тренер 16	Силовой тренинг	t
17	17	Учебный тренер 17	Функциональный тренинг	t
18	18	Учебный тренер 18	Силовой тренинг	t
19	19	Учебный тренер 19	Функциональный тренинг	t
20	20	Учебный тренер 20	Силовой тренинг	t
21	21	Учебный тренер 21	Функциональный тренинг	t
22	22	Учебный тренер 22	Силовой тренинг	t
23	23	Учебный тренер 23	Функциональный тренинг	t
24	24	Учебный тренер 24	Силовой тренинг	t
25	25	Учебный тренер 25	Функциональный тренинг	t
26	26	Учебный тренер 26	Силовой тренинг	t
27	27	Учебный тренер 27	Функциональный тренинг	t
28	28	Учебный тренер 28	Силовой тренинг	t
29	29	Учебный тренер 29	Функциональный тренинг	t
30	30	Учебный тренер 30	Силовой тренинг	t
31	31	Учебный тренер 31	Функциональный тренинг	t
32	32	Учебный тренер 32	Силовой тренинг	t
33	33	Учебный тренер 33	Функциональный тренинг	t
34	34	Учебный тренер 34	Силовой тренинг	t
35	35	Учебный тренер 35	Функциональный тренинг	t
36	36	Учебный тренер 36	Силовой тренинг	t
37	37	Учебный тренер 37	Функциональный тренинг	t
38	38	Учебный тренер 38	Силовой тренинг	t
39	39	Учебный тренер 39	Функциональный тренинг	t
40	40	Учебный тренер 40	Силовой тренинг	t
41	41	Учебный тренер 41	Функциональный тренинг	t
42	42	Учебный тренер 42	Силовой тренинг	t
43	43	Учебный тренер 43	Функциональный тренинг	t
44	44	Учебный тренер 44	Силовой тренинг	t
45	45	Учебный тренер 45	Функциональный тренинг	t
46	46	Учебный тренер 46	Силовой тренинг	t
47	47	Учебный тренер 47	Функциональный тренинг	t
48	48	Учебный тренер 48	Силовой тренинг	t
49	49	Учебный тренер 49	Функциональный тренинг	t
50	50	Учебный тренер 50	Силовой тренинг	t
51	51	Учебный тренер 51	Функциональный тренинг	t
52	52	Учебный тренер 52	Силовой тренинг	t
53	53	Учебный тренер 53	Функциональный тренинг	t
54	54	Учебный тренер 54	Силовой тренинг	t
55	55	Учебный тренер 55	Функциональный тренинг	t
56	56	Учебный тренер 56	Силовой тренинг	t
57	57	Учебный тренер 57	Функциональный тренинг	t
58	58	Учебный тренер 58	Силовой тренинг	t
59	59	Учебный тренер 59	Функциональный тренинг	t
60	60	Учебный тренер 60	Силовой тренинг	t
61	61	Учебный тренер 61	Функциональный тренинг	t
62	62	Учебный тренер 62	Силовой тренинг	t
63	63	Учебный тренер 63	Функциональный тренинг	t
64	64	Учебный тренер 64	Силовой тренинг	t
65	65	Учебный тренер 65	Функциональный тренинг	t
66	66	Учебный тренер 66	Силовой тренинг	t
67	67	Учебный тренер 67	Функциональный тренинг	t
68	68	Учебный тренер 68	Силовой тренинг	t
69	69	Учебный тренер 69	Функциональный тренинг	t
70	70	Учебный тренер 70	Силовой тренинг	t
\.


--
-- Name: bookings_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.bookings_id_seq', 140, true);


--
-- Name: classes_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.classes_id_seq', 140, true);


--
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.clients_id_seq', 211, true);


--
-- Name: gyms_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.gyms_id_seq', 71, true);


--
-- Name: memberships_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.memberships_id_seq', 210, true);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.payments_id_seq', 210, true);


--
-- Name: plans_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.plans_id_seq', 1060, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.reviews_id_seq', 70, true);


--
-- Name: trainers_id_seq; Type: SEQUENCE SET; Schema: almaty_gym; Owner: -
--

SELECT pg_catalog.setval('almaty_gym.trainers_id_seq', 70, true);


--
-- Name: bookings bookings_client_id_class_id_booked_for_key; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.bookings
    ADD CONSTRAINT bookings_client_id_class_id_booked_for_key UNIQUE (client_id, class_id, booked_for);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: classes classes_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id);


--
-- Name: clients clients_email_key; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.clients
    ADD CONSTRAINT clients_email_key UNIQUE (email);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: gym_amenities gym_amenities_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.gym_amenities
    ADD CONSTRAINT gym_amenities_pkey PRIMARY KEY (gym_id, amenity_code);


--
-- Name: gyms gyms_name_address_key; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.gyms
    ADD CONSTRAINT gyms_name_address_key UNIQUE (name, address);


--
-- Name: gyms gyms_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.gyms
    ADD CONSTRAINT gyms_pkey PRIMARY KEY (id);


--
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: plans plans_gym_id_audience_duration_days_key; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.plans
    ADD CONSTRAINT plans_gym_id_audience_duration_days_key UNIQUE (gym_id, audience, duration_days);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_client_id_gym_id_key; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.reviews
    ADD CONSTRAINT reviews_client_id_gym_id_key UNIQUE (client_id, gym_id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: trainers trainers_id_gym_id_key; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.trainers
    ADD CONSTRAINT trainers_id_gym_id_key UNIQUE (id, gym_id);


--
-- Name: trainers trainers_pkey; Type: CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.trainers
    ADD CONSTRAINT trainers_pkey PRIMARY KEY (id);


--
-- Name: idx_bookings_class; Type: INDEX; Schema: almaty_gym; Owner: -
--

CREATE INDEX idx_bookings_class ON almaty_gym.bookings USING btree (class_id);


--
-- Name: idx_classes_gym; Type: INDEX; Schema: almaty_gym; Owner: -
--

CREATE INDEX idx_classes_gym ON almaty_gym.classes USING btree (gym_id);


--
-- Name: idx_gyms_zone_band; Type: INDEX; Schema: almaty_gym; Owner: -
--

CREATE INDEX idx_gyms_zone_band ON almaty_gym.gyms USING btree (city_zone, price_band);


--
-- Name: idx_memberships_plan; Type: INDEX; Schema: almaty_gym; Owner: -
--

CREATE INDEX idx_memberships_plan ON almaty_gym.memberships USING btree (plan_id);


--
-- Name: idx_plans_audience_price; Type: INDEX; Schema: almaty_gym; Owner: -
--

CREATE INDEX idx_plans_audience_price ON almaty_gym.plans USING btree (audience, price_kzt);


--
-- Name: idx_plans_gym; Type: INDEX; Schema: almaty_gym; Owner: -
--

CREATE INDEX idx_plans_gym ON almaty_gym.plans USING btree (gym_id);


--
-- Name: idx_reviews_gym; Type: INDEX; Schema: almaty_gym; Owner: -
--

CREATE INDEX idx_reviews_gym ON almaty_gym.reviews USING btree (gym_id);


--
-- Name: v_gym_prices _RETURN; Type: RULE; Schema: almaty_gym; Owner: -
--

CREATE OR REPLACE VIEW almaty_gym.v_gym_prices AS
 SELECT g.id AS gym_id,
    g.name,
    g.address,
    g.city_zone,
    g.price_band,
    g.latitude,
    g.longitude,
    g.geo_accuracy_m,
    min(p.price_kzt) FILTER (WHERE ((p.audience = 'student'::text) AND (p.duration_days = 30))) AS student_month_kzt,
    min(p.price_kzt) FILTER (WHERE ((p.audience = 'adult'::text) AND (p.duration_days = 30))) AS adult_month_kzt,
    min(p.price_kzt) FILTER (WHERE ((p.audience = 'premium'::text) AND (p.duration_days = 30))) AS premium_month_kzt,
    count(*) FILTER (WHERE (p.price_basis = 'published'::text)) AS published_plan_count
   FROM (almaty_gym.gyms g
     LEFT JOIN almaty_gym.plans p ON ((p.gym_id = g.id)))
  GROUP BY g.id;


--
-- Name: bookings bookings_class_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.bookings
    ADD CONSTRAINT bookings_class_id_fkey FOREIGN KEY (class_id) REFERENCES almaty_gym.classes(id) ON DELETE CASCADE;


--
-- Name: bookings bookings_client_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.bookings
    ADD CONSTRAINT bookings_client_id_fkey FOREIGN KEY (client_id) REFERENCES almaty_gym.clients(id) ON DELETE CASCADE;


--
-- Name: classes classes_gym_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.classes
    ADD CONSTRAINT classes_gym_id_fkey FOREIGN KEY (gym_id) REFERENCES almaty_gym.gyms(id) ON DELETE CASCADE;


--
-- Name: classes classes_trainer_id_gym_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.classes
    ADD CONSTRAINT classes_trainer_id_gym_id_fkey FOREIGN KEY (trainer_id, gym_id) REFERENCES almaty_gym.trainers(id, gym_id);


--
-- Name: gym_amenities gym_amenities_gym_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.gym_amenities
    ADD CONSTRAINT gym_amenities_gym_id_fkey FOREIGN KEY (gym_id) REFERENCES almaty_gym.gyms(id) ON DELETE CASCADE;


--
-- Name: memberships memberships_client_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.memberships
    ADD CONSTRAINT memberships_client_id_fkey FOREIGN KEY (client_id) REFERENCES almaty_gym.clients(id) ON DELETE CASCADE;


--
-- Name: memberships memberships_plan_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.memberships
    ADD CONSTRAINT memberships_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES almaty_gym.plans(id) ON DELETE RESTRICT;


--
-- Name: payments payments_membership_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.payments
    ADD CONSTRAINT payments_membership_id_fkey FOREIGN KEY (membership_id) REFERENCES almaty_gym.memberships(id) ON DELETE CASCADE;


--
-- Name: plans plans_gym_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.plans
    ADD CONSTRAINT plans_gym_id_fkey FOREIGN KEY (gym_id) REFERENCES almaty_gym.gyms(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_client_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.reviews
    ADD CONSTRAINT reviews_client_id_fkey FOREIGN KEY (client_id) REFERENCES almaty_gym.clients(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_gym_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.reviews
    ADD CONSTRAINT reviews_gym_id_fkey FOREIGN KEY (gym_id) REFERENCES almaty_gym.gyms(id) ON DELETE CASCADE;


--
-- Name: trainers trainers_gym_id_fkey; Type: FK CONSTRAINT; Schema: almaty_gym; Owner: -
--

ALTER TABLE ONLY almaty_gym.trainers
    ADD CONSTRAINT trainers_gym_id_fkey FOREIGN KEY (gym_id) REFERENCES almaty_gym.gyms(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict u0nS2xFqOFeXPsoKbRjTGGrF8IxjXkvzthfoaOGfDZezKbmhxNmXoAXm9DW2Fbo

