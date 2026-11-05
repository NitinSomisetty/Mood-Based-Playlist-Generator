import {NextRequest,NextResponse} from "next/server";import {decodeSession} from "@/lib/auth/session";
export async function middleware(req:NextRequest){if(req.nextUrl.pathname.startsWith("/admin")){const s=await decodeSession(req.cookies.get("session")?.value);if(!s||s.role!=="ADMIN")return NextResponse.redirect(new URL("/login",req.url))}return NextResponse.next()}
export const config={matcher:["/admin/:path*"]};
