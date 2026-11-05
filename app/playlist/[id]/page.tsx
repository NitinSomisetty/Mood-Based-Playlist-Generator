"use client";

import {useEffect,useState} from "react";
import Link from "next/link";

type Song={title:string;artist:string;position:number};
type Playlist={name:string;mood_input:string;is_saved:boolean;songs:Song[]};

export default function Playlist({params}:{params:{id:string}}){
  const [playlist,setPlaylist]=useState<Playlist|null>(null);
  const [error,setError]=useState("");
  const [saving,setSaving]=useState(false);
  const [deleting,setDeleting]=useState(false);

  useEffect(()=>{
    fetch(`/api/playlists/${params.id}`)
      .then(async response=>{
        const data=await readResponse<Playlist>(response);
        if(!response.ok) throw new Error(data.error||"Could not load playlist");
        setPlaylist(data);
      })
      .catch(error=>setError(error instanceof Error?error.message:"Could not load playlist"));
  },[params.id]);

  async function toggleSaved(){
    if(!playlist) return;
    setSaving(true);
    try{
      const response=await fetch(`/api/playlists/${params.id}`,{
        method:"PATCH",
        headers:{"content-type":"application/json"},
        body:JSON.stringify({isSaved:!playlist.is_saved})
      });
      const data=await readResponse<Playlist>(response);
      if(!response.ok) throw new Error(data.error||"Could not update playlist");
      setPlaylist({...playlist,is_saved:data.is_saved});
    }catch(error){
      setError(error instanceof Error?error.message:"Could not update playlist");
    }finally{
      setSaving(false);
    }
  }

  async function deletePlaylist(){
      if(!playlist||!window.confirm("Delete this playlist permanently?")) return;
      setDeleting(true);
      setError("");
      try{
        const response=await fetch(`/api/playlists/${params.id}`,{method:"DELETE"});
        if(!response.ok){
          const data=await readResponse<{error?:string}>(response);
          throw new Error(data.error||"Could not delete playlist");
        }
        window.location.href="/dashboard";
      }catch(error){
        setError(error instanceof Error?error.message:"Could not delete playlist");
        setDeleting(false);
    }
  }

  if(error) return <section><div className="card"><h1>Playlist unavailable</h1><p>{error}</p>{error==="Unauthorized"&&<Link className="button" href="/login">Sign in →</Link>}</div></section>;
  if(!playlist) return <section><p className="muted">Loading playlist...</p></section>;

  return <section><Link href="/dashboard" className="muted">← Back to collection</Link><div className="playlist-top"><div><div className="eyebrow">Your generated mix</div><h1>{playlist.name}</h1><p className="muted">Built around “{playlist.mood_input}” · {playlist.songs?.length||0} tracks</p></div><div className="playlist-actions"><button onClick={toggleSaved} disabled={saving||deleting}>{saving?"Saving...":playlist.is_saved?"Saved to library":"Save playlist"}</button><button className="danger-button" onClick={deletePlaylist} disabled={saving||deleting}>{deleting?"Deleting...":"Delete"}</button></div></div>{error&&<div className="alert" role="alert">{error}</div>}<div className="card song-list">{playlist.songs?.length ? playlist.songs.map(song=><div className="song-row" key={`${song.position}-${song.title}`}><span className="song-number">{String(song.position).padStart(2,"0")}</span><div><div className="song-title">{song.title}</div><div className="song-artist">{song.artist}</div></div><span className="song-dot"/></div>) : <p className="muted">No songs were found. Re-run the seed script, then generate a new playlist.</p>}</div></section>;
}

async function readResponse<T extends object>(response:Response):Promise<T & {error?:string}>{
  const text=await response.text();
  if(!text) return {error:`Request failed (${response.status})`} as T & {error:string};
  try{return JSON.parse(text) as T & {error?:string}}catch{return {error:`Request failed (${response.status})`} as T & {error:string};}
}
