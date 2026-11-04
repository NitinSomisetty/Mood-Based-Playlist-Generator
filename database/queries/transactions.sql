-- Run this block as one transaction in the same SQL session.
BEGIN;

UPDATE songs
SET description = 'Temporary test description'
WHERE title = 'Morning Light';

SELECT title, description
FROM songs
WHERE title = 'Morning Light';

ROLLBACK;

-- The original description should be restored.
SELECT title, description
FROM songs
WHERE title = 'Morning Light';
