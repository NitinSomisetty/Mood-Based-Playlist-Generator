import {NextResponse} from "next/server";
import pool from "@/lib/db/pool";

export const dynamic="force-dynamic";

export async function GET(){
  try{
    const result=await pool.query("SELECT current_database() AS database, current_user AS user_name, now() AS server_time");
    return NextResponse.json({ok:true,database:result.rows[0]});
  }catch(error){
    console.error("Database health check failed",error);
    return NextResponse.json({
      ok:false,
      error:"Supabase connection failed. Check DATABASE_URL, the database password, and the Session Pooler URI."
    },{status:503});
  }
}
