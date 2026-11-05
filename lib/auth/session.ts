import {SignJWT,jwtVerify} from "jose";
const secret=()=>{
  if(!process.env.AUTH_SECRET) throw new Error("AUTH_SECRET is not configured.");
  return new TextEncoder().encode(process.env.AUTH_SECRET);
};
export type Session={userId:string;username:string;role:"USER"|"ADMIN"};
export async function createSession(s:Session){return new SignJWT(s).setProtectedHeader({alg:"HS256"}).setIssuedAt().setExpirationTime("7d").sign(secret())}
export async function decodeSession(token?:string){if(!token)return null;try{return (await jwtVerify(token,secret())).payload as unknown as Session}catch{return null}}
