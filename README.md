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

## Local setup

1. Copy `.env.example` to `.env.local` and set the PostgreSQL connection values.
2. Ensure PostgreSQL has the `vector` extension available.
3. Apply the Phase 4 DDL:

   ```text
   psql "$DATABASE_URL" -f database/schema.sql
   ```

4. Verify the required constraints and cascading behavior:

   ```text
   psql "$DATABASE_URL" -f database/verify_schema.sql
   ```

5. Install frontend dependencies:

   ```text
   cd frontend
   npm install
   ```

6. Start the development server:

   ```text
   npm run dev
   ```

The Phase 4 DDL is also documented in
[`database/README.md`](database/README.md). Vector HNSW indexes remain
separate until embeddings and the vector-search workload are available.
