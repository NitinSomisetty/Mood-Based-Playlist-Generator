# Mood-Based Playlist Generator

A Next.js and PostgreSQL application that generates playlists from predefined moods
or natural-language mood descriptions. The project demonstrates relational
database design, pgvector similarity search, authentication, and advanced SQL.

## Project structure

- `frontend/` - Next.js application, API routes, and shared server/client code
- `database/` - PostgreSQL schema, seed data, queries, functions, and triggers
- `embeddings/` - Python tooling for generating 384-dimensional embeddings
- `documentation/` - ER diagram, relational schema, data dictionary, and project report
- `tests/` - Application and database test suites

## Database design documentation

The Phase 2 design deliverables are available in:

- [ER diagram](documentation/ER_Diagram.md)
- [Relational schema](documentation/Relational_Schema.md)
- [Data dictionary and constraints](documentation/Data_Dictionary.md)

## Supabase CLI database workflow

The committed SQL source of truth is [`supabase/migrations/`](supabase/migrations/).
The migration files were moved from the existing `database/migrations/` directory
into timestamped Supabase filenames; they were not copied. The existing
[`database/schema.sql`](database/schema.sql) remains a reference-only
compatibility file and must not be run in addition to the migrations.

Install the Supabase CLI using the official instructions for your operating
system: <https://supabase.com/docs/guides/cli/getting-started>. You must
obtain the project reference from Supabase Dashboard > Project Settings >
General. If the CLI prompts for it, obtain the database password from
Dashboard > Project Settings > Database; do not put that password in a file.
Then run these commands manually from the repository root:

```text
supabase login
supabase link --project-ref <PROJECT_REF>
supabase migration list
```

`<PROJECT_REF>` is the project reference from the Supabase dashboard URL or
Project Settings > General. The link command does not prove that migrations
have been applied; `supabase migration list` must be checked.

Because this database already contains tables and data, do not run
`supabase db reset`, and do not run `supabase db push` until the remote
migration history and the SQL files have been compared. If the remote schema
already contains the exact changes represented by a migration, use
`supabase migration repair --status applied <VERSION>` only after verifying
that migration's effects in the dashboard SQL editor. This records history
without executing the migration. Never mark an unverified migration applied.

For a remote change that is not represented locally, create a new migration
instead of editing an applied file:

```text
supabase migration new describe_the_change
supabase db push
supabase migration list
```

`supabase db push` applies pending migrations to the linked project. It should
only be run after reviewing the SQL and confirming the target project. The
development seed at [`supabase/seed.sql`](supabase/seed.sql) is used by local
Supabase workflows; it is not a production data import.

For team development, commit every reviewed migration and the
`supabase/config.toml` file, never commit `.env` files, access tokens, database
passwords, or local `.supabase/` state. Each teammate should install the CLI,
run `supabase login`, link using the same project reference, inspect
`supabase migration list`, and pull/review remote changes before creating a
new migration. Resolve migration conflicts by creating a new corrective
migration rather than rewriting a migration already applied remotely.

## Local application setup

1. Copy `.env.example` to `.env.local` and set the PostgreSQL connection values.
2. Ensure PostgreSQL has the `vector` extension available.
3. Install frontend dependencies:

   ```text
   cd frontend
   npm install
   ```

4. Start the development server:

   ```text
   npm run dev
   ```

The database file layout is also documented in
[`database/README.md`](database/README.md).

## Phase 5: DML and SQL queries

The complete, labelled SQL demonstration file is
[`database/queries.sql`](database/queries.sql). It covers DML, joins,
aggregates, `GROUP BY`/`HAVING`, nested and correlated queries, CTEs, and
recommendation candidates using the existing schema.

The application uses the existing `pg` dependency and the shared pool in
[`frontend/lib/db.ts`](frontend/lib/db.ts). Its
[`/api/library`](frontend/app/api/library/route.ts) route supports adding a
song, filtering songs by mood, renaming playlists, and deleting saved private
playlists. The starter page now exposes those operations with loading and
error feedback.

The current Supabase schema does not contain `genres` or `parent_genre_id`.
The genre join and recursive CTE are therefore documented as non-executable
templates in `database/queries.sql` rather than inventing an unapproved table.
