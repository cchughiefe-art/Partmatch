import { readFile } from "node:fs/promises";
import { neon } from "@neondatabase/serverless";

const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;
if (!connectionString) {
  console.error("Missing DATABASE_URL (or POSTGRES_URL).");
  process.exit(1);
}

const sql = neon(connectionString);
const schema = await readFile(new URL("../database/schema.sql", import.meta.url), "utf8");
const statements = schema
  .split(";")
  .map((statement) => statement.trim())
  .filter((statement) => statement.length > 0);

for (const statement of statements) {
  await sql.query(statement);
}

// Existing databases may retain an older CHECK constraint because CREATE TABLE IF NOT EXISTS
// does not update constraints. Replace it explicitly so the current status vocabulary is applied.
await sql.query("ALTER TABLE compatibilities DROP CONSTRAINT IF EXISTS compatibilities_status_check");
await sql.query(`ALTER TABLE compatibilities ADD CONSTRAINT compatibilities_status_check
  CHECK (status IN ('verified','supplier_listed','unverified','disputed','rejected'))`);

console.log("PartMatch database schema and compatibility status constraint are ready.");
