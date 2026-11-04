# Relational Schema

Notation: `PK` = primary key, `FK` = foreign key, `UK` = unique key,
`NN` = not null. `vector(384)` is supplied by the PostgreSQL `pgvector`
extension.

## Core relations

```text
USERS(
    user_id PK,
    username UK NN,
    email UK NN,
    password_hash NN,
    role NN,
    created_at NN,
    updated_at NN
)

MOODS(
    mood_id PK,
    mood_name UK NN,
    description NN,
    embedding NN,
    created_at NN
)

SONGS(
    song_id PK,
    title NN,
    artist NN,
    album,
    lyrics,
    description,
    duration_seconds NN,
    embedding,
    created_at NN
)

PLAYLISTS(
    playlist_id PK,
    user_id FK -> USERS(user_id) NN,
    mood_id FK -> MOODS(mood_id),
    name NN,
    mood_input,
    is_saved NN,
    created_at NN,
    updated_at NN
)

PLAYLIST_SONGS(
    playlist_id PK, FK -> PLAYLISTS(playlist_id),
    song_id PK, FK -> SONGS(song_id),
    position NN,
    relevance_score NN,
    added_at NN
)

SONG_MOODS(
    song_id PK, FK -> SONGS(song_id),
    mood_id PK, FK -> MOODS(mood_id),
    relevance_score NN
)

MOOD_STATS(
    mood_stat_id PK,
    mood_id FK -> MOODS(mood_id) NN,
    stat_date NN,
    generated_count NN,
    saved_count NN,
    UNIQUE(mood_id, stat_date)
)
```

## Supporting relation

```text
PLAYLIST_HISTORY(
    history_id PK,
    user_id FK -> USERS(user_id) NN,
    playlist_id FK -> PLAYLISTS(playlist_id),
    mood_id FK -> MOODS(mood_id),
    input_text,
    generated_at NN
)
```

## Domain types and implementation notes

- `USERS.user_id`, `PLAYLISTS.playlist_id`, and
  `PLAYLIST_HISTORY.playlist_id` use UUID values.
- `MOODS.embedding` and `SONGS.embedding` use `vector(384)`.
- `role` is a database enum or constrained text value containing only
  `USER` and `ADMIN`.
- `relevance_score` is a decimal similarity score in the inclusive range
  `0.0` to `1.0`.
- `PLAYLIST_SONGS` uses a composite primary key so a song appears at most
  once in a playlist.
- The schema supports both predefined mood selection (`mood_id`) and
  natural-language input (`mood_input` or `input_text`).

