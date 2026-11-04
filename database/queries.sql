-- Phase 5: DML and SQL query demonstrations
-- Schema source of truth: app_users, moods, songs, song_moods, playlists,
-- playlist_songs, and user_mood_history.
-- These examples use the actual Supabase schema. DML statements are clearly
-- marked; review their target values before running them in production.

-- ============================================================================
-- 1. BASIC DML OPERATIONS
-- ============================================================================

-- Demonstration mutations are rolled back at the end of this section so the
-- SQL file does not create or delete production data.
BEGIN;

-- INSERT: add a song and its mood relationship atomically.
WITH inserted_song AS (
    INSERT INTO songs (title, artist, description, duration)
    SELECT 'Example Song', 'Example Artist',
           'A sample song for DML demonstration', 210
    WHERE EXISTS (SELECT 1 FROM moods WHERE mood_name = 'Happy')
    RETURNING song_id, title, artist, duration
)
INSERT INTO song_moods (song_id, mood_id, relevance_score)
SELECT inserted_song.song_id, m.mood_id, 0.900
FROM inserted_song
JOIN moods AS m ON m.mood_name = 'Happy'
ON CONFLICT (song_id, mood_id) DO NOTHING;

-- SELECT: retrieve songs associated with one particular mood.
SELECT s.song_id, s.title, s.artist, s.duration, sm.relevance_score
FROM songs AS s
JOIN song_moods AS sm ON sm.song_id = s.song_id
JOIN moods AS m ON m.mood_id = sm.mood_id
WHERE m.mood_name = 'Happy'
ORDER BY sm.relevance_score DESC NULLS LAST, s.title;

-- UPDATE: change the title of an existing playlist.
UPDATE playlists
SET title = 'Updated Playlist Title'
WHERE playlist_id = 1
RETURNING playlist_id, title, updated_at;

-- DELETE: remove a saved (private) playlist. playlist_songs rows cascade.
DELETE FROM playlists
WHERE playlist_id = 1
  AND is_public = FALSE
RETURNING playlist_id, title;

ROLLBACK;

-- ============================================================================
-- 2. JOIN QUERIES
-- ============================================================================

-- 2.1 INNER JOIN: retrieve all songs in a particular playlist.
SELECT p.playlist_id, p.title AS playlist_title, ps.position,
       s.song_id, s.title AS song_title, s.artist, s.duration
FROM playlists AS p
JOIN playlist_songs AS ps ON ps.playlist_id = p.playlist_id
JOIN songs AS s ON s.song_id = ps.song_id
WHERE p.playlist_id = 1
ORDER BY ps.position;

-- 2.2 INNER JOIN: retrieve all playlists belonging to a user.
SELECT u.user_id, u.username, p.playlist_id, p.title, p.is_public,
       COUNT(ps.song_id)::INTEGER AS song_count
FROM app_users AS u
JOIN playlists AS p ON p.user_id = u.user_id
LEFT JOIN playlist_songs AS ps ON ps.playlist_id = p.playlist_id
WHERE u.user_id = 1
GROUP BY u.user_id, u.username, p.playlist_id
ORDER BY p.created_at DESC;

-- 2.3 INNER JOIN: retrieve songs associated with a mood.
SELECT m.mood_name, s.title, s.artist, sm.relevance_score
FROM moods AS m
JOIN song_moods AS sm ON sm.mood_id = m.mood_id
JOIN songs AS s ON s.song_id = sm.song_id
WHERE m.mood_name = 'Happy'
ORDER BY sm.relevance_score DESC NULLS LAST;

-- 2.4 Schema limitation: this project currently has no genres table or
-- songs.genre_id column. A query joining genres would not be executable
-- against the actual Supabase schema and is intentionally not fabricated.
-- Songs can currently be joined to their moods using query 2.3.

-- 2.5 LEFT JOIN: retrieve the most frequently used moods, including moods
-- with no playlists.
SELECT m.mood_id, m.mood_name, COUNT(p.playlist_id)::INTEGER AS usage_count
FROM moods AS m
LEFT JOIN playlists AS p ON p.mood_id = m.mood_id
GROUP BY m.mood_id, m.mood_name
ORDER BY usage_count DESC, m.mood_name;

-- ============================================================================
-- 3. AGGREGATE FUNCTIONS
-- ============================================================================

-- COUNT: number of songs associated with each mood.
SELECT m.mood_name, COUNT(sm.song_id)::INTEGER AS song_count
FROM moods AS m
LEFT JOIN song_moods AS sm ON sm.mood_id = m.mood_id
GROUP BY m.mood_id, m.mood_name
ORDER BY song_count DESC;

-- AVG: average duration of all songs, in seconds.
SELECT AVG(duration)::NUMERIC(10,2) AS average_song_duration_seconds
FROM songs
WHERE duration IS NOT NULL;

-- MAX: longest song, in seconds.
SELECT MAX(duration) AS longest_song_seconds
FROM songs
WHERE duration IS NOT NULL;

