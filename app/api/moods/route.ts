import {NextResponse} from "next/server";import pool from "@/lib/db/pool";
export const dynamic="force-dynamic";
export async function GET(){try{const r=await pool.query("SELECT mood_id,mood_name,description FROM moods ORDER BY mood_name");return NextResponse.json({moods:r.rows})}catch(error){console.error("Mood query failed",error);return NextResponse.json({error:"Database connection failed. Check DATABASE_URL and Supabase project status."},{status:503})}}
