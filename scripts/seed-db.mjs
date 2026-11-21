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
    const char = source[i], next = source[i + 1];
    if (inLineComment) { if (char === "\n") { inLineComment = false; current += char; } continue; }
    if (inBlockComment) { if (char === "*" && next === "/") { inBlockComment = false; i += 1; } continue; }
    if (!inSingleQuote && !inDoubleQuote && char === "-" && next === "-") { inLineComment = true; i += 1; continue; }
    if (!inSingleQuote && !inDoubleQuote && char === "/" && next === "*") { inBlockComment = true; i += 1; continue; }
    if (inSingleQuote) { current += char; if (char === "'" && next === "'") { current += next; i += 1; } else if (char === "'") inSingleQuote = false; continue; }
    if (inDoubleQuote) { current += char; if (char === '"') inDoubleQuote = false; continue; }
    if (char === "'") { inSingleQuote = true; current += char; continue; }
    if (char === '"') { inDoubleQuote = true; current += char; continue; }
    if (char === ";") { if (current.trim()) statements.push(current.trim()); current = ""; continue; }
    current += char;
  }
  if (inSingleQuote || inDoubleQuote || inBlockComment) throw new Error("Unterminated quote or block comment in database/seed.sql");
  if (current.trim()) statements.push(current.trim());
  return statements;
}

for (const statement of splitSqlStatements(seed)) await sql.query(statement);

// Import source-attributed supplier catalogue groups. Every imported relation remains
// supplier_listed; this script never promotes a supplier claim to bench-verified.
const catalog = JSON.parse(await readFile(new URL("../database/research-catalog.json", import.meta.url), "utf8"));
const source = catalog.source;
let importedFitments = 0;
for (const group of catalog.groups) {
  const brandNames = [...new Set(group.models.map((model) => model[0]))];
  for (const brandName of brandNames) {
    const slug = brandName.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    await sql.query(
      "INSERT INTO brands (name, slug) VALUES ($1, $2) ON CONFLICT (name) DO NOTHING",
      [brandName, slug]
    );
  }

  const partRows = await sql.query(
    "SELECT id FROM screen_parts WHERE source_product_id = $1 LIMIT 1",
    [group.ref]
  );
  let partId = partRows[0]?.id;
  if (!partId) {
    const inserted = await sql.query(
      `INSERT INTO screen_parts
       (part_number, screen_type, assembly_type, manufacturer, notes, source_title, source_product_id, search_aliases)
       VALUES ($1, 'LCD', 'Replacement LCD assembly; exact frame/touch variant must be checked', 'Aftermarket',
       $2, $3, $4, $5) RETURNING id`,
      [group.part, source.notes, source.title, group.ref, group.models.map((m) => m[2]).filter(Boolean).join(" ")]
    );
    partId = inserted[0].id;
  }

  for (const [brandName, marketingName, rawCode] of group.models) {
    const modelCode = rawCode || null;
    const brandRows = await sql.query("SELECT id FROM brands WHERE name = $1 LIMIT 1", [brandName]);
    const brandId = brandRows[0].id;
    const existing = await sql.query(
      `SELECT id FROM devices WHERE brand_id = $1 AND LOWER(marketing_name) = LOWER($2)
       AND (COALESCE(LOWER(model_code), '') = COALESCE(LOWER($3), '')
         OR ($3 IS NOT NULL AND COALESCE(LOWER(model_aliases), '') LIKE '%' || LOWER($3) || '%')) LIMIT 1`,
      [brandId, marketingName, modelCode]
    );
    let deviceId = existing[0]?.id;
    if (!deviceId) {
      // Some supplier sheets reuse shorthand model codes across multiple marketing names.
      // Preserve the searchable code as an alias on the secondary name instead of violating
      // the database's (brand, model_code, region) uniqueness constraint.
      let storedCode = modelCode;
      let modelAliases = null;
      if (modelCode) {
        const codeOwner = await sql.query(
          "SELECT id FROM devices WHERE brand_id = $1 AND LOWER(model_code) = LOWER($2) LIMIT 1",
          [brandId, modelCode]
        );
        if (codeOwner.length) {
          storedCode = null;
          modelAliases = modelCode;
        }
      }
      const inserted = await sql.query(
        "INSERT INTO devices (brand_id, marketing_name, model_code, model_aliases) VALUES ($1, $2, $3, $4) RETURNING id",
        [brandId, marketingName, storedCode, modelAliases]
      );
      deviceId = inserted[0].id;
    }
    await sql.query(
      `INSERT INTO compatibilities (device_id, screen_part_id, status, evidence_source, evidence_url, notes)
       VALUES ($1, $2, 'supplier_listed', $3, $4, $5)
       ON CONFLICT (device_id, screen_part_id) DO UPDATE SET
       status = 'supplier_listed', evidence_source = EXCLUDED.evidence_source,
       evidence_url = EXCLUDED.evidence_url, notes = EXCLUDED.notes`,
      [deviceId, partId, source.publisher, source.url,
       "Explicitly grouped in supplier catalogue. Not independently bench-tested; verify exact model code, flex, connector, resolution, frame and touch revision before fitting."]
    );
    importedFitments += 1;
  }
}

const counts = await sql.query(
  "SELECT (SELECT COUNT(*) FROM brands) AS brands, (SELECT COUNT(*) FROM devices) AS devices, (SELECT COUNT(*) FROM screen_parts) AS screen_parts, (SELECT COUNT(*) FROM compatibilities WHERE status='supplier_listed') AS supplier_listed"
);
console.log("PartMatch seed completed:", JSON.stringify({ ...counts[0], importedFitments }));
