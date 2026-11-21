# PartMatch

PartMatch is a phone display/LCD compatibility reference. Search by device marketing name, model code (such as BG6 or BF7), brand, or screen part number. Results are grouped by shared screen part.

## Stack
- Next.js 15, React 19, TypeScript
- Neon PostgreSQL via @neondatabase/serverless
- Deployable to Vercel

## Local setup
1. Use Node.js 20 or later.
2. Run npm install.
3. Copy .env.example to .env.local and set DATABASE_URL to your Neon connection string.
4. Run npm run db:setup to create tables.
5. Run npm run dev and open http://localhost:3000.

## Vercel deployment
1. Import this repository into Vercel as a Next.js project.
2. Add DATABASE_URL to Vercel environment variables.
3. Run npm run db:setup once against the intended Neon database, then deploy.

Never commit database credentials.

## Database
- brands: phone manufacturers
- devices: marketing names, model codes, region variants
- screen_parts: LCD/OLED part and assembly identifiers
- compatibilities: device-to-screen relationships plus status and evidence

Compatibility statuses:
- verified: documented physical fit/function test or reliable manufacturer documentation
- supplier_listed: explicitly claimed by a supplier/catalogue, not independently confirmed
- unverified: possible match without sufficient evidence
- disputed: credible sources conflict
- rejected: known not to fit; excluded from normal search

Record evidence_source, evidence_url where available, and concise notes. Visual similarity alone is not proof of compatibility.

## Current catalogue status
The live database currently contains 14 brands, 375 device records, 83 screen-part records, and 388 supplier-listed compatibility relations. The latest public supplier-catalogue import added 79 groups and 374 model entries across Samsung, Motorola, Xiaomi, POCO, OPPO, Realme, OnePlus, Vivo, Tecno, Infinix, itel, Honor, and ZTE.

Primary imported source: [Crown QZ / QT Mobile LCD Compatibility Catalogue (2025-04-09)](https://www.scribd.com/document/919633992/Crown-Lcd-Qt-Lcd-2025-04-09). The structured import is in `database/research-catalog.json`. Additional public references are used as research leads and cross-checks.

**Verification status:** the imported supplier records are labelled `supplier_listed`; they are not independent bench tests. The database currently has no independently bench-verified compatibility claims. Exact regional model code, panel revision, flex, connector, frame and touch variant must be checked before installation. Conflicting supplier claims should remain flagged rather than merged into a guaranteed fitment.

The catalogue is an expanding reference, not an exhaustive list of every phone or every LCD currently sold.

## API
GET /api/search?q=BG6 returns up to 100 matching records. Search covers device name, model code, brand, screen part number, and screen manufacturer.
