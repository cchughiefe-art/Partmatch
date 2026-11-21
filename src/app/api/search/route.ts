import { NextRequest, NextResponse } from "next/server";
import { databaseConfigured } from "@/lib/db";
import { searchCompatibility } from "@/lib/search";
export const runtime = "nodejs";
export async function GET(request:NextRequest) {
 const q = request.nextUrl.searchParams.get("q")?.trim() ?? "";
 if (q.length < 2) return NextResponse.json({results:[],message:"Enter at least 2 characters."});
 if (q.length > 100) return NextResponse.json({error:"Search is limited to 100 characters."},{status:400});
 if (!databaseConfigured()) return NextResponse.json({error:"Database is not configured. Add DATABASE_URL in Vercel environment variables."},{status:503});
 try {
  const results = await searchCompatibility(q);
  return NextResponse.json({results,count:results.length});
 } catch (error) {
  console.error("PartMatch search failed:",error);
  return NextResponse.json({error:"Search failed. Check the database connection and schema."},{status:500});
 }
}
