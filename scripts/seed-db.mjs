import { readFile } from "node:fs/promises";
import { neon } from "@neondatabase/serverless";

const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;
if (!connectionString) {
  console.error("Missing DATABASE_URL (or POSTGRES_URL).");
  process.exit(1);
}

const sql = neon(connectionString);
const seed = await readFile(new URL("../database/seed.sql", import.meta.url), "utf8");
const statements = seed
  .split("\n")
  .filter((line) => !line.trimStart().startsWith("--"))
  .join("\n")
  .split(";")
  .map((statement) => statement.trim())
  .filter((statement) => statement.length > 0);

for (const statement of statements) {
  await sql.query(statement);
}

const counts = await sql.query(
  "SELECT (SELECT COUNT(*) FROM brands) AS brands, (SELECT COUNT(*) FROM devices) AS devices, (SELECT COUNT(*) FROM screen_parts) AS screen_parts, (SELECT COUNT(*) FROM compatibilities WHERE status='supplier_listed') AS supplier_listed"
);
console.log("PartMatch seed completed:", JSON.stringify(counts[0]));
