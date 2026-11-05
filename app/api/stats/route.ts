import {NextResponse} from "next/server";
import {cookies} from "next/headers";
import {decodeSession} from "@/lib/auth/session";
import {withDatabaseSession} from "@/lib/db/session";

export const dynamic = "force-dynamic";

export async function GET() {
  const session = await decodeSession(cookies().get("session")?.value);
  if (!session) return NextResponse.json({error: "Unauthorized"}, {status: 401});
  try {
    const stats = await withDatabaseSession(session, async client => {
      const [overview, moods, recent] = await Promise.all([
        client.query(
          `SELECT COUNT(DISTINCT p.playlist_id)::INTEGER AS playlist_count,
                  COUNT(ps.song_id)::INTEGER AS song_count,
                  COALESCE(SUM(s.duration_seconds), 0)::BIGINT AS total_seconds
           FROM playlists p
           LEFT JOIN playlist_songs ps ON ps.playlist_id = p.playlist_id
           LEFT JOIN songs s ON s.song_id = ps.song_id
           WHERE p.user_id = $1`,
          [session.userId],
        ),
        client.query(
          `SELECT m.mood_name, COUNT(p.playlist_id)::INTEGER AS playlist_count
           FROM moods m
           LEFT JOIN playlists p
             ON p.mood_id = m.mood_id AND p.user_id = $1
           GROUP BY m.mood_id, m.mood_name
           ORDER BY playlist_count DESC, m.mood_name`,
          [session.userId],
        ),
        client.query(
          `SELECT DATE_TRUNC('day', created_at)::DATE AS day,
                  COUNT(*)::INTEGER AS playlist_count
           FROM playlists
           WHERE user_id = $1
             AND created_at >= CURRENT_DATE - INTERVAL '6 days'
           GROUP BY day
           ORDER BY day`,
          [session.userId],
        ),
      ]);
      return {
        overview: overview.rows[0],
        moods: moods.rows,
        recent: recent.rows,
      };
    });
    return NextResponse.json(stats);
  } catch (error) {
    console.error("Statistics query failed", error);
    return NextResponse.json({error: "Could not load playlist statistics."}, {status: 503});
  }
}
