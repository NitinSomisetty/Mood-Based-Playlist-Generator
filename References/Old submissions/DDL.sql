-- ================================================================
-- DBMS Level 3 Mini-Project: Mood-Based Playlist Generator
-- Week 4 Lab: Database Setup
-- ================================================================

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- ================================================================
-- 1. USERS TABLE
-- ================================================================
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- 2. MOODS TABLE
-- ================================================================
CREATE TABLE moods (
  mood_id SERIAL PRIMARY KEY,
  mood_name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  embedding vector(384),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- 3. SONGS TABLE
-- ================================================================
CREATE TABLE songs (
  song_id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  artist VARCHAR(255) NOT NULL,
  lyrics TEXT,
  description TEXT,
  duration INT,
  embedding vector(384),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- 4. PLAYLISTS TABLE
-- ================================================================
CREATE TABLE playlists (
  playlist_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  mood_id INT REFERENCES moods(mood_id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- 5. PLAYLIST_SONGS JUNCTION TABLE (Many-to-Many)
-- ================================================================
CREATE TABLE playlist_songs (
  playlist_id INT NOT NULL REFERENCES playlists(playlist_id) ON DELETE CASCADE,
  song_id INT NOT NULL REFERENCES songs(song_id) ON DELETE CASCADE,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (playlist_id, song_id)
);

-- ================================================================
-- 6. MOOD_STATS TABLE (for trending/aggregates)
-- ================================================================
CREATE TABLE mood_stats (
  mood_id INT PRIMARY KEY REFERENCES moods(mood_id) ON DELETE CASCADE,
  playlist_count INT DEFAULT 0,
  play_count INT DEFAULT 0,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- INDEXES
-- ================================================================

-- Vector indexes for semantic search
CREATE INDEX idx_songs_embedding ON songs 
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX idx_moods_embedding ON moods 
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 50);

-- Foreign key and lookup indexes
CREATE INDEX idx_playlists_user_id ON playlists(user_id);
CREATE INDEX idx_playlists_mood_id ON playlists(mood_id);
CREATE INDEX idx_playlist_songs_song_id ON playlist_songs(song_id);
CREATE INDEX idx_mood_stats_playlist_count ON mood_stats(playlist_count DESC);

-- Composite indexes
CREATE INDEX idx_playlists_user_mood ON playlists(user_id, mood_id);

-- ================================================================
-- CONSTRAINTS (Additional)
-- ================================================================

-- Ensure songs have embeddings for search
ALTER TABLE songs ADD CONSTRAINT chk_embedding_not_null 
  CHECK (embedding IS NOT NULL);

ALTER TABLE moods ADD CONSTRAINT chk_mood_embedding_not_null 
  CHECK (embedding IS NOT NULL);

-- ================================================================
-- VERIFICATION QUERIES (Run these to confirm setup)
-- ================================================================

-- Check all tables exist
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Check indexes
-- SELECT indexname FROM pg_indexes WHERE schemaname = 'public';

-- Check vector extension
-- SELECT * FROM pg_extension WHERE extname = 'vector';
