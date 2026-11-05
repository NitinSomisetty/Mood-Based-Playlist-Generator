"use client";

import {FormEvent, useEffect, useState} from "react";
import Link from "next/link";

type Song={song_id:string;title:string;artist:string;album:string|null;description:string|null;duration_seconds:number};
const empty={title:"",artist:"",album:"",description:"",durationSeconds:""};

export default function Songs(){
  const [songs,setSongs]=useState<Song[]>([]);
  const [form,setForm]=useState(empty);
  const [editing,setEditing]=useState<string|null>(null);
  const [message,setMessage]=useState("");
  const [loading,setLoading]=useState(true);

  async function load(){
    setLoading(true);
    try{
      const response=await fetch("/api/songs");
      const data=await response.json();
      if(!response.ok)throw new Error(data.error||"Could not load songs");
      setSongs(data.songs||[]);
    }catch(error){setMessage(error instanceof Error?error.message:"Could not load songs")}
    finally{setLoading(false)}
  }
  useEffect(()=>{load()},[]);

  function edit(song:Song){setEditing(song.song_id);setForm({title:song.title,artist:song.artist,album:song.album||"",description:song.description||"",durationSeconds:String(song.duration_seconds)})}
  function reset(){setEditing(null);setForm(empty)}
  async function submit(event:FormEvent){event.preventDefault();setMessage("");const response=await fetch("/api/songs",{method:editing?"PATCH":"POST",headers:{"content-type":"application/json"},body:JSON.stringify({...form,songId:editing||undefined,durationSeconds:Number(form.durationSeconds)})});const data=await response.json();if(!response.ok){setMessage(data.error||"Could not save song");return}setMessage(editing?"Song updated.":"Song added.");reset();await load()}
  async function remove(songId:string){if(!window.confirm("Delete this song? Playlist memberships will cascade."))return;const response=await fetch(`/api/songs?songId=${encodeURIComponent(songId)}`,{method:"DELETE"});if(!response.ok){const data=await response.json();setMessage(data.error||"Could not delete song");return}setMessage("Song deleted.");await load()}

  return <section>
    <Link href="/admin" className="muted">← Admin console</Link>
    <div className="section-head"><div><div className="eyebrow">Content management</div><h1>Song catalogue</h1></div></div>
    {message&&<div className="alert">{message}</div>}
    <div className="card"><h2>{editing?"Edit song":"Add song"}</h2><form className="admin-form" onSubmit={submit}>
      <input className="input" required maxLength={255} placeholder="Title" value={form.title} onChange={event=>setForm({...form,title:event.target.value})}/>
      <input className="input" required maxLength={255} placeholder="Artist" value={form.artist} onChange={event=>setForm({...form,artist:event.target.value})}/>
      <input className="input" placeholder="Album" value={form.album} onChange={event=>setForm({...form,album:event.target.value})}/>
      <input className="input" required min="1" max="86400" type="number" placeholder="Duration (seconds)" value={form.durationSeconds} onChange={event=>setForm({...form,durationSeconds:event.target.value})}/>
      <textarea className="input" maxLength={5000} placeholder="Description" value={form.description} onChange={event=>setForm({...form,description:event.target.value})}/>
      <div><button type="submit">{editing?"Update song":"Add song"}</button>{editing&&<button type="button" className="button secondary cancel-button" onClick={reset}>Cancel</button>}</div>
    </form></div>
    <div className="card catalogue-card"><h2>Catalogue</h2>{loading?<p className="muted">Loading songs...</p>:<div className="table-wrap"><table><thead><tr><th>Title</th><th>Artist</th><th>Duration</th><th>Actions</th></tr></thead><tbody>{songs.map(song=><tr key={song.song_id}><td>{song.title}</td><td>{song.artist}</td><td>{song.duration_seconds}s</td><td><button className="small-button" onClick={()=>edit(song)}>Edit</button><button className="small-button danger-button" onClick={()=>remove(song.song_id)}>Delete</button></td></tr>)}</tbody></table>{!songs.length&&<p className="muted">No songs found.</p>}</div>}</div>
  </section>
}
