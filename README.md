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

## Data status
The schema intentionally starts empty. No compatibility claims are fabricated. The search application is ready, but records must be imported from sourced catalogues, manufacturer documentation, or physical test records before it can return results. It is not yet a complete all-brand verified catalogue.

## API
GET /api/search?q=BG6 returns up to 100 matching records. Search covers device name, model code, brand, screen part number, and screen manufacturer.
