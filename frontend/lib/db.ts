import { Pool } from "pg";

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error(
    "DATABASE_URL is not configured. Set it in frontend/.env.local.",
  );
}

declare global {
  // eslint-disable-next-line no-var
  var postgresPool: Pool | undefined;
}

export const db =
  globalThis.postgresPool ??
  new Pool({
    connectionString: databaseUrl,
    max: 10,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000,
  });

if (process.env.NODE_ENV !== "production") {
  globalThis.postgresPool = db;
}
