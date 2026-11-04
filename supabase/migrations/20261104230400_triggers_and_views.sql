-- Update playlist.updated_at automatically whenever a playlist is updated.
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_playlist_timestamp ON playlists;

CREATE TRIGGER trg_update_playlist_timestamp
BEFORE UPDATE ON playlists
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- View combining playlist, user, mood and song details.
CREATE OR REPLACE VIEW playlist_details AS
SELECT
    p.playlist_id,
    p.title AS playlist_name,
    u.username,
    m.mood_name,
    s.song_id,
    s.title AS song_title,
    s.artist,
    ps.position,
    ps.added_at
FROM playlists AS p
JOIN app_users AS u ON p.user_id = u.user_id
JOIN moods AS m ON p.mood_id = m.mood_id
JOIN playlist_songs AS ps ON p.playlist_id = ps.playlist_id
JOIN songs AS s ON ps.song_id = s.song_id;
