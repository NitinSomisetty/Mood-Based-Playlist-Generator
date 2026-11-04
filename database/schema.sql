-- Phase 4 DDL for the existing Supabase PostgreSQL schema.
-- Run against the project database after 001_enable_extensions.sql.
-- This script is idempotent and does not drop existing project tables.

CREATE EXTENSION IF NOT EXISTS vector;

-- Application users are intentionally named app_users because `users` may
-- already be owned by Supabase or another installed integration.
CREATE TABLE IF NOT EXISTS app_users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role VARCHAR(10) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT app_users_role_check CHECK (role IN ('USER', 'ADMIN'))
);

CREATE TABLE IF NOT EXISTS moods (
    mood_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mood_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    embedding VECTOR(384),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS songs (
    song_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL,
    lyrics TEXT,
    description TEXT,
    duration INTEGER CHECK (duration IS NULL OR duration > 0),
    embedding VECTOR(384),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS song_moods (
    song_id BIGINT NOT NULL REFERENCES songs(song_id) ON DELETE CASCADE,
    mood_id BIGINT NOT NULL REFERENCES moods(mood_id) ON DELETE CASCADE,
    relevance_score NUMERIC(4,3)
        CHECK (relevance_score IS NULL OR relevance_score BETWEEN 0 AND 1),
    PRIMARY KEY (song_id, mood_id)
);

CREATE TABLE IF NOT EXISTS playlists (
    playlist_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(user_id) ON DELETE CASCADE,
    mood_id BIGINT NOT NULL REFERENCES moods(mood_id),
    title VARCHAR(150) NOT NULL,
    description TEXT,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS playlist_songs (
    playlist_id BIGINT NOT NULL REFERENCES playlists(playlist_id) ON DELETE CASCADE,
    song_id BIGINT NOT NULL REFERENCES songs(song_id) ON DELETE CASCADE,
    position INTEGER NOT NULL CHECK (position > 0),
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (playlist_id, song_id),
    UNIQUE (playlist_id, position)
);

CREATE TABLE IF NOT EXISTS user_mood_history (
    history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(user_id) ON DELETE CASCADE,
    mood_id BIGINT NOT NULL REFERENCES moods(mood_id),
    input_text TEXT,
    confidence_score NUMERIC(4,3)
        CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1),
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mood_stats (
    mood_stat_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mood_id BIGINT NOT NULL REFERENCES moods(mood_id) ON DELETE CASCADE,
    stat_date DATE NOT NULL DEFAULT CURRENT_DATE,
    generated_count INTEGER NOT NULL DEFAULT 0 CHECK (generated_count >= 0),
    saved_count INTEGER NOT NULL DEFAULT 0
        CHECK (saved_count >= 0 AND saved_count <= generated_count),
    UNIQUE (mood_id, stat_date)
);

-- Schema adjustments retained from the existing Supabase database.
ALTER TABLE app_users
    ADD COLUMN IF NOT EXISTS role VARCHAR(10);

UPDATE app_users
SET role = 'USER'
WHERE role IS NULL;

ALTER TABLE app_users
    ALTER COLUMN role SET DEFAULT 'USER',
    ALTER COLUMN role SET NOT NULL;

ALTER TABLE playlists
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

UPDATE playlists
SET updated_at = created_at
WHERE updated_at IS NULL;

ALTER TABLE playlists
    ALTER COLUMN updated_at SET DEFAULT NOW(),
    ALTER COLUMN updated_at SET NOT NULL;

ALTER TABLE playlist_songs
    ADD COLUMN IF NOT EXISTS position INTEGER;

WITH numbered AS (
    SELECT
        playlist_id,
        song_id,
        ROW_NUMBER() OVER (
            PARTITION BY playlist_id
            ORDER BY added_at, song_id
        ) AS new_position
    FROM playlist_songs
)
UPDATE playlist_songs AS ps
SET position = numbered.new_position
FROM numbered
WHERE ps.playlist_id = numbered.playlist_id
  AND ps.song_id = numbered.song_id
  AND ps.position IS NULL;

ALTER TABLE playlist_songs
    ALTER COLUMN position SET NOT NULL;

-- Named constraints make the required domain rules explicit for existing
-- tables while the catalog checks prevent duplicate additions on reruns.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'app_users_role_check'
          AND conrelid = 'app_users'::regclass
    ) THEN
        ALTER TABLE app_users
            ADD CONSTRAINT app_users_role_check
            CHECK (role IN ('USER', 'ADMIN'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'songs_duration_check'
          AND conrelid = 'songs'::regclass
    ) THEN
        ALTER TABLE songs
            ADD CONSTRAINT songs_duration_check
            CHECK (duration IS NULL OR duration > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'playlist_songs_position_check'
          AND conrelid = 'playlist_songs'::regclass
    ) THEN
        ALTER TABLE playlist_songs
            ADD CONSTRAINT playlist_songs_position_check
            CHECK (position > 0);
    END IF;
END;
$$;

-- ALTER demonstration: language is retained as a useful song attribute.
ALTER TABLE songs
    ADD COLUMN IF NOT EXISTS language VARCHAR(50);

-- Relational indexes. Vector indexes remain in 004_create_indexes.sql and
-- should be created after embeddings and the vector-search workload exist.
CREATE INDEX IF NOT EXISTS idx_songs_artist
    ON songs (artist);

CREATE INDEX IF NOT EXISTS idx_song_moods_mood
    ON song_moods (mood_id);

CREATE INDEX IF NOT EXISTS idx_playlists_user
    ON playlists (user_id);

CREATE INDEX IF NOT EXISTS idx_playlists_mood
    ON playlists (mood_id);

CREATE INDEX IF NOT EXISTS idx_playlist_songs_song
    ON playlist_songs (song_id);

CREATE INDEX IF NOT EXISTS idx_user_mood_history_user
    ON user_mood_history (user_id);

CREATE INDEX IF NOT EXISTS idx_user_mood_history_detected
    ON user_mood_history (detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_mood_stats_mood_date
    ON mood_stats (mood_id, stat_date DESC);

-- DROP demonstration uses only a temporary object.
CREATE TEMPORARY TABLE IF NOT EXISTS ddl_drop_demo (demo_id INTEGER);
DROP TABLE IF EXISTS ddl_drop_demo;