-- MIN: shortest song, in seconds.
SELECT MIN(duration) AS shortest_song_seconds
FROM songs
WHERE duration IS NOT NULL;

-- SUM: total duration of one playlist, in seconds.
SELECT p.playlist_id, p.title,
       COALESCE(SUM(s.duration), 0)::BIGINT AS total_duration_seconds
FROM playlists AS p
LEFT JOIN playlist_songs AS ps ON ps.playlist_id = p.playlist_id
LEFT JOIN songs AS s ON s.song_id = ps.song_id
WHERE p.playlist_id = 1
GROUP BY p.playlist_id, p.title;

-- ============================================================================
-- 4. GROUP BY AND HAVING
-- ============================================================================

-- Find moods used in more than five playlists.
SELECT m.mood_id, m.mood_name, COUNT(p.playlist_id)::INTEGER AS playlist_count
FROM moods AS m
JOIN playlists AS p ON p.mood_id = m.mood_id
GROUP BY m.mood_id, m.mood_name
HAVING COUNT(p.playlist_id) > 5
ORDER BY playlist_count DESC;

-- ============================================================================
-- 5. NESTED QUERIES
-- ============================================================================

-- Find songs whose duration exceeds the average duration of all songs.
SELECT song_id, title, artist, duration
FROM songs
WHERE duration > (SELECT AVG(duration) FROM songs WHERE duration IS NOT NULL)
ORDER BY duration DESC;

-- ============================================================================
-- 6. CORRELATED QUERIES
-- ============================================================================

-- Find users who have created at least one playlist.
SELECT u.user_id, u.username, u.email
FROM app_users AS u
WHERE EXISTS (
    SELECT 1
    FROM playlists AS p
    WHERE p.user_id = u.user_id
)
ORDER BY u.username;

-- ============================================================================
-- 7. RECURSIVE CTE
-- ============================================================================

-- Limitation: the actual schema has no genres table or parent_genre_id
-- relationship. Therefore no executable recursive genre query can be supplied
-- without introducing an unapproved schema change. When that relationship is
-- added, the following query is the intended implementation:
--
-- WITH RECURSIVE genre_tree AS (
--     SELECT genre_id, genre_name, parent_genre_id, 0 AS depth,
--            ARRAY[genre_id] AS path
--     FROM genres
--     WHERE parent_genre_id IS NULL
--     UNION ALL
--     SELECT child.genre_id, child.genre_name, child.parent_genre_id,
--            parent.depth + 1, parent.path || child.genre_id
--     FROM genres AS child
--     JOIN genre_tree AS parent
--       ON child.parent_genre_id = parent.genre_id
--     WHERE NOT child.genre_id = ANY(parent.path)
-- )
-- SELECT genre_id, genre_name, parent_genre_id, depth
-- FROM genre_tree
-- ORDER BY path;

-- ============================================================================
-- 8. COMMON TABLE EXPRESSIONS
-- ============================================================================

-- 8.1 Rank songs by duration using a window function.
WITH ranked_songs AS (
    SELECT song_id, title, artist, duration,
           RANK() OVER (ORDER BY duration DESC NULLS LAST) AS duration_rank
    FROM songs
)
SELECT *
FROM ranked_songs
ORDER BY duration_rank, title;

-- 8.2 Find popular moods by playlist usage.
WITH mood_usage AS (
    SELECT m.mood_id, m.mood_name, COUNT(p.playlist_id)::INTEGER AS playlist_count
    FROM moods AS m
    LEFT JOIN playlists AS p ON p.mood_id = m.mood_id
    GROUP BY m.mood_id, m.mood_name
)
SELECT *
FROM mood_usage
WHERE playlist_count > 0
ORDER BY playlist_count DESC, mood_name;

-- 8.3 Calculate playlist song count and total duration.
WITH playlist_statistics AS (
    SELECT p.playlist_id, p.title,
           COUNT(ps.song_id)::INTEGER AS song_count,
           COALESCE(SUM(s.duration), 0)::BIGINT AS total_duration_seconds
    FROM playlists AS p
    LEFT JOIN playlist_songs AS ps ON ps.playlist_id = p.playlist_id
    LEFT JOIN songs AS s ON s.song_id = ps.song_id
    GROUP BY p.playlist_id, p.title
)
SELECT *
FROM playlist_statistics
ORDER BY total_duration_seconds DESC;

-- 8.4 Retrieve mood-based recommendation candidates, then filter them.
WITH recommendation_candidates AS (
    SELECT s.song_id, s.title, s.artist, s.duration,
           sm.mood_id, sm.relevance_score
    FROM songs AS s
    JOIN song_moods AS sm ON sm.song_id = s.song_id
    JOIN moods AS m ON m.mood_id = sm.mood_id
    WHERE m.mood_name = 'Happy'
)
SELECT *
FROM recommendation_candidates
WHERE duration BETWEEN 120 AND 360
  AND relevance_score >= 0.700
ORDER BY relevance_score DESC NULLS LAST, title;
