import type { PoolClient } from "pg";
import type { Session } from "@/lib/auth/session";
import pool from "@/lib/db/pool";

export async function withDatabaseSession<T>(
  session: Session,
  operation: (client: PoolClient) => Promise<T>,
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query(
      "SELECT set_config('app.user_id', $1, true), set_config('app.role', $2, true)",
      [session.userId, session.role],
    );
    const result = await operation(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
