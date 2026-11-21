CREATE TABLE IF NOT EXISTS brands (
 id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL UNIQUE, slug TEXT NOT NULL UNIQUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE brands ADD COLUMN IF NOT EXISTS slug TEXT;
UPDATE brands SET slug = trim(both '-' from lower(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'))) WHERE slug IS NULL OR slug = '';
ALTER TABLE brands ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS brands_slug_unique_idx ON brands(slug);

CREATE TABLE IF NOT EXISTS devices (
 id BIGSERIAL PRIMARY KEY, brand_id BIGINT NOT NULL REFERENCES brands(id) ON DELETE RESTRICT,
 marketing_name TEXT NOT NULL, model_code TEXT, region TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS model_aliases TEXT;
CREATE INDEX IF NOT EXISTS devices_marketing_name_idx ON devices USING GIN (to_tsvector('simple', marketing_name));
CREATE INDEX IF NOT EXISTS devices_model_code_idx ON devices (LOWER(model_code));
CREATE TABLE IF NOT EXISTS screen_parts (
 id BIGSERIAL PRIMARY KEY, part_number TEXT NOT NULL, screen_type TEXT, assembly_type TEXT, manufacturer TEXT, notes TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE screen_parts ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE screen_parts ADD COLUMN IF NOT EXISTS quality_class TEXT;
ALTER TABLE screen_parts ADD COLUMN IF NOT EXISTS touchscreen TEXT;
ALTER TABLE screen_parts ADD COLUMN IF NOT EXISTS matrix_type TEXT;
ALTER TABLE screen_parts ADD COLUMN IF NOT EXISTS source_title TEXT;
ALTER TABLE screen_parts ADD COLUMN IF NOT EXISTS source_product_id TEXT;
CREATE INDEX IF NOT EXISTS screen_parts_part_number_idx ON screen_parts (LOWER(part_number));
CREATE TABLE IF NOT EXISTS compatibilities (
 id BIGSERIAL PRIMARY KEY, device_id BIGINT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
 screen_part_id BIGINT NOT NULL REFERENCES screen_parts(id) ON DELETE CASCADE,
 status TEXT NOT NULL DEFAULT 'unverified' CHECK (status IN ('verified','supplier_listed','unverified','disputed','rejected')),
 evidence_source TEXT, evidence_url TEXT, notes TEXT, checked_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 UNIQUE(device_id, screen_part_id)
);
ALTER TABLE compatibilities DROP CONSTRAINT IF EXISTS compatibilities_status_check;
ALTER TABLE compatibilities ADD CONSTRAINT compatibilities_status_check
 CHECK (status IN ('verified','supplier_listed','unverified','disputed','rejected'));
CREATE INDEX IF NOT EXISTS compatibilities_status_idx ON compatibilities(status);
CREATE INDEX IF NOT EXISTS compatibilities_device_idx ON compatibilities(device_id);
CREATE INDEX IF NOT EXISTS compatibilities_part_idx ON compatibilities(screen_part_id);
-- No compatibility is considered bench-verified unless a technician confirms the fit.

-- Legacy deployments created model_code as NOT NULL. Some supplier listings
-- do not publish a handset code, so allow NULL while keeping the unique key.
ALTER TABLE devices ALTER COLUMN model_code DROP NOT NULL;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS model_aliases TEXT;
ALTER TABLE screen_parts ADD COLUMN IF NOT EXISTS search_aliases TEXT;
CREATE INDEX IF NOT EXISTS screen_parts_search_aliases_idx ON screen_parts USING GIN (to_tsvector('simple', COALESCE(search_aliases,'')));

-- Older installations required a URL even when a listing came from a user-provided title.
-- Preserve provenance without inventing a URL.
ALTER TABLE compatibilities ALTER COLUMN evidence_url DROP NOT NULL;
