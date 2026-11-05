"use client";
import {useEffect,useState} from "react";
import Link from "next/link";

type Playlist={playlist_id:string;name:string;mood_input:string;is_saved:boolean;created_at:string};

export default function Dashboard(){
  const [playlists,setPlaylists]=useState<Playlist[]>([]);
  const [error,setError]=useState("");
  useEffect(()=>{fetch("/api/playlists").then(async response=>{const data=await response.json();if(!response.ok)throw new Error(data.error||"Could not load playlists");setPlaylists(data.playlists||[])}).catch(error=>setError(error instanceof Error?error.message:"Could not load playlists"))},[]);
  return <section><div className="section-head"><div><div className="eyebrow">Your collection</div><h1>My playlists</h1></div><Link className="button" href="/">+ Create a mix</Link></div>{error&&<div className="alert"><p>{error}</p><Link href="/login">Sign in →</Link></div>}{!error&&!playlists.length&&<div className="card"><h2>Your library is waiting.</h2><p className="muted">Describe a mood and your first playlist will appear here.</p><Link className="button" href="/">Generate a playlist →</Link></div>}<div className="grid">{playlists.map(playlist=><Link className="card playlist-card" href={`/playlist/${playlist.playlist_id}`} key={playlist.playlist_id}><div><span className="status">{playlist.is_saved?"Saved mix":"Generated mix"}</span><h2>{playlist.name}</h2><p className="muted">{playlist.mood_input}</p></div><span className="muted">Open playlist →</span></Link>)}</div></section>
}
