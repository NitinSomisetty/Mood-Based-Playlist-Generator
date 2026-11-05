# Mood-Based Playlist Generator
An auditable DBMS mini-project that turns natural-language mood descriptions into song recommendations. It demonstrates UUID relational design, many-to-many relationships, pgvector cosine search, full-text search, joins, nested/correlated/recursive queries, functions, triggers, views, RLS, and a Next.js interface.

## Setup
1. Install Node 18+ and create a Supabase project.
2. Run `npm install`.
3. In Supabase, click **Connect**, choose **Session pooler**, choose **URI**, and copy the complete URI. Put it in `.env.local` as `DATABASE_URL` along with a long `AUTH_SECRET`. The URI should contain `pooler.supabase.com` and port `5432`; do not use square brackets around the password.
4. Run `.\scripts\db-setup.ps1` in PowerShell, or execute the SQL files in `db/` manually in Supabase SQL Editor. The `psql` command must be installed and available on `PATH` for the script.
5. Run `npm run dev`, then open `http://localhost:3000`.

To verify the connection before using the UI, open `http://localhost:3000/api/health`. A successful response contains `"ok":true`; a `503` means `DATABASE_URL` is still incorrect or the Supabase project is paused/unreachable. Rerunning `db/02_seed_data.sql` adds demo tracks up to 100 without duplicating existing tracks.

Architecture: `Next.js UI → API route → pg Pool/raw SQL → Supabase PostgreSQL + pgvector`.

The application now includes semantic search on the home page, mood-based
filtering through playlist generation, dashboard statistics, and administrator
song CRUD at `/admin/songs`. Protected playlist requests set the transaction
local `app.user_id` and `app.role` values expected by the RLS policies. Run
`db/07_validation.sql` as part of setup to add database-level validation for
user identity fields and playlist text fields.

`03_dml_examples.sql` and `05_vector_search.sql` are demonstration queries; run them manually in the SQL editor. Demo users are `admin@moodmix.demo`, `alex@moodmix.demo`, and `maya@moodmix.demo`; change seeded credentials before deployment. The included deterministic embedding fallback is intentionally offline-friendly; see `docs/vector-strategy.md` for production model integration.
