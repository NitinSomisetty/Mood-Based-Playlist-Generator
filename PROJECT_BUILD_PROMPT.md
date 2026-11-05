# Build Prompt: Mood-Based Playlist Generator (DBMS Level 3 Mini Project)

> Paste this entire file into Claude Code / Cursor / an AI coding agent as the
> first instruction. It specifies a complete, working, DBMS-focused project.
> Every numbered section is a requirement from the course rubric
> (`References.txt`) — do not skip any of them. Comment all SQL and all
> non-trivial code explaining *why*, not just *what*.

## 0. Project identity

- **Title:** Mood-Based Playlist Generator
- **Team:** Nitin Somisetty (PES2UG24CS327), Nishit Suresh (PES2UG24CS326)
- **Stack:** Next.js 14 (App Router) + Next.js API routes, PostgreSQL via
  **Supabase** with the `pgvector` extension, TypeScript, `pg` driver (raw
  SQL — no ORM, so every query is visible and gradeable).
- **Why raw SQL, not an ORM:** the rubric evaluates DDL, DML, joins,
  subqueries, triggers, functions, CTEs, and vector search directly. An ORM
  would hide exactly what's being graded. Use the `pg` package and write
  SQL by hand in `lib/db/queries/*.ts`.

## 1. Non-negotiable deliverables (map to rubric)

| # | Requirement | Where it lives |
|---|---|---|
| 1 | ER diagram | `docs/er-diagram.png` (already supplied) |
| 2 | Relational schema w/ keys, relationships, constraints | `docs/relational-schema.md` (already supplied) |
| 3 | SQL DDL with constraints | `db/01_schema.sql` |
| 4 | Vector DB (pgvector) | embedded in `01_schema.sql` + `db/05_vector_search.sql` |
| 5 | Tech justification | `docs/tech-justification.md` |
| 6 | DML operations | `db/02_seed_data.sql`, `db/03_dml_examples.sql` |
| 7 | Nested/correlated/recursive, JOIN queries | `db/03_dml_examples.sql` |
| 8 | Advanced SQL: functions, triggers, CTEs, views | `db/04_advanced.sql` |
| 9 | Next.js interface | `app/` |
| 10 | Backend/API + DB integration | `app/api/**/route.ts`, `lib/db/*` |
| 11 | Auth, 2 roles, RBAC in DB | `lib/auth/*`, `role` column + RLS policies |
| 12 | Documentation, Git/GitHub | `README.md`, commit discipline |
| 13 | Originality / individual contribution | commit history, `docs/contributions.md` |

## 2. Database schema (use this exact schema — it supersedes the DDL.sql previously drafted)

Implement **exactly** the relations below in `db/01_schema.sql`. This is the
schema from `Relational_Schema.md` and `er_diagram.png`, with UUID primary
keys, a `SONG_MOODS` many-to-many junction, and a `PLAYLIST_HISTORY` audit
table — richer than the first draft, so use this version.

