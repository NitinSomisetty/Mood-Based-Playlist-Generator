# Data Dictionary and Constraints

## `USERS`

| Column | Type | Key | Required | Description and constraints |
|---|---|---|---|---|
| `user_id` | `UUID` | PK | Yes | System-generated user identifier. |
| `username` | `VARCHAR(50)` | UK | Yes | Display/login name; must be unique and non-empty. |
| `email` | `VARCHAR(255)` | UK | Yes | Login email; must be unique and use a valid application-level format. |
| `password_hash` | `TEXT` |  | Yes | bcrypt hash; plaintext passwords are never stored. |
| `role` | `USER_ROLE` |  | Yes | Must be `USER` or `ADMIN`; default is `USER`. |
| `created_at` | `TIMESTAMPTZ` |  | Yes | Registration timestamp. |
| `updated_at` | `TIMESTAMPTZ` |  | Yes | Last profile update timestamp. |

## `MOODS`

| Column | Type | Key | Required | Description and constraints |
|---|---|---|---|---|
| `mood_id` | `INTEGER` | PK | Yes | Identity identifier for a predefined mood. |
| `mood_name` | `VARCHAR(50)` | UK | Yes | Unique name such as `Happy` or `Energetic`. |
| `description` | `TEXT` |  | Yes | Semantic description used to explain the mood and create its embedding. |
| `embedding` | `VECTOR(384)` |  | Yes | Sentence-transformer embedding for cosine similarity search. |
| `created_at` | `TIMESTAMPTZ` |  | Yes | Creation timestamp. |

## `SONGS`

| Column | Type | Key | Required | Description and constraints |
|---|---|---|---|---|
| `song_id` | `BIGINT` | PK | Yes | Identity identifier for a song. |
| `title` | `VARCHAR(255)` |  | Yes | Song title. |
| `artist` | `VARCHAR(255)` |  | Yes | Artist or performing group. |
| `album` | `TEXT` |  | No | Album name. |
| `lyrics` | `TEXT` |  | No | Lyrics or searchable text, subject to content rights. |
| `description` | `TEXT` |  | No | Semantic song description. |
| `duration_seconds` | `INTEGER` |  | Yes | Must be greater than zero. |
| `embedding` | `VECTOR(384)` |  | No | Embedding generated from song text; nullable until processing completes. |
| `created_at` | `TIMESTAMPTZ` |  | Yes | Creation timestamp. |

## `PLAYLISTS`

| Column | Type | Key | Required | Description and constraints |
|---|---|---|---|---|
| `playlist_id` | `UUID` | PK | Yes | System-generated playlist identifier. |
| `user_id` | `UUID` | FK | Yes | Must reference an existing `USERS.user_id`; ownership is mandatory. |
| `mood_id` | `INTEGER` | FK | No | References the predefined mood used to generate the playlist. |
| `name` | `VARCHAR(150)` |  | Yes | User-visible playlist name. |
| `mood_input` | `TEXT` |  | No | Natural-language mood request supplied by the user. |
| `is_saved` | `BOOLEAN` |  | Yes | Indicates whether the user saved the generated playlist; default `FALSE`. |
| `created_at` | `TIMESTAMPTZ` |  | Yes | Creation timestamp. |
| `updated_at` | `TIMESTAMPTZ` |  | Yes | Last playlist update timestamp. |

At least one of `mood_id` and `mood_input` must be present for a generated
playlist. This is enforced with a table-level check constraint.

## `PLAYLIST_SONGS`

| Column | Type | Key | Required | Description and constraints |
|---|---|---|---|---|
| `playlist_id` | `UUID` | PK, FK | Yes | References `PLAYLISTS`; cascade deletion is allowed for dependent rows. |
| `song_id` | `BIGINT` | PK, FK | Yes | References `SONGS`; a song cannot be duplicated in one playlist. |
| `position` | `INTEGER` |  | Yes | Must be positive and unique within a playlist. |
| `relevance_score` | `NUMERIC(5,4)` |  | Yes | Must be between `0.0000` and `1.0000`. |
| `added_at` | `TIMESTAMPTZ` |  | Yes | Time the song was added to the playlist. |

## `SONG_MOODS`

| Column | Type | Key | Required | Description and constraints |
|---|---|---|---|---|
| `song_id` | `BIGINT` | PK, FK | Yes | References `SONGS`. |
| `mood_id` | `INTEGER` | PK, FK | Yes | References `MOODS`. |
| `relevance_score` | `NUMERIC(5,4)` |  | Yes | Must be between `0.0000` and `1.0000`; represents song-mood relevance. |

The composite key prevents duplicate song-mood assignments.

## `MOOD_STATS`

| Column | Type | Key | Required | Description and constraints |
|---|---|---|---|---|
| `mood_stat_id` | `BIGINT` | PK | Yes | Identity identifier for an aggregate row. |
| `mood_id` | `INTEGER` | FK | Yes | References `MOODS`; deleting a mood removes its statistics. |
| `stat_date` | `DATE` | UK (with `mood_id`) | Yes | Calendar day represented by the aggregate. |
| `generated_count` | `INTEGER` |  | Yes | Number of playlists generated; must be non-negative. |
| `saved_count` | `INTEGER` |  | Yes | Number of playlists saved; must be non-negative and no greater than generated count. |

## `PLAYLIST_HISTORY`

| Column | Type | Key | Required | Description and constraints |
|---|---|---|---|---|
| `history_id` | `BIGINT` | PK | Yes | Identity identifier for a generation event. |
| `user_id` | `UUID` | FK | Yes | References the user who generated the playlist. |
| `playlist_id` | `UUID` | FK | No | References the resulting playlist; nullable if the generation was not saved. |
| `mood_id` | `INTEGER` | FK | No | References the selected predefined mood, if any. |
| `input_text` | `TEXT` |  | No | Natural-language request used for the generation. |
| `generated_at` | `TIMESTAMPTZ` |  | Yes | Generation timestamp. |

History rows are retained when a playlist is deleted. This preserves usage
statistics and auditability; the playlist foreign key should therefore use
`ON DELETE SET NULL`.

## Cross-table integrity rules

1. All primary-key columns are unique and not nullable.
2. Foreign keys prevent playlists, songs, moods, and statistics from
   referencing missing parent rows.
3. Deleting a user cascades to that user's playlists and playlist-song rows,
   while history retains the user reference only if the implementation
   explicitly supports anonymization; otherwise user deletion is restricted.
4. Deleting a song cascades to `SONG_MOODS` and `PLAYLIST_SONGS`.
5. Deleting a mood cascades to `SONG_MOODS` and `MOOD_STATS`, and sets
   nullable mood references in playlists and history to `NULL`.
6. Indexes should be created on all foreign-key columns, playlist ownership,
   mood names, song artists, and the vector columns used by similarity search.
