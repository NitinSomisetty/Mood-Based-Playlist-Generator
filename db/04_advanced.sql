-- ============================================================================
-- PHASE 6: ADVANCED POSTGRESQL FEATURES
-- ============================================================================
-- Run this file in the Supabase SQL Editor after 01_schema.sql.
--
-- IMPORTANT:
-- * Executable SQL is active in this file. Comment out any section you do not want to run.
-- * Comment out individual sections when you want to run only selected blocks.
-- * Functions, triggers, and views are persistent database objects.
-- * The final two blocks are read-only demonstrations.

-- ============================================================================
-- 1. STORED TRIGGER FUNCTION: count generated playlists
-- The playlist_history trigger increments one mood_stats row per mood/day.
-- Prerequisite: mood_stats and playlist_history must already exist.
-- ============================================================================
CREATE OR REPLACE FUNCTION record_generation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO mood_stats (mood_id, stat_date, generated_count)
    VALUES (NEW.mood_id, CURRENT_DATE, 1)
    ON CONFLICT (mood_id, stat_date)
    DO UPDATE SET generated_count = mood_stats.generated_count + 1;
    RETURN NEW;
END;
$$;

-- ============================================================================
-- 2. STORED TRIGGER FUNCTION: count first-time saves
-- The trigger updates saved_count only when is_saved changes FALSE -> TRUE.
-- ============================================================================
CREATE OR REPLACE FUNCTION record_save()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_saved AND NOT OLD.is_saved AND NEW.mood_id IS NOT NULL THEN
        INSERT INTO mood_stats (mood_id, stat_date, saved_count)
        VALUES (NEW.mood_id, CURRENT_DATE, 1)
        ON CONFLICT (mood_id, stat_date)
        DO UPDATE SET saved_count = mood_stats.saved_count + 1;
    END IF;
    RETURN NEW;
END;
$$;

-- ============================================================================
-- 3. TRIGGERS
-- Drop/recreate is safe because it changes only these named triggers.
-- ============================================================================
DROP TRIGGER IF EXISTS playlist_generation_stats ON playlist_history;
CREATE TRIGGER playlist_generation_stats
AFTER INSERT ON playlist_history
FOR EACH ROW
WHEN (NEW.mood_id IS NOT NULL)
EXECUTE FUNCTION record_generation();

DROP TRIGGER IF EXISTS playlist_save_stats ON playlists;
CREATE TRIGGER playlist_save_stats
AFTER UPDATE OF is_saved ON playlists
FOR EACH ROW
EXECUTE FUNCTION record_save();

-- ============================================================================
-- 4. VECTOR SIMILARITY STORED FUNCTION
-- Returns songs ordered by cosine similarity to a 384-dimensional vector.
-- Replace $1 with a vector value when calling it from SQL.
-- ============================================================================
CREATE OR REPLACE FUNCTION get_similar_songs(
    query_embedding VECTOR(384),
    result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    song_id UUID,
    title VARCHAR,
    artist VARCHAR,
    similarity REAL
)
LANGUAGE SQL
STABLE
AS $$
    SELECT s.song_id,
           s.title,
           s.artist,
           (1 - (s.embedding <=> query_embedding))::REAL
    FROM songs AS s
    WHERE s.embedding IS NOT NULL
    ORDER BY s.embedding <=> query_embedding
    LIMIT GREATEST(result_limit, 1);
$$;

-- ============================================================================
-- 5. VIEW
-- Provides a safe playlist summary without exposing password_hash.
-- ============================================================================
CREATE OR REPLACE VIEW public_playlists_view AS
SELECT p.playlist_id,
       p.name,
       p.is_saved,
       p.created_at,
       u.username,
       m.mood_name,
       COUNT(ps.song_id)::INTEGER AS song_count
FROM playlists AS p
JOIN users AS u ON u.user_id = p.user_id
LEFT JOIN moods AS m ON m.mood_id = p.mood_id
LEFT JOIN playlist_songs AS ps ON ps.playlist_id = p.playlist_id
GROUP BY p.playlist_id, u.username, m.mood_name;

