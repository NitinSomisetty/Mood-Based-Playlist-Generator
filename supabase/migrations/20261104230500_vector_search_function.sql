-- Returns songs ordered by cosine similarity to a supplied 384-dimensional vector.
CREATE OR REPLACE FUNCTION search_similar_songs(
    query_embedding VECTOR(384),
    match_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    song_id BIGINT,
    title TEXT,
    artist TEXT,
    similarity DOUBLE PRECISION
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        s.song_id,
        s.title::TEXT,
        s.artist::TEXT,
        (1 - (s.embedding <=> query_embedding)) AS similarity
    FROM songs AS s
    WHERE s.embedding IS NOT NULL
    ORDER BY s.embedding <=> query_embedding
    LIMIT GREATEST(match_count, 1);
$$;
