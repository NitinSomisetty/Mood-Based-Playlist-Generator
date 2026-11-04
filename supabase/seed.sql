-- Sample moods (safe to rerun)
INSERT INTO moods (mood_name, description)
SELECT v.mood_name, v.description
FROM (VALUES
    ('Happy', 'Positive and cheerful mood'),
    ('Sad', 'Melancholic and emotional mood'),
    ('Relaxed', 'Calm and peaceful mood'),
    ('Energetic', 'High-energy and exciting mood'),
    ('Focused', 'Concentration and productivity mood')
) AS v(mood_name, description)
WHERE NOT EXISTS (
    SELECT 1 FROM moods AS m WHERE m.mood_name = v.mood_name
);

-- Sample songs. Uses the actual observed columns: title, artist, description, duration.
INSERT INTO songs (title, artist, description, duration)
SELECT v.title, v.artist, v.description, v.duration
FROM (VALUES
    ('Morning Light', 'Demo Artist 1', 'A cheerful and uplifting song', 210),
    ('Rainy Evening', 'Demo Artist 2', 'A melancholic and emotional song', 240),
    ('Quiet Moments', 'Demo Artist 3', 'A calm and peaceful instrumental', 195),
    ('Run Free', 'Demo Artist 4', 'An energetic and exciting track', 220),
    ('Deep Focus', 'Demo Artist 5', 'An instrumental track for concentration', 260)
) AS v(title, artist, description, duration)
WHERE NOT EXISTS (
    SELECT 1
    FROM songs AS s
    WHERE s.title = v.title AND s.artist = v.artist
);

-- Associate songs with moods.
INSERT INTO song_moods (song_id, mood_id, relevance_score)
SELECT s.song_id, m.mood_id, v.score
FROM (VALUES
    ('Morning Light', 'Happy', 0.950),
    ('Rainy Evening', 'Sad', 0.900),
    ('Quiet Moments', 'Relaxed', 0.950),
    ('Run Free', 'Energetic', 0.980),
    ('Deep Focus', 'Focused', 0.970),
    ('Morning Light', 'Energetic', 0.600),
    ('Quiet Moments', 'Focused', 0.750)
) AS v(title, mood, score)
JOIN songs AS s ON s.title = v.title
JOIN moods AS m ON m.mood_name = v.mood
WHERE NOT EXISTS (
    SELECT 1
    FROM song_moods AS sm
    WHERE sm.song_id = s.song_id AND sm.mood_id = m.mood_id
);
