# Database DDL

## Phase 4 files

- `schema.sql` is the idempotent project DDL. It preserves the existing
  Supabase naming contract (`app_users`, `songs.duration`, and
  `playlists.title`), creates missing relations, applies schema adjustments,
  adds constraints and relational indexes, demonstrates `ALTER TABLE`, and
  safely demonstrates `DROP` using a temporary table.
- `verify_schema.sql` runs duplicate-key, invalid-role, invalid-foreign-key,
  negative-duration, and cascade-deletion checks inside a transaction that is
  rolled back.

Run the schema against the project database:

```text
psql "$DATABASE_URL" -f database/schema.sql
```

Then run the verification script:

```text
psql "$DATABASE_URL" -f database/verify_schema.sql
```

Vector HNSW indexes are intentionally not created by `schema.sql`; they
remain in `migrations/004_create_indexes.sql` and should be applied after
embeddings and the vector-search workload are available.