-- ============================================================================
-- 6. TRANSACTION DEMONSTRATION
-- Uncomment the whole block together. ROLLBACK intentionally leaves no data.
-- ============================================================================
BEGIN;
UPDATE playlists
SET name = 'Temporary Transaction Test'
WHERE name = 'Alex Calm Collection';
SELECT playlist_id, name
FROM playlists
WHERE name = 'Temporary Transaction Test';
ROLLBACK;

-- ============================================================================
-- 7. CTE AND WINDOW FUNCTION
-- Rank the best song-mood relationships within each mood.
-- READ-ONLY.
-- ============================================================================
WITH ranked_songs AS (
    SELECT sm.song_id,
           sm.mood_id,
           sm.relevance_score,
           ROW_NUMBER() OVER (
               PARTITION BY sm.mood_id
               ORDER BY sm.relevance_score DESC
           ) AS mood_rank
    FROM song_moods AS sm
)
SELECT r.mood_id,
       m.mood_name,
       r.song_id,
       s.title,
       r.relevance_score,
       r.mood_rank
FROM ranked_songs AS r
JOIN moods AS m ON m.mood_id = r.mood_id
JOIN songs AS s ON s.song_id = r.song_id
WHERE r.mood_rank <= 10
ORDER BY m.mood_name, r.mood_rank;

-- ============================================================================
-- 8. CTE: POPULAR MOODS
-- Calculate mood popularity from playlist usage.
-- READ-ONLY.
-- ============================================================================
WITH mood_usage AS (
    SELECT p.mood_id, COUNT(*)::INTEGER AS playlist_count
    FROM playlists AS p
    WHERE p.mood_id IS NOT NULL
    GROUP BY p.mood_id
)
SELECT m.mood_name, mu.playlist_count
FROM mood_usage AS mu
JOIN moods AS m ON m.mood_id = mu.mood_id
ORDER BY mu.playlist_count DESC, m.mood_name;

-- ============================================================================
-- 9. CTE: PLAYLIST STATISTICS
-- Calculate song count and total duration for every playlist.
-- READ-ONLY.
-- ============================================================================
WITH playlist_stats AS (
    SELECT p.playlist_id,
           p.name,
           COUNT(ps.song_id)::INTEGER AS song_count,
           COALESCE(SUM(s.duration_seconds), 0)::BIGINT AS total_duration_seconds
    FROM playlists AS p
    LEFT JOIN playlist_songs AS ps ON ps.playlist_id = p.playlist_id
    LEFT JOIN songs AS s ON s.song_id = ps.song_id
    GROUP BY p.playlist_id, p.name
)
SELECT *
FROM playlist_stats
ORDER BY total_duration_seconds DESC;

-- ============================================================================
-- 10. CTE: FILTERED RECOMMENDATION CANDIDATES
-- Build candidates from song_moods, then apply a relevance filter outside the
-- CTE. Replace the mood name with a predefined mood in the moods table.
-- READ-ONLY.
-- ============================================================================
WITH recommendation_candidates AS (
    SELECT s.song_id,
           s.title,
           s.artist,
           m.mood_name,
           sm.relevance_score
    FROM song_moods AS sm
    JOIN songs AS s ON s.song_id = sm.song_id
    JOIN moods AS m ON m.mood_id = sm.mood_id
    WHERE m.mood_name = 'Happy'
)
SELECT *
FROM recommendation_candidates
WHERE relevance_score >= 0.70
ORDER BY relevance_score DESC, title;

-- ============================================================================
-- 11. FULL-TEXT SEARCH
-- The search_vector column and GIN index are created in 01_schema.sql.
-- Replace 'calm' with the words you want to search.
-- READ-ONLY.
-- ============================================================================
SELECT song_id,
       title,
       artist,
       ts_rank(
           search_vector,
           websearch_to_tsquery('english', 'calm')
       ) AS rank
FROM songs
WHERE search_vector @@ websearch_to_tsquery('english', 'calm')
ORDER BY rank DESC;

-- ============================================================================
-- 12. MOOD STATISTICS CHECK
-- Confirm generated and saved counters after using the application.
-- READ-ONLY.
-- ============================================================================
SELECT m.mood_name,
       ms.stat_date,
       ms.generated_count,
       ms.saved_count
FROM mood_stats AS ms
JOIN moods AS m ON m.mood_id = ms.mood_id
ORDER BY ms.stat_date DESC, m.mood_name;
