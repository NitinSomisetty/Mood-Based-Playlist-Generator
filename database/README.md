# Database

The Supabase CLI is now the canonical migration workflow:

- [`../supabase/config.toml`](../supabase/config.toml) contains non-secret
  project settings.
- [`../supabase/migrations/`](../supabase/migrations/) contains the existing
  SQL migrations, moved into timestamped filenames in dependency order.
- [`../supabase/seed.sql`](../supabase/seed.sql) contains development-only
  sample data.

The older [`schema.sql`](schema.sql) and [`verify_schema.sql`](verify_schema.sql)
files remain as a compatibility reference and verification script. They are
not part of the Supabase CLI migration path. Do not run `schema.sql` after
applying the canonical migrations, because that would replay overlapping DDL.

The migration workflow and the safe existing-database linking procedure are
documented in the repository [README](../README.md).