```sql
-- ================================================================
-- db/01_schema.sql
-- Mood-Based Playlist Generator — DDL
-- Run this once against a fresh Supabase/Postgres database.
-- ================================================================

-- Needed for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- Needed for embedding columns + vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- ----------------------------------------------------------------
-- ROLE ENUM — backs Role-Based Access Control (RBAC).
-- Using an enum (not free text) means the database itself rejects
-- any role value outside {USER, ADMIN} — this is the DB-level
-- enforcement the rubric asks for, independent of the frontend.
-- ----------------------------------------------------------------
CREATE TYPE user_role AS ENUM ('USER', 'ADMIN');

-- ----------------------------------------------------------------
-- USERS
-- ----------------------------------------------------------------
CREATE TABLE users (
  user_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username        VARCHAR(50)  UNIQUE NOT NULL,
  email           VARCHAR(100) UNIQUE NOT NULL,
  password_hash   TEXT NOT NULL,              -- bcrypt hash, never plaintext
  role            user_role NOT NULL DEFAULT 'USER',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------
-- MOODS — predefined moods, each with a semantic embedding so
-- natural-language mood input can be matched via vector similarity.
-- ----------------------------------------------------------------
CREATE TABLE moods (
  mood_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mood_name     VARCHAR(100) UNIQUE NOT NULL,
  description   TEXT NOT NULL,
  embedding     vector(384) NOT NULL,         -- all-MiniLM-L6-v2 output size
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------
-- SONGS
-- ----------------------------------------------------------------
CREATE TABLE songs (
  song_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title              VARCHAR(255) NOT NULL,
  artist             VARCHAR(255) NOT NULL,
  album              VARCHAR(255),
  lyrics             TEXT,
  description        TEXT,
  duration_seconds   INT NOT NULL CHECK (duration_seconds > 0),
  embedding          vector(384),             -- nullable: not every song is embedded yet
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------
-- PLAYLISTS — a user-owned collection, optionally tied to a
-- predefined mood (mood_id) and/or free-text mood input.
-- ----------------------------------------------------------------
CREATE TABLE playlists (
  playlist_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  mood_id       UUID REFERENCES moods(mood_id) ON DELETE SET NULL,
  name          VARCHAR(255) NOT NULL,
  mood_input    TEXT,                          -- raw natural-language prompt, if used
  is_saved      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------
-- PLAYLIST_SONGS — junction table, composite PK guarantees a song
-- appears at most once per playlist. position orders the songs.
-- ----------------------------------------------------------------
CREATE TABLE playlist_songs (
  playlist_id       UUID NOT NULL REFERENCES playlists(playlist_id) ON DELETE CASCADE,
  song_id           UUID NOT NULL REFERENCES songs(song_id) ON DELETE CASCADE,
  position          INT NOT NULL,
  relevance_score   NUMERIC(4,3) NOT NULL CHECK (relevance_score BETWEEN 0.0 AND 1.0),
  added_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (playlist_id, song_id)
);

-- ----------------------------------------------------------------
-- SONG_MOODS — many-to-many: a song can fit several moods, each
-- with its own relevance score (from vector similarity at index time).
-- ----------------------------------------------------------------
CREATE TABLE song_moods (
  song_id           UUID NOT NULL REFERENCES songs(song_id) ON DELETE CASCADE,
  mood_id           UUID NOT NULL REFERENCES moods(mood_id) ON DELETE CASCADE,
  relevance_score   NUMERIC(4,3) NOT NULL CHECK (relevance_score BETWEEN 0.0 AND 1.0),
  PRIMARY KEY (song_id, mood_id)
);

-- ----------------------------------------------------------------
-- MOOD_STATS — daily aggregate counters per mood (one row per
-- mood per day), fed by the trigger in 04_advanced.sql.
-- ----------------------------------------------------------------
CREATE TABLE mood_stats (
  mood_stat_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mood_id           UUID NOT NULL REFERENCES moods(mood_id) ON DELETE CASCADE,
  stat_date         DATE NOT NULL DEFAULT CURRENT_DATE,
  generated_count   INT NOT NULL DEFAULT 0,
  saved_count       INT NOT NULL DEFAULT 0,
  UNIQUE (mood_id, stat_date)
);

-- ----------------------------------------------------------------
-- PLAYLIST_HISTORY — audit log of every generation event, even ones
-- the user never saves as a playlist (playlist_id nullable).
-- ----------------------------------------------------------------
CREATE TABLE playlist_history (
  history_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  playlist_id   UUID REFERENCES playlists(playlist_id) ON DELETE SET NULL,
  mood_id       UUID REFERENCES moods(mood_id) ON DELETE SET NULL,
  input_text    TEXT,
  generated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------
-- INDEXES
-- ----------------------------------------------------------------
-- Vector similarity indexes (ANN search via ivfflat, cosine distance)
CREATE INDEX idx_songs_embedding  ON songs  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_moods_embedding  ON moods  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 50);

-- Foreign-key / lookup indexes (Postgres does not auto-index FKs)
CREATE INDEX idx_playlists_user_id        ON playlists(user_id);
CREATE INDEX idx_playlists_mood_id        ON playlists(mood_id);
CREATE INDEX idx_playlist_songs_song_id   ON playlist_songs(song_id);
CREATE INDEX idx_song_moods_mood_id       ON song_moods(mood_id);
CREATE INDEX idx_mood_stats_date          ON mood_stats(stat_date);
CREATE INDEX idx_playlist_history_user_id ON playlist_history(user_id);

-- Composite index for a common access pattern: "this user's playlists for this mood"
CREATE INDEX idx_playlists_user_mood ON playlists(user_id, mood_id);

-- Full-text search index for lyric/description search (advanced feature #4)
ALTER TABLE songs ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(artist,'') || ' ' || coalesce(lyrics,''))) STORED;
CREATE INDEX idx_songs_search_vector ON songs USING GIN (search_vector);
```

