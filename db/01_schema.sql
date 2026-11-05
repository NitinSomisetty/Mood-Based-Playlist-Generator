-- Mood-Based Playlist Generator: complete PostgreSQL DDL.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;
DO $$ BEGIN CREATE TYPE user_role AS ENUM ('USER','ADMIN'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE TABLE IF NOT EXISTS users(user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),username VARCHAR(50) UNIQUE NOT NULL,email VARCHAR(100) UNIQUE NOT NULL,password_hash TEXT NOT NULL,role user_role NOT NULL DEFAULT 'USER',created_at TIMESTAMPTZ NOT NULL DEFAULT now(),updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS moods(mood_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),mood_name VARCHAR(100) UNIQUE NOT NULL,description TEXT NOT NULL,embedding vector(384) NOT NULL,created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS songs(song_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),title VARCHAR(255) NOT NULL,artist VARCHAR(255) NOT NULL,album VARCHAR(255),lyrics TEXT,description TEXT,duration_seconds INT NOT NULL CHECK(duration_seconds>0),embedding vector(384),created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS playlists(playlist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,mood_id UUID REFERENCES moods(mood_id) ON DELETE SET NULL,name VARCHAR(255) NOT NULL,mood_input TEXT,is_saved BOOLEAN NOT NULL DEFAULT false,created_at TIMESTAMPTZ NOT NULL DEFAULT now(),updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS playlist_songs(playlist_id UUID NOT NULL REFERENCES playlists(playlist_id) ON DELETE CASCADE,song_id UUID NOT NULL REFERENCES songs(song_id) ON DELETE CASCADE,position INT NOT NULL,relevance_score NUMERIC(4,3) NOT NULL CHECK(relevance_score BETWEEN 0 AND 1),added_at TIMESTAMPTZ NOT NULL DEFAULT now(),PRIMARY KEY(playlist_id,song_id));
CREATE TABLE IF NOT EXISTS song_moods(song_id UUID NOT NULL REFERENCES songs(song_id) ON DELETE CASCADE,mood_id UUID NOT NULL REFERENCES moods(mood_id) ON DELETE CASCADE,relevance_score NUMERIC(4,3) NOT NULL CHECK(relevance_score BETWEEN 0 AND 1),PRIMARY KEY(song_id,mood_id));
CREATE TABLE IF NOT EXISTS mood_stats(mood_stat_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),mood_id UUID NOT NULL REFERENCES moods(mood_id) ON DELETE CASCADE,stat_date DATE NOT NULL DEFAULT CURRENT_DATE,generated_count INT NOT NULL DEFAULT 0,saved_count INT NOT NULL DEFAULT 0,UNIQUE(mood_id,stat_date));
CREATE TABLE IF NOT EXISTS playlist_history(history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,playlist_id UUID REFERENCES playlists(playlist_id) ON DELETE SET NULL,mood_id UUID REFERENCES moods(mood_id) ON DELETE SET NULL,input_text TEXT,generated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX IF NOT EXISTS idx_songs_embedding ON songs USING ivfflat(embedding vector_cosine_ops) WITH(lists=100);
CREATE INDEX IF NOT EXISTS idx_moods_embedding ON moods USING ivfflat(embedding vector_cosine_ops) WITH(lists=50);
CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_playlist_songs_song_id ON playlist_songs(song_id);
ALTER TABLE songs ADD COLUMN IF NOT EXISTS search_vector tsvector GENERATED ALWAYS AS(to_tsvector('english',coalesce(title,'')||' '||coalesce(artist,'')||' '||coalesce(lyrics,''))) STORED;
CREATE INDEX IF NOT EXISTS idx_songs_search_vector ON songs USING GIN(search_vector);
