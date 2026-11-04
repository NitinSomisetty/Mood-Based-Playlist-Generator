-- Adjustments made to the existing Supabase schema.
-- Backfill playlist positions before making the column NOT NULL.

ALTER TABLE playlists
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE playlist_songs
ADD COLUMN IF NOT EXISTS position INTEGER;

WITH numbered AS (
    SELECT
        playlist_id,
        song_id,
        ROW_NUMBER() OVER (
            PARTITION BY playlist_id
            ORDER BY added_at, song_id
        ) AS new_position
    FROM playlist_songs
)
UPDATE playlist_songs AS ps
SET position = numbered.new_position
FROM numbered
WHERE ps.playlist_id = numbered.playlist_id
  AND ps.song_id = numbered.song_id
  AND ps.position IS NULL;

ALTER TABLE playlist_songs
ALTER COLUMN position SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_playlist_position
ON playlist_songs (playlist_id, position);
