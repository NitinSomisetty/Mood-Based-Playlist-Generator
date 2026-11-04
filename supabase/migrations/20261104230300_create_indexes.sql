-- Relational indexes
CREATE INDEX IF NOT EXISTS idx_song_moods_mood
ON song_moods (mood_id);

CREATE INDEX IF NOT EXISTS idx_playlists_user
ON playlists (user_id);

CREATE INDEX IF NOT EXISTS idx_playlists_mood
ON playlists (mood_id);

CREATE INDEX IF NOT EXISTS idx_playlist_songs_song
ON playlist_songs (song_id);

CREATE INDEX IF NOT EXISTS idx_mood_history_user
ON user_mood_history (user_id);

CREATE INDEX IF NOT EXISTS idx_mood_history_detected
ON user_mood_history (detected_at DESC);

-- Approximate nearest-neighbor indexes using cosine distance
CREATE INDEX IF NOT EXISTS idx_songs_embedding
ON songs USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_moods_embedding
ON moods USING hnsw (embedding vector_cosine_ops);
