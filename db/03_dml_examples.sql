-- INSERT RETURNING: create a playlist and capture its generated UUID.
INSERT INTO playlists(user_id,name,mood_input) SELECT user_id,'Rainy evening','calm rainy evening' FROM users WHERE username='alex' RETURNING playlist_id;
-- The SQL Editor does not substitute :playlist_id/:song_id placeholders.
-- The examples below choose an existing seeded row so they can be run directly.
-- UPDATE DML: save the most recently created Rainy evening playlist.
UPDATE playlists SET is_saved=true,updated_at=now()
WHERE playlist_id=(SELECT playlist_id FROM playlists WHERE name='Rainy evening' ORDER BY created_at DESC LIMIT 1);
-- DELETE DML: composite key identifies exactly one song membership.
DELETE FROM playlist_songs
WHERE playlist_id=(SELECT playlist_id FROM playlists WHERE name='Alex Calm Collection' LIMIT 1)
  AND song_id=(SELECT song_id FROM playlist_songs WHERE playlist_id=(SELECT playlist_id FROM playlists WHERE name='Alex Calm Collection' LIMIT 1) ORDER BY position LIMIT 1);
-- JOIN: songs and their mood tags in a seeded playlist.
SELECT p.name,s.title,s.artist,m.mood_name
FROM playlists p
JOIN playlist_songs ps ON ps.playlist_id=p.playlist_id
JOIN songs s ON s.song_id=ps.song_id
LEFT JOIN song_moods sm ON sm.song_id=s.song_id
LEFT JOIN moods m ON m.mood_id=sm.mood_id
WHERE p.name='Alex Calm Collection';
-- GROUP/HAVING: moods represented by more than N playlists.
SELECT m.mood_name,count(p.playlist_id) AS generated FROM moods m JOIN playlists p USING(mood_id) GROUP BY m.mood_id HAVING count(p.playlist_id)>1;
-- Correlated subquery: users with no saved playlist.
SELECT u.username FROM users u WHERE NOT EXISTS(SELECT 1 FROM playlists p WHERE p.user_id=u.user_id AND p.is_saved);
-- Nested subquery: five most frequently included songs.
SELECT * FROM (SELECT s.title,count(*) AS appearances FROM songs s JOIN playlist_songs ps USING(song_id) GROUP BY s.song_id,s.title) popular ORDER BY appearances DESC LIMIT 5;
-- Recursive CTE is useful for backfilling daily stats over a date range.
WITH RECURSIVE days(d) AS (SELECT CURRENT_DATE-6 UNION ALL SELECT d+1 FROM days WHERE d<CURRENT_DATE) SELECT d,m.mood_name FROM days CROSS JOIN moods m ORDER BY d;
