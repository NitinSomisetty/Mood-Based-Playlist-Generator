-- pgvector cosine search: $1 is a 384-dimensional all-MiniLM-L6-v2 vector.
SELECT song_id,title,artist,1-(embedding<=>$1) AS similarity FROM songs WHERE embedding IS NOT NULL ORDER BY embedding<=>$1 LIMIT 20;
