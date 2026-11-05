import {Pool} from "pg";

if(!process.env.DATABASE_URL) {
  console.warn("DATABASE_URL is not set; configure .env.local before using database API routes.");
}

const pool=new Pool({
  connectionString:process.env.DATABASE_URL,
  ssl:process.env.DATABASE_URL ? {rejectUnauthorized:false} : undefined,
  max:10
});
export default pool;
