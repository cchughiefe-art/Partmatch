import { readFile } from "node:fs/promises";
import { neon } from "@neondatabase/serverless";

const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;
if (!connectionString) {
  console.error("Missing DATABASE_URL (or POSTGRES_URL).");
  process.exit(1);
}

const sql = neon(connectionString);
const seed = await readFile(new URL("../database/seed.sql", import.meta.url), "utf8");

function splitSqlStatements(source) {
  const statements = [];
  let current = "";
  let inSingleQuote = false;
  let inDoubleQuote = false;
  let inLineComment = false;
  let inBlockComment = false;

  for (let i = 0; i < source.length; i += 1) {
    const char = source[i];
    const next = source[i + 1];

    if (inLineComment) {
      if (char === "\n") {
        inLineComment = false;
        current += char;
      }
      continue;
    }

    if (inBlockComment) {
      if (char === "*" && next === "/") {
        inBlockComment = false;
        i += 1;
      }
      continue;
    }

    if (!inSingleQuote && !inDoubleQuote && char === "-" && next === "-") {
      inLineComment = true;
      i += 1;
      continue;
    }
    if (!inSingleQuote && !inDoubleQuote && char === "/" && next === "*") {
      inBlockComment = true;
      i += 1;
      continue;
    }

    if (inSingleQuote) {
      current += char;
      if (char === "'" && next === "'") {
        current += next;
        i += 1;
      } else if (char === "'") {
        inSingleQuote = false;
      }
      continue;
    }

    if (inDoubleQuote) {
      current += char;
      if (char === '"') inDoubleQuote = false;
      continue;
    }

    if (char === "'") {
      inSingleQuote = true;
      current += char;
      continue;
    }
    if (char === '"') {
      inDoubleQuote = true;
      current += char;
      continue;
    }
    if (char === ";") {
      if (current.trim()) statements.push(current.trim());
      current = "";
      continue;
    }
    current += char;
  }

  if (inSingleQuote || inDoubleQuote || inBlockComment) {
    throw new Error("Unterminated quote or block comment in database/seed.sql");
  }
  if (current.trim()) statements.push(current.trim());
  return statements;
}

for (const statement of splitSqlStatements(seed)) {
  await sql.query(statement);
}

const counts = await sql.query(
  "SELECT (SELECT COUNT(*) FROM brands) AS brands, (SELECT COUNT(*) FROM devices) AS devices, (SELECT COUNT(*) FROM screen_parts) AS screen_parts, (SELECT COUNT(*) FROM compatibilities WHERE status='supplier_listed') AS supplier_listed"
);
console.log("PartMatch seed completed:", JSON.stringify(counts[0]));
