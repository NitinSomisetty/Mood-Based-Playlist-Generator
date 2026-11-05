-- Trigger functions maintain daily aggregates transactionally.
CREATE OR REPLACE FUNCTION record_generation() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN INSERT INTO mood_stats(mood_id,stat_date,generated_count) VALUES(NEW.mood_id,CURRENT_DATE,1) ON CONFLICT(mood_id,stat_date) DO UPDATE SET generated_count=mood_stats.generated_count+1; RETURN NEW; END $$;
CREATE OR REPLACE FUNCTION record_save() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN
  -- Free-text playlists may not have a predefined mood, so there is no
  -- mood_stats row to update in that case.
  IF NEW.is_saved AND NOT OLD.is_saved AND NEW.mood_id IS NOT NULL THEN
    INSERT INTO mood_stats(mood_id,stat_date,saved_count)
    VALUES(NEW.mood_id,CURRENT_DATE,1)
    ON CONFLICT(mood_id,stat_date) DO UPDATE
      SET saved_count=mood_stats.saved_count+1;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS playlist_generation_stats ON playlist_history;
CREATE TRIGGER playlist_generation_stats AFTER INSERT ON playlist_history FOR EACH ROW WHEN(NEW.mood_id IS NOT NULL) EXECUTE FUNCTION record_generation();
DROP TRIGGER IF EXISTS playlist_save_stats ON playlists;
CREATE TRIGGER playlist_save_stats AFTER UPDATE OF is_saved ON playlists FOR EACH ROW EXECUTE FUNCTION record_save();
COMMENT ON TRIGGER playlist_generation_stats ON playlist_history IS 'Counts generated playlists per mood/day.';
COMMENT ON TRIGGER playlist_save_stats ON playlists IS 'Counts first-time saves per mood/day.';
CREATE OR REPLACE FUNCTION get_similar_songs(query_embedding vector(384),result_limit int DEFAULT 20) RETURNS TABLE(song_id UUID,title VARCHAR,artist VARCHAR,similarity real) LANGUAGE SQL STABLE SET ivfflat.probes = 100 AS $$ SELECT s.song_id,s.title,s.artist,(1-(s.embedding<=>query_embedding))::real FROM songs s WHERE s.embedding IS NOT NULL ORDER BY s.embedding<=>query_embedding LIMIT result_limit $$;
COMMENT ON FUNCTION get_similar_songs(vector,int) IS 'Returns songs ordered by pgvector cosine similarity.';
CREATE OR REPLACE VIEW public_playlists_view AS SELECT p.playlist_id,p.name,p.is_saved,p.created_at,u.username,m.mood_name,count(ps.song_id)::int song_count FROM playlists p JOIN users u USING(user_id) LEFT JOIN moods m USING(mood_id) LEFT JOIN playlist_songs ps USING(playlist_id) GROUP BY p.playlist_id,u.username,m.mood_name;
COMMENT ON VIEW public_playlists_view IS 'Safe public playlist projection; excludes password hashes.';
-- CTE ranking: best songs for each mood.
WITH ranked AS(SELECT sm.*,row_number() OVER(PARTITION BY mood_id ORDER BY relevance_score DESC) AS rank FROM song_moods sm) SELECT * FROM ranked WHERE rank<=10;
-- Full-text search demonstration.
-- Supabase SQL Editor does not substitute :query parameters, so replace 'calm'
-- with the search words you want to test.
SELECT song_id,title,ts_rank(search_vector,websearch_to_tsquery('english','calm')) AS rank
FROM songs
WHERE search_vector @@ websearch_to_tsquery('english','calm')
ORDER BY rank DESC;