Also create `db/00_extensions_check.sql` with a single verification query
that lists installed extensions, for the demo.

## 3. DML — `db/02_seed_data.sql` and `db/03_dml_examples.sql`

**Seed data (`02_seed_data.sql`):** at least 3 users (1 admin, 2 regular,
bcrypt-hashed passwords — generate real hashes, don't fake them), 8 moods,
40+ songs with realistic embeddings (use `pgvector`'s random/normalized
vectors for seed purposes, comment that production embeddings come from the
app's embedding pipeline), playlists, playlist_songs, song_moods.

**DML examples (`03_dml_examples.sql`) — comment every query with what it
demonstrates:**
- `INSERT ... RETURNING` to create a playlist and get its id back
- `UPDATE` a playlist's `is_saved` flag
- `DELETE` a song from a playlist (respecting the composite key)
- A plain multi-table `JOIN`: all songs in a given playlist with their mood tags
- A `GROUP BY` + `HAVING` + aggregate: moods with more than N generated playlists
- A **correlated subquery**: users who have never saved a playlist
  (`WHERE NOT EXISTS (SELECT 1 FROM playlists p WHERE p.user_id = u.user_id AND p.is_saved)`)
- A **nested subquery**: top 5 songs by how many playlists include them
- A **recursive CTE**: not naturally present in this schema, so add one
  genuinely useful recursive query — e.g. a `WITH RECURSIVE` that walks a
  user's `playlist_history` to build a session timeline, or (simpler and
  honest) a recursive series generator used to backfill `mood_stats` for a
  date range. Comment clearly that this is included specifically to
  demonstrate recursive CTE syntax since the domain doesn't have a natural
  hierarchy.

## 4. Advanced SQL — `db/04_advanced.sql` (need ≥4; include all 5 below)

1. **Trigger + function:** after INSERT on `playlist_history`, upsert
   `mood_stats.generated_count` for that mood/day. After UPDATE on
   `playlists` setting `is_saved = true`, increment `saved_count`.
2. **Stored function:** `get_similar_songs(query_embedding vector(384), result_limit int)`
   returns songs ordered by cosine distance — used by the API route.
3. **View:** `public_playlists_view` joining playlists, users (username
   only, never password_hash), moods, and a song count.
4. **CTE:** a non-recursive CTE ranking songs per mood by relevance_score
   using `ROW_NUMBER() OVER (PARTITION BY mood_id ORDER BY relevance_score DESC)`.
5. **Full-text search query** using the `search_vector` column from
   section 2, with `ts_rank` to order results.

Every object must have a `COMMENT ON FUNCTION/TRIGGER/VIEW ...` SQL comment
in addition to inline `--` comments, so `\df+`, `\dv` etc. are self-documenting
during the viva.

## 5. Vector search — `db/05_vector_search.sql` + `docs/vector-strategy.md`

Document in `docs/vector-strategy.md`:
- **What's embedded:** song `title + artist + lyrics + description`
  concatenated; mood `mood_name + description`.
- **Model:** `all-MiniLM-L6-v2` (sentence-transformers), 384 dimensions,
  chosen for being small enough to run cheaply at seed/index time and for
  matching `vector(384)` in the schema.
- **Storage:** `pgvector`'s `vector(384)` column type, directly inside
  Postgres — this is the justification for pgvector over a separate vector
  DB (Pinecone/Chroma): avoids a second system, avoids cross-DB joins, and
  keeps ACID guarantees across the relational and vector data in one
  transaction.
- **Similarity metric:** cosine distance (`<=>` operator), matching the
  `vector_cosine_ops` index operator class.
- **Retrieval flow:** user mood text → embedding generated server-side (API
  route calls an embedding service/local model) → `get_similar_songs()`
  function called with that vector → top-K songs → inserted into a new
  playlist with `relevance_score` set from `1 - cosine_distance`.

Include the actual similarity query, commented:

```sql
-- Given a query embedding, return the 20 closest songs by cosine distance.
-- `<=>` is pgvector's cosine distance operator (0 = identical direction).
SELECT song_id, title, artist, 1 - (embedding <=> $1) AS similarity
FROM songs
WHERE embedding IS NOT NULL
ORDER BY embedding <=> $1
LIMIT 20;
```

## 6. Auth + RBAC (section 11 of the rubric)

- Passwords hashed with `bcrypt` (never plaintext, never reversible).
- Session via `next-auth` (Credentials provider) or a signed JWT in an
  httpOnly cookie — pick one, document the choice in
  `docs/tech-justification.md`.
- **Two roles: `USER` and `ADMIN`**, stored in the `role` enum column.
- **DB-level RBAC, not just frontend checks:** enable Row-Level Security
  (RLS) on `users`, `playlists`, `playlist_history` in Supabase:
  - Users can only `SELECT`/`UPDATE`/`DELETE` their own rows
    (`auth.uid() = user_id` if using Supabase Auth, or a session-scoped
    Postgres role/claim if using custom auth — document whichever is used).
  - Admins (role = 'ADMIN') get a policy allowing access to all rows.
  - Write the RLS policies in `db/06_rls_policies.sql`, fully commented,
    and explain in the report that this is enforcement *inside the
    database*, independent of any frontend bug.
- Frontend: middleware (`middleware.ts`) blocking `/admin/*` routes for
  non-admins; API routes re-check role server-side (never trust the client).

## 7. Next.js app structure

```
app/
  layout.tsx
  page.tsx                          -- landing / mood input
  login/page.tsx
  register/page.tsx
  playlist/[id]/page.tsx            -- view a generated/saved playlist
  dashboard/page.tsx                -- user's saved playlists
  admin/
    page.tsx                        -- admin-only: manage songs/moods
    songs/page.tsx
  api/
    auth/[...nextauth]/route.ts     -- or custom login/register routes
    moods/route.ts                  -- GET all moods
    playlists/route.ts              -- POST generate, GET user's playlists
    playlists/[id]/route.ts         -- GET/PATCH/DELETE one playlist
    songs/route.ts                  -- ADMIN: CRUD songs
    search/route.ts                 -- vector similarity search endpoint
lib/
  db/
    pool.ts                         -- Supabase-ready pg Pool (see §8)
    queries/
      moods.ts
      playlists.ts
      songs.ts
      stats.ts
  auth/
    hash.ts                         -- bcrypt wrappers
    session.ts
  embeddings/
    embed.ts                        -- wraps the embedding model/service
db/
  00_extensions_check.sql
  01_schema.sql
  02_seed_data.sql
  03_dml_examples.sql
  04_advanced.sql
  05_vector_search.sql
  06_rls_policies.sql
docs/
  er-diagram.png                    -- (supplied)
  relational-schema.md              -- (supplied)
  tech-justification.md
  vector-strategy.md
  contributions.md
.env.example
.env.local                          -- gitignored
README.md
```

## 8. Supabase connection — make this fully working out of the box

Create `lib/db/pool.ts`:

```ts
// lib/db/pool.ts
// Single shared connection pool for all API routes.
// Works against Supabase's pooled Postgres connection string.
import { Pool } from 'pg';

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is not set. Copy .env.example to .env.local and fill it in.');
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Supabase requires SSL; rejectUnauthorized: false is standard for their
  // pooled connection since they use a managed cert chain not in the
  // default Node trust store.
  ssl: { rejectUnauthorized: false },
  max: 10,
});

export default pool;
```

Create `.env.example` (committed) and instruct the user to copy it to
`.env.local` (gitignored):

```env
# Copy this file to .env.local and fill in real values. Never commit .env.local.

# Supabase → Project Settings → Database → Connection string → Session pooler
DATABASE_URL=postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres

# Only needed if using Supabase Auth instead of custom JWT/bcrypt auth
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=

# Secret for signing session JWTs if not using Supabase Auth
AUTH_SECRET=
```

Add a `scripts/db-setup.sh` that runs all `db/*.sql` files in order against
`$DATABASE_URL`, so setup is one command:

```bash
#!/usr/bin/env bash
# scripts/db-setup.sh
# Applies the full schema + seed data + advanced SQL to the database
# pointed to by DATABASE_URL, in the correct order.
set -euo pipefail
: "${DATABASE_URL:?Set DATABASE_URL first (see .env.example)}"

for f in db/00_extensions_check.sql db/01_schema.sql db/02_seed_data.sql \
         db/04_advanced.sql db/06_rls_policies.sql; do
  echo "Applying $f..."
  psql "$DATABASE_URL" -f "$f"
done
echo "Database setup complete."
```

(`03_dml_examples.sql` and `05_vector_search.sql` are query demonstrations,
not setup scripts — run them manually in the SQL editor during the demo,
note this in README.)

## 9. README.md must include

- Project overview + problem statement (not just CRUD — justify this)
- Setup: clone → `npm install` → create Supabase project → enable
  `vector` extension → copy `.env.example` → `./scripts/db-setup.sh` →
  `npm run dev`
- Architecture diagram (can be ASCII) showing Next.js → API routes → pg
  Pool → Supabase Postgres (+ pgvector)
- How to run the demo queries in `03_dml_examples.sql` / `05_vector_search.sql`
- Roles and how to get admin access for grading (e.g. a seeded admin
  account's credentials, clearly marked as demo-only)

## 10. Git/GitHub discipline

- Both teammates commit under their own name/email (`git config user.name`)
- Commit in small, labeled chunks matching the sections above (e.g.
  `feat(db): add schema with RLS policies`, `feat(api): playlist generation route`)
- `.gitignore` must include `.env.local`, `node_modules`, `.next`
- `docs/contributions.md`: a short table of who did what, for the
  "individual contribution" rubric line

## 11. Build order (do it in this sequence, verify each step works before moving on)

1. `db/01_schema.sql` → run against Supabase, confirm tables in Table Editor
2. `db/02_seed_data.sql` → run, confirm row counts
3. `lib/db/pool.ts` + one API route (`/api/moods`) → confirm JSON returns
4. Auth: register/login + bcrypt + session → confirm login works end-to-end
5. `db/04_advanced.sql` (trigger/function/view/CTE/full-text) → run, test
   each manually in SQL editor
6. `db/06_rls_policies.sql` → enable, test as both roles
7. Core UI: mood input → `/api/search` (vector) → generate playlist →
   save playlist
8. Admin pages (songs CRUD)
9. `db/03_dml_examples.sql` + `db/05_vector_search.sql` written up for the
   report, run once more to confirm they still work against seeded data
10. README + docs + screenshots + final commit pass

---

**Agent instructions:** Build this as a real, runnable repository. Do not
stub out the database logic — every API route must execute real SQL
against the pool from `lib/db/pool.ts`. Do not fabricate query results.
After scaffolding, run `npm run build` and fix any TypeScript errors before
declaring a step done.
