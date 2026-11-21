import { readFile } from "node:fs/promises";
import { neon } from "@neondatabase/serverless";
const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;
if (!connectionString) { console.error("Missing DATABASE_URL (or POSTGRES_URL)."); process.exit(1); }
const sql = neon(connectionString);
const schema = await readFile(new URL("../database/schema.sql", import.meta.url), "utf8");
await sql.query(schema);
console.log("PartMatch database schema is ready.");
