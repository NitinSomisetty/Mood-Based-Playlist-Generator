-- INNER JOIN: songs associated with each mood
SELECT m.mood_name, s.title, s.artist
FROM moods AS m
JOIN song_moods AS sm ON m.mood_id = sm.mood_id
JOIN songs AS s ON sm.song_id = s.song_id;

-- LEFT JOIN: include moods that have no songs
SELECT m.mood_name, s.title
FROM moods AS m
LEFT JOIN song_moods AS sm ON m.mood_id = sm.mood_id
LEFT JOIN songs AS s ON sm.song_id = s.song_id
ORDER BY m.mood_name;

-- GROUP BY: count songs per mood
SELECT m.mood_name, COUNT(sm.song_id) AS total_songs
FROM moods AS m
LEFT JOIN song_moods AS sm ON m.mood_id = sm.mood_id
GROUP BY m.mood_id, m.mood_name
ORDER BY total_songs DESC;

-- Subquery: songs longer than average duration
SELECT title, artist, duration
FROM songs
WHERE duration > (SELECT AVG(duration) FROM songs);

-- ORDER BY: rank song-mood associations by relevance
SELECT s.title, m.mood_name, sm.relevance_score
FROM song_moods AS sm
JOIN songs AS s ON sm.song_id = s.song_id
JOIN moods AS m ON sm.mood_id = m.mood_id
ORDER BY sm.relevance_score DESC;

-- Aggregate functions
SELECT
    COUNT(*) AS total_songs,
    AVG(duration) AS average_duration,
    MIN(duration) AS shortest_song,
    MAX(duration) AS longest_song
FROM songs;
