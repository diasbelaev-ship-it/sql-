-- Сервисные таблицы сайта находятся отдельно от 10 таблиц SQL-кейса.
CREATE SCHEMA IF NOT EXISTS gym_web;
CREATE TABLE IF NOT EXISTS gym_web.accounts (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 name text NOT NULL, email text UNIQUE NOT NULL, password_hash text NOT NULL
);
CREATE TABLE IF NOT EXISTS gym_web.sessions (
 token_hash text PRIMARY KEY, account_id bigint NOT NULL REFERENCES gym_web.accounts ON DELETE CASCADE,
 expires_at timestamptz NOT NULL
);
CREATE TABLE IF NOT EXISTS gym_web.favorites (
 account_id bigint REFERENCES gym_web.accounts ON DELETE CASCADE,
 gym_id bigint REFERENCES almaty_gym.gyms ON DELETE CASCADE, PRIMARY KEY(account_id,gym_id)
);
CREATE TABLE IF NOT EXISTS gym_web.reviews (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 account_id bigint NOT NULL REFERENCES gym_web.accounts ON DELETE CASCADE,
 gym_id bigint NOT NULL REFERENCES almaty_gym.gyms ON DELETE CASCADE,
 rating smallint NOT NULL CHECK(rating BETWEEN 1 AND 5), content text NOT NULL CHECK(length(content) BETWEEN 3 AND 2000),
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(account_id,gym_id)
);
CREATE TABLE IF NOT EXISTS gym_web.chats (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), owner_hash text NOT NULL,
 filters jsonb NOT NULL DEFAULT '{}', results bigint[] NOT NULL DEFAULT '{}',
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS gym_web.messages (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 chat_id uuid NOT NULL REFERENCES gym_web.chats ON DELETE CASCADE,
 role text NOT NULL CHECK(role IN ('user','assistant')), content text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_web_sessions_account ON gym_web.sessions(account_id);
CREATE INDEX IF NOT EXISTS idx_web_favorites_gym ON gym_web.favorites(gym_id);
CREATE INDEX IF NOT EXISTS idx_web_reviews_gym ON gym_web.reviews(gym_id);
CREATE INDEX IF NOT EXISTS idx_web_messages_chat ON gym_web.messages(chat_id);
