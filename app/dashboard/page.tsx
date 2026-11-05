"use client";

import {useEffect, useState} from "react";
import Link from "next/link";

type Playlist={playlist_id:string;name:string;mood_input:string;is_saved:boolean;created_at:string};
type Stats={overview:{playlist_count:number;song_count:number;total_seconds:number};moods:{mood_name:string;playlist_count:number}[];recent:{day:string;playlist_count:number}[]};

export default function Dashboard(){
  const [playlists,setPlaylists]=useState<Playlist[]>([]);
  const [stats,setStats]=useState<Stats|null>(null);
  const [error,setError]=useState("");
  useEffect(()=>{
    Promise.all([fetch("/api/playlists"),fetch("/api/stats")]).then(async([playlistsResponse,statsResponse])=>{
      const playlistsData=await playlistsResponse.json();
      const statsData=await statsResponse.json();
      if(!playlistsResponse.ok)throw new Error(playlistsData.error||"Could not load playlists");
      if(!statsResponse.ok)throw new Error(statsData.error||"Could not load statistics");
      setPlaylists(playlistsData.playlists||[]);
      setStats(statsData);
    }).catch(error=>setError(error instanceof Error?error.message:"Could not load dashboard"));
  },[]);
  return <section>
    <div className="section-head"><div><div className="eyebrow">Your collection</div><h1>My playlists</h1></div><Link className="button" href="/">+ Create a mix</Link></div>
    {error&&<div className="alert"><p>{error}</p><Link href="/login">Sign in →</Link></div>}
    {stats&&<div className="stats-grid">
      <div className="card stat-card"><span className="muted">Playlists</span><strong>{stats.overview.playlist_count}</strong></div>
      <div className="card stat-card"><span className="muted">Tracks collected</span><strong>{stats.overview.song_count}</strong></div>
      <div className="card stat-card"><span className="muted">Listening time</span><strong>{Math.round(Number(stats.overview.total_seconds||0)/60)} min</strong></div>
    </div>}
    {stats&&<div className="dashboard-columns">
      <div className="card"><h2>Most explored moods</h2>{stats.moods.slice(0,5).map(mood=><div className="metric-row" key={mood.mood_name}><span>{mood.mood_name}</span><strong>{mood.playlist_count}</strong></div>)}</div>
      <div className="card"><h2>Last seven days</h2>{stats.recent.length?stats.recent.map(day=><div className="metric-row" key={day.day}><span>{day.day}</span><strong>{day.playlist_count}</strong></div>):<p className="muted">No recent playlist activity.</p>}</div>
    </div>}
    {!error&&!playlists.length&&<div className="card"><h2>Your library is waiting.</h2><p className="muted">Describe a mood and your first playlist will appear here.</p><Link className="button" href="/">Generate a playlist →</Link></div>}
    <div className="grid">{playlists.map(playlist=><Link className="card playlist-card" href={`/playlist/${playlist.playlist_id}`} key={playlist.playlist_id}><div><span className="status">{playlist.is_saved?"Saved mix":"Generated mix"}</span><h2>{playlist.name}</h2><p className="muted">{playlist.mood_input}</p></div><span className="muted">Open playlist →</span></Link>)}</div>
  </section>
}
