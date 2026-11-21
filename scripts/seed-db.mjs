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

// Import source-attributed supplier catalogue groups in bulk to keep Vercel prebuilds fast.
// Every relation remains supplier_listed; this importer never promotes supplier claims to bench-verified.
const catalog = JSON.parse(await readFile(new URL("../database/research-catalog.json", import.meta.url), "utf8"));
const source = catalog.source;
const groupRows = catalog.groups.map((g) => ({ ref: g.ref, part: g.part }));
const flatModels = catalog.groups.flatMap((g) => g.models.map(([brand, marketing_name, model_code]) => ({
  ref: g.ref, brand, marketing_name, model_code: model_code || null
})));
const uniqueBrands = [...new Set(flatModels.map((m) => m.brand))].map((name) => ({
  name, slug: name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
}));
await sql.query(
  `INSERT INTO brands (name, slug)
   SELECT x.name, x.slug FROM jsonb_to_recordset($1::jsonb) AS x(name text, slug text)
   ON CONFLICT (name) DO NOTHING`,
  [JSON.stringify(uniqueBrands)]
);

await sql.query(
  `WITH incoming AS (
     SELECT * FROM jsonb_to_recordset($1::jsonb) AS x(ref text, part text)
   )
   INSERT INTO screen_parts
     (part_number, screen_type, assembly_type, manufacturer, notes, source_title, source_product_id, search_aliases)
   SELECT i.part, 'LCD', 'Replacement LCD assembly; exact frame/touch variant must be checked',
     'Aftermarket', $2, $3, i.ref, ''
   FROM incoming i
   WHERE NOT EXISTS (SELECT 1 FROM screen_parts sp WHERE sp.source_product_id = i.ref)`,
  [JSON.stringify(groupRows), source.notes, source.title]
);

await sql.query(
  `WITH incoming AS (
     SELECT * FROM jsonb_to_recordset($1::jsonb)
       AS x(brand text, marketing_name text, model_code text)
   ),
   ranked AS (
     SELECT i.*, ROW_NUMBER() OVER (
       PARTITION BY LOWER(brand), LOWER(COALESCE(model_code, ''))
       ORDER BY marketing_name
     ) AS code_rank
     FROM incoming i
   ),
   prepared AS (
     SELECT b.id AS brand_id, r.marketing_name,
       CASE WHEN r.model_code IS NOT NULL AND (
         r.code_rank > 1 OR EXISTS (
           SELECT 1 FROM devices d WHERE d.brand_id=b.id
             AND LOWER(d.model_code)=LOWER(r.model_code)
             AND LOWER(d.marketing_name)<>LOWER(r.marketing_name)
         )
       ) THEN NULL ELSE r.model_code END AS stored_code,
       CASE WHEN r.model_code IS NOT NULL AND (
         r.code_rank > 1 OR EXISTS (
           SELECT 1 FROM devices d WHERE d.brand_id=b.id
             AND LOWER(d.model_code)=LOWER(r.model_code)
             AND LOWER(d.marketing_name)<>LOWER(r.marketing_name)
         )
       ) THEN r.model_code ELSE NULL END AS model_aliases
     FROM ranked r JOIN brands b ON LOWER(b.name)=LOWER(r.brand)
   )
   INSERT INTO devices (brand_id, marketing_name, model_code, model_aliases)
   SELECT p.brand_id, p.marketing_name, p.stored_code, p.model_aliases
   FROM prepared p
   WHERE NOT EXISTS (
     SELECT 1 FROM devices d WHERE d.brand_id=p.brand_id
       AND LOWER(d.marketing_name)=LOWER(p.marketing_name)
       AND (COALESCE(LOWER(d.model_code),'')=COALESCE(LOWER(p.stored_code),'')
         OR (p.model_aliases IS NOT NULL AND LOWER(COALESCE(d.model_aliases,'')) LIKE '%'||LOWER(p.model_aliases)||'%'))
   )
   ON CONFLICT DO NOTHING`,
  [JSON.stringify(flatModels.map(({brand,marketing_name,model_code})=>({brand,marketing_name,model_code})))]
);

await sql.query(
  `WITH incoming AS (
     SELECT * FROM jsonb_to_recordset($1::jsonb)
       AS x(ref text, brand text, marketing_name text, model_code text)
   ),
   matches AS (
     SELECT DISTINCT d.id AS device_id, sp.id AS screen_part_id
     FROM incoming i
     JOIN brands b ON LOWER(b.name)=LOWER(i.brand)
     JOIN devices d ON d.brand_id=b.id AND LOWER(d.marketing_name)=LOWER(i.marketing_name)
       AND (i.model_code IS NULL
         OR LOWER(COALESCE(d.model_code,''))=LOWER(i.model_code)
         OR LOWER(COALESCE(d.model_aliases,'')) LIKE '%'||LOWER(i.model_code)||'%')
     JOIN screen_parts sp ON sp.source_product_id=i.ref
   )
   INSERT INTO compatibilities
     (device_id, screen_part_id, status, evidence_source, evidence_url, notes)
   SELECT m.device_id, m.screen_part_id, 'supplier_listed', $2, $3,
     'Explicitly grouped in supplier catalogue. Not independently bench-tested; verify exact model code, flex, connector, resolution, frame and touch revision before fitting.'
   FROM matches m
   ON CONFLICT (device_id, screen_part_id) DO UPDATE SET
     status='supplier_listed', evidence_source=EXCLUDED.evidence_source,
     evidence_url=EXCLUDED.evidence_url, notes=EXCLUDED.notes`,
  [JSON.stringify(flatModels), source.publisher, source.url]
);
const importedFitments = flatModels.length;

const counts = await sql.query(
  "SELECT (SELECT COUNT(*) FROM brands) AS brands, (SELECT COUNT(*) FROM devices) AS devices, (SELECT COUNT(*) FROM screen_parts) AS screen_parts, (SELECT COUNT(*) FROM compatibilities WHERE status='supplier_listed') AS supplier_listed"
);
console.log("PartMatch seed completed:", JSON.stringify({ ...counts[0], importedFitments }));
