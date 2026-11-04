# Mood-Based Playlist Generator

## Phase 2: ER diagram and relational schema

The database design deliverables for this phase are maintained as separate
documents:

- [ER diagram](./ER_Diagram.md)
- [Relational schema](./Relational_Schema.md)
- [Data dictionary and constraints](./Data_Dictionary.md)

The design covers the seven primary relations (`USERS`, `MOODS`, `SONGS`,
`PLAYLISTS`, `PLAYLIST_SONGS`, `SONG_MOODS`, and `MOOD_STATS`) and the
supporting `PLAYLIST_HISTORY` audit relation. It defines primary keys,
foreign keys, unique constraints, cardinalities, nullable attributes, domain
constraints, and the 384-dimensional pgvector embedding attributes.

## Phase 5: DML and SQL query implementation

[`database/queries.sql`](../database/queries.sql) contains labelled examples
for INSERT, SELECT, UPDATE, DELETE, joins, aggregate functions, `GROUP BY`
and `HAVING`, nested queries, correlated `EXISTS`, CTEs, ranking, playlist
statistics, and mood-based recommendation candidates.

The application integration uses the shared PostgreSQL pool in
[`frontend/lib/db.ts`](../frontend/lib/db.ts) and the parameterized
[`library` route](../frontend/app/api/library/route.ts). The page supports
adding a song with its mood relationship, filtering songs by mood, renaming
playlists, and deleting saved private playlists. Mutations refresh the
displayed data and return explicit errors.

The current schema has no `genres` relation or `parent_genre_id`, so the
genre join and recursive hierarchy query are documented limitations in
`queries.sql`; they are not claimed as validated executable queries.

## Phase 4: DDL implementation

The executable DDL is in [`database/schema.sql`](../database/schema.sql). It
creates the project relations in dependency order, applies primary keys,
foreign keys, unique, not-null, check, default, and cascading rules,
demonstrates `ALTER TABLE`, creates relational indexes, and safely demonstrates
`DROP` using a temporary object. The matching
[`verify_schema.sql`](../database/verify_schema.sql) script checks duplicate
usernames, invalid roles, invalid foreign keys, negative durations, and
cascading deletion inside a transaction that is rolled back.
