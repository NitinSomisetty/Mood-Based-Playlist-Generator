-- Core table definitions for a fresh database.
-- Existing Supabase tables are not modified by CREATE TABLE IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS app_users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
