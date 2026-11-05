import Link from "next/link";
import {cookies} from "next/headers";
import {decodeSession} from "@/lib/auth/session";
import "./globals.css";
export const metadata={title:"Mood-Based Playlist Generator",description:"DBMS level mood-aware playlists"};
export default async function Layout({children}:{children:React.ReactNode}){const session=await decodeSession(cookies().get("session")?.value);return <html lang="en"><body><header className="site-header"><div className="shell nav"><Link href="/" className="brand"><span className="brand-mark">♪</span>MoodMix</Link><nav className="navlinks"><Link href="/dashboard">My playlists</Link>{session?.role==="ADMIN"&&<Link href="/admin">Admin</Link>}{session?<><span className="signed-in">Hi, {session.username}</span><form action="/api/auth/logout" method="post"><button className="logout-button">Log out</button></form></>:<Link href="/login" className="nav-cta">Sign in</Link>}</nav></div></header><main className="shell main">{children}</main><footer className="shell footer">MoodMix · A mood-aware music experience powered by PostgreSQL + pgvector</footer></body></html>}
