import { NextRequest, NextResponse } from "next/server";
import type { QueryResultRow } from "pg";
import { db } from "@/lib/db";

type SongRow = QueryResultRow & {
  song_id: number;
  title: string;
  artist: string;
  duration: number | null;
  mood_name: string | null;
};

function parsePositiveInteger(value: string | null, field: string): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`${field} must be a positive integer.`);
  }
  return parsed;
}

export async function GET(request: NextRequest) {
  try {
    const moodId = request.nextUrl.searchParams.get("moodId");
    const userId = request.nextUrl.searchParams.get("userId");

    const [moods, songs, playlists] = await Promise.all([
      db.query(
        "SELECT mood_id, mood_name FROM moods ORDER BY mood_name",
      ),
      db.query<SongRow>(
        `SELECT s.song_id, s.title, s.artist, s.duration,
                STRING_AGG(DISTINCT m.mood_name, ', ' ORDER BY m.mood_name) AS mood_name
         FROM songs AS s
         LEFT JOIN song_moods AS sm ON sm.song_id = s.song_id
         LEFT JOIN moods AS m ON m.mood_id = sm.mood_id
         WHERE (
           $1::BIGINT IS NULL
           OR EXISTS (
             SELECT 1
             FROM song_moods AS filter_sm
             WHERE filter_sm.song_id = s.song_id
               AND filter_sm.mood_id = $1
           )
         )
         GROUP BY s.song_id, s.title, s.artist, s.duration
         ORDER BY s.title, s.song_id`,
        [moodId ? parsePositiveInteger(moodId, "moodId") : null],
      ),
      db.query(
        `SELECT p.playlist_id, p.title, p.is_public, p.created_at,
                COUNT(ps.song_id)::INTEGER AS song_count
         FROM playlists AS p
         LEFT JOIN playlist_songs AS ps ON ps.playlist_id = p.playlist_id
         WHERE ($1::BIGINT IS NULL OR p.user_id = $1)
         GROUP BY p.playlist_id
         ORDER BY p.created_at DESC`,
        [userId ? parsePositiveInteger(userId, "userId") : null],
      ),
    ]);

    return NextResponse.json({
      moods: moods.rows,
      songs: songs.rows,
      playlists: playlists.rows,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Database query failed.";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const title = typeof body.title === "string" ? body.title.trim() : "";
    const artist = typeof body.artist === "string" ? body.artist.trim() : "";
    const duration = Number(body.duration);
    const moodId = Number(body.moodId);

    if (!title || !artist || !Number.isInteger(duration) || duration <= 0) {
      return NextResponse.json(
        { error: "Title, artist, and a positive integer duration are required." },
        { status: 400 },
      );
    }
    if (!Number.isInteger(moodId) || moodId <= 0) {
      return NextResponse.json(
        { error: "A valid mood is required." },
        { status: 400 },
      );
    }

    const client = await db.connect();
    try {
      await client.query("BEGIN");
      const song = await client.query(
        `INSERT INTO songs (title, artist, duration)
         VALUES ($1, $2, $3)
         RETURNING song_id, title, artist, duration`,
        [title, artist, duration],
      );
      await client.query(
        `INSERT INTO song_moods (song_id, mood_id)
         VALUES ($1, $2)`,
        [song.rows[0].song_id, moodId],
      );
      await client.query("COMMIT");
      return NextResponse.json({ song: song.rows[0] }, { status: 201 });
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "Song could not be added.";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const body = await request.json();
    const playlistId = Number(body.playlistId);
    const title = typeof body.title === "string" ? body.title.trim() : "";
    if (!Number.isInteger(playlistId) || playlistId <= 0 || !title) {
      return NextResponse.json(
        { error: "A valid playlist and non-empty title are required." },
        { status: 400 },
      );
    }

    const result = await db.query(
      `UPDATE playlists
       SET title = $1
       WHERE playlist_id = $2
       RETURNING playlist_id, title, updated_at`,
      [title, playlistId],
    );
    if (result.rowCount === 0) {
      return NextResponse.json({ error: "Playlist not found." }, { status: 404 });
    }
    return NextResponse.json({ playlist: result.rows[0] });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Playlist could not be updated.";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const playlistId = parsePositiveInteger(
      request.nextUrl.searchParams.get("playlistId"),
      "playlistId",
    );
    const result = await db.query(
      `DELETE FROM playlists
       WHERE playlist_id = $1 AND is_public = FALSE
       RETURNING playlist_id`,
      [playlistId],
    );
    if (result.rowCount === 0) {
      return NextResponse.json(
        { error: "Saved private playlist not found." },
        { status: 404 },
      );
    }
    return NextResponse.json({ deletedPlaylistId: result.rows[0].playlist_id });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Playlist could not be deleted.";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
