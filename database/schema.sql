CREATE TABLE IF NOT EXISTS brands (
 id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL UNIQUE, slug TEXT NOT NULL UNIQUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS devices (
 id BIGSERIAL PRIMARY KEY, brand_id BIGINT NOT NULL REFERENCES brands(id) ON DELETE RESTRICT,
 marketing_name TEXT NOT NULL, model_code TEXT, region TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS devices_marketing_name_idx ON devices USING GIN (to_tsvector('simple', marketing_name));
CREATE INDEX IF NOT EXISTS devices_model_code_idx ON devices (LOWER(model_code));
CREATE TABLE IF NOT EXISTS screen_parts (
 id BIGSERIAL PRIMARY KEY, part_number TEXT NOT NULL, screen_type TEXT, assembly_type TEXT, manufacturer TEXT, notes TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS screen_parts_part_number_idx ON screen_parts (LOWER(part_number));
CREATE TABLE IF NOT EXISTS compatibilities (
 id BIGSERIAL PRIMARY KEY, device_id BIGINT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
 screen_part_id BIGINT NOT NULL REFERENCES screen_parts(id) ON DELETE CASCADE,
 status TEXT NOT NULL DEFAULT 'unverified' CHECK (status IN ('verified','supplier_listed','unverified','disputed','rejected')),
 evidence_source TEXT, evidence_url TEXT, notes TEXT, checked_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 UNIQUE(device_id, screen_part_id)
);
CREATE INDEX IF NOT EXISTS compatibilities_status_idx ON compatibilities(status);
CREATE INDEX IF NOT EXISTS compatibilities_device_idx ON compatibilities(device_id);
CREATE INDEX IF NOT EXISTS compatibilities_part_idx ON compatibilities(screen_part_id);
-- Intentionally no fabricated compatibility rows are seeded.
