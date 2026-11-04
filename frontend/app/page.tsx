"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
import styles from "./page.module.css";

type Mood = { mood_id: number; mood_name: string };
type Song = {
  song_id: number;
  title: string;
  artist: string;
  duration: number | null;
  mood_name: string | null;
};
type Playlist = {
  playlist_id: number;
  title: string;
  is_public: boolean;
  song_count: number;
};

const emptySong = { title: "", artist: "", duration: "", moodId: "" };

export default function Home() {
  const [moods, setMoods] = useState<Mood[]>([]);
  const [songs, setSongs] = useState<Song[]>([]);
  const [playlists, setPlaylists] = useState<Playlist[]>([]);
  const [moodId, setMoodId] = useState("");
  const [songForm, setSongForm] = useState(emptySong);
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch(`/api/library${moodId ? `?moodId=${moodId}` : ""}`);
      const data = await response.json();
      if (!response.ok) throw new Error(data.error);
      setMoods(data.moods);
      setSongs(data.songs);
      setPlaylists(data.playlists);
    } finally {
      setLoading(false);
    }
  }, [moodId]);

  useEffect(() => {
    loadData().catch((error: Error) => setMessage(error.message));
  }, [loadData]);

  async function addSong(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try {
      const response = await fetch("/api/library", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(songForm),
      });
      const data = await response.json();
      setMessage(response.ok ? "Song added." : data.error);
      if (response.ok) {
        setSongForm(emptySong);
        await loadData();
      }
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Song could not be added.");
    }
  }

  async function renamePlaylist(playlist: Playlist) {
    const title = window.prompt("New playlist title", playlist.title)?.trim();
    if (!title) return;
    try {
      const response = await fetch("/api/library", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playlistId: playlist.playlist_id, title }),
      });
      const data = await response.json();
      setMessage(response.ok ? "Playlist updated." : data.error);
      if (response.ok) await loadData();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Playlist could not be updated.");
    }
  }

  async function deletePlaylist(playlistId: number) {
    try {
      const response = await fetch(`/api/library?playlistId=${playlistId}`, { method: "DELETE" });
      const data = await response.json();
      setMessage(response.ok ? "Saved playlist deleted." : data.error);
      if (response.ok) await loadData();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Playlist could not be deleted.");
    }
  }

  return (
    <div className={styles.page}>
      <main className={styles.main}>
        <p className={styles.eyebrow}>MOOD-BASED PLAYLIST GENERATOR</p>
        <h1>Build a soundtrack for how you feel.</h1>
        <p className={styles.lede}>Add songs, filter by mood, and manage saved playlists with PostgreSQL.</p>
        {message && <p className={styles.message}>{message}</p>}

        <section className={styles.card}>
          <h2>Add a song</h2>
          <form className={styles.form} onSubmit={addSong}>
            <input required placeholder="Song title" value={songForm.title} onChange={(event) => setSongForm({ ...songForm, title: event.target.value })} />
            <input required placeholder="Artist" value={songForm.artist} onChange={(event) => setSongForm({ ...songForm, artist: event.target.value })} />
            <input required min="1" type="number" placeholder="Duration (seconds)" value={songForm.duration} onChange={(event) => setSongForm({ ...songForm, duration: event.target.value })} />
            <select required value={songForm.moodId} onChange={(event) => setSongForm({ ...songForm, moodId: event.target.value })}>
              <option value="">Choose mood</option>
              {moods.map((mood) => <option key={mood.mood_id} value={mood.mood_id}>{mood.mood_name}</option>)}
            </select>
            <button className={styles.primary} type="submit">Add song</button>
          </form>
        </section>

        <section className={styles.card}>
          <div className={styles.sectionHeader}>
            <h2>Songs</h2>
            <select aria-label="Filter songs by mood" value={moodId} onChange={(event) => setMoodId(event.target.value)}>
              <option value="">All moods</option>
              {moods.map((mood) => <option key={mood.mood_id} value={mood.mood_id}>{mood.mood_name}</option>)}
            </select>
          </div>
          <div className={styles.list}>
            {loading && <p>Loading library...</p>}
            {songs.map((song) => <div className={styles.row} key={song.song_id}><span><strong>{song.title}</strong><small>{song.artist} · {song.mood_name ?? "Unassigned"}</small></span><span>{song.duration ?? "—"} sec</span></div>)}
            {!loading && !songs.length && <p>No songs found for this mood.</p>}
          </div>
        </section>

        <section className={styles.card}>
          <h2>Saved playlists</h2>
          <div className={styles.list}>
            {playlists.filter((playlist) => !playlist.is_public).map((playlist) => <div className={styles.row} key={playlist.playlist_id}><span><strong>{playlist.title}</strong><small>{playlist.song_count} songs</small></span><span className={styles.actions}><button onClick={() => renamePlaylist(playlist)}>Rename</button><button onClick={() => deletePlaylist(playlist.playlist_id)}>Delete</button></span></div>)}
            {!playlists.some((playlist) => !playlist.is_public) && <p>No saved playlists found.</p>}
          </div>
        </section>
      </main>
    </div>
  );
}
