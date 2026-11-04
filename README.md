# Mood-Based Playlist Generator

A Next.js and PostgreSQL application that generates playlists from predefined moods
or natural-language mood descriptions. The project demonstrates relational
database design, pgvector similarity search, authentication, and advanced SQL.

## Project structure

- `frontend/` - Next.js application, API routes, and shared server/client code
- `database/` - PostgreSQL schema, seed data, queries, functions, and triggers
- `embeddings/` - Python tooling for generating 384-dimensional embeddings
- `documentation/` - ER diagram, relational schema, and project report
- `tests/` - Application and database test suites

## Local setup

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

Database scripts and embedding setup will be added incrementally as features are
implemented.
