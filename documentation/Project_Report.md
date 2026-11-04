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
