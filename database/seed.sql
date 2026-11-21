-- PartMatch starter dataset. Every row is supplier-listed, NOT bench-verified.
-- Sources are the supplier product pages that explicitly enumerate compatible devices.
-- Re-running this file is safe: brands, devices, parts and compatibility links are deduplicated.

INSERT INTO brands (name, slug) VALUES
 ('Tecno','tecno'), ('Infinix','infinix')
ON CONFLICT (name) DO NOTHING;

-- Refresh model identifiers on records created by earlier seed versions.
UPDATE devices d SET model_code = v.model_code
FROM brands b, (VALUES
 ('Tecno','Spark Go (2023)','BF7 / BF7N'),
 ('Infinix','Smart 8','X6525 / X6525D'),
 ('Infinix','Smart 8 Plus','X6526'),
 ('Infinix','Hot 40i','X6528 / X6528B')
) AS v(brand_name, phone_name, model_code)
WHERE d.brand_id=b.id AND b.name=v.brand_name AND d.marketing_name=v.phone_name;

-- Supplier listing: GsmServer product #916763, FPC6605-5 / FPC6605-05 family.
-- The listing explicitly names these seven device families.
INSERT INTO screen_parts (part_number, screen_type, assembly_type, manufacturer, notes)
SELECT 'FPC6605-5', 'IPS LCD', 'LCD + touch, without frame', 'Aftermarket',
       'Supplier listing also labels the family BF6, BF7, KI5Q and KI5K. Confirm flex and connector before fitting.'
WHERE NOT EXISTS (SELECT 1 FROM screen_parts WHERE LOWER(part_number)=LOWER('FPC6605-5'));

WITH input(brand, marketing_name, model_code) AS (VALUES
 ('Tecno','Spark Go (2023)','BF7 / BF7N'),
 ('Tecno','Pop 7','BF6'),
 ('Infinix','Smart 7','X6515')
)
INSERT INTO devices (brand_id, marketing_name, model_code)
SELECT b.id, i.marketing_name, i.model_code
FROM input i JOIN brands b ON b.name=i.brand
WHERE NOT EXISTS (
 SELECT 1 FROM devices d
 WHERE d.brand_id=b.id AND LOWER(d.marketing_name)=LOWER(i.marketing_name)
 AND COALESCE(LOWER(d.model_code),'')=COALESCE(LOWER(i.model_code),'')
);

INSERT INTO compatibilities (device_id, screen_part_id, status, evidence_source, evidence_url, notes)
SELECT d.id, sp.id, 'unverified', 'GsmServer product listing',
 'https://gsmserver.com/en/lcd-compatible-with-tecno-pop-7-spark-go-2023-infinix-smart-7-black-without-frame-high-copy-bf7-bf6/',
 'Supplier explicitly lists this device as compatible with FPC6605-5. Aftermarket listing only, physical fit and touch must be tested.'
FROM devices d
JOIN brands b ON b.id=d.brand_id
JOIN screen_parts sp ON LOWER(sp.part_number)=LOWER('FPC6605-5')
WHERE (b.name='Tecno' AND d.marketing_name IN ('Spark Go (2023)','Pop 7'))
   OR (b.name='Infinix' AND d.marketing_name='Smart 7')
ON CONFLICT (device_id, screen_part_id) DO UPDATE SET
 status='unverified', evidence_source=EXCLUDED.evidence_source,
 evidence_url=EXCLUDED.evidence_url, notes=EXCLUDED.notes;

-- Supplier listing: Dama Mobile Spares SKU BG6CL. Separate replacement assembly.
INSERT INTO screen_parts (part_number, screen_type, assembly_type, manufacturer, notes)
SELECT 'BG6CL', 'LCD', 'LCD + touch, without frame', 'Aftermarket',
       'Supplier SKU BG6CL. Do not assume it is interchangeable with FPC6605-5, this is a separate listed assembly.'
WHERE NOT EXISTS (SELECT 1 FROM screen_parts WHERE LOWER(part_number)=LOWER('BG6CL'));

WITH input(brand, marketing_name, model_code) AS (VALUES
 ('Tecno','Spark Go 2024','BG6')
)
INSERT INTO devices (brand_id, marketing_name, model_code)
SELECT b.id, i.marketing_name, i.model_code
FROM input i JOIN brands b ON b.name=i.brand
WHERE NOT EXISTS (
 SELECT 1 FROM devices d
 WHERE d.brand_id=b.id AND LOWER(d.marketing_name)=LOWER(i.marketing_name)
 AND COALESCE(LOWER(d.model_code),'')=COALESCE(LOWER(i.model_code),'')
);

INSERT INTO compatibilities (device_id, screen_part_id, status, evidence_source, evidence_url, notes)
SELECT d.id, sp.id, 'unverified', 'Dama Mobile Spares product listing (SKU BG6CL)',
 'https://damamobilespares.co.ke/product/tecno-bg6-comp-lcd/',
 'Supplier listing explicitly groups this model with SKU BG6CL. Aftermarket supplier claim; verify connector, flex layout and physical fit.'
FROM devices d
JOIN brands b ON b.id=d.brand_id
JOIN screen_parts sp ON LOWER(sp.part_number)=LOWER('BG6CL')
WHERE b.name='Tecno' AND d.marketing_name='Spark Go 2024'
ON CONFLICT (device_id, screen_part_id) DO UPDATE SET
 status='unverified', evidence_source=EXCLUDED.evidence_source,
 evidence_url=EXCLUDED.evidence_url, notes=EXCLUDED.notes;


-- Combo Universal source import: Itel/Tecno/Infinix 2026, version 5.0 group.
-- The source groups these handset names/model codes under one Notch LCD/Display/Combo entry.
-- This is a supplier/reference claim, not an independently bench-tested fitment.
INSERT INTO brands (name, slug) VALUES
 ('itel','itel'), ('ZTE','zte')
ON CONFLICT (name) DO NOTHING;

INSERT INTO screen_parts (part_number, screen_type, assembly_type, manufacturer, notes)
SELECT 'CU-TI-2026-001', 'LCD', 'Notch LCD / Display / Combo', 'Combo Universal reference group',
       'Reference group label only, not a retail flex/part number. Source entry: Itel/Tecno/Infinix Universal Combo List 2026, new version V5.0.'
WHERE NOT EXISTS (SELECT 1 FROM screen_parts WHERE LOWER(part_number)=LOWER('CU-TI-2026-001'));

WITH input(brand, marketing_name, model_code) AS (VALUES
 ('Infinix','Smart 7','X6515'),
 ('Infinix','Smart 7 HD','X6516'),
 ('Infinix','Smart 7 Plus','X6517'),
 ('Infinix','Hot 30i','X669 / X669B / X669C / X669D'),
 ('Tecno','Pop 7','BF6'),
 ('Tecno','Spark Go 2023','BF7N / BF7S'),
 ('Tecno','Pop 7 Pro','BF7 / BF7H'),
 ('Tecno','Spark K10','KI5N'),
 ('Tecno','Spark 10','KI5Q'),
 ('Tecno','Spark K10 5G','KI8'),
 ('Tecno','Spark 10C','KI5K / KI5M'),
 ('itel','P40','P662L'),
 ('itel','P55 5G','P661N'),
 ('itel','Colour Pro 5G','P661N'),
 ('itel','A05s','A663L / A663LC'),
 ('itel','A05i','A663L'),
 ('itel','A50','A667L / A667LP'),
 ('itel','A60','A662L'),
 ('itel','A60s','A662LM'),
 ('itel','A70','A665L'),
 ('itel','S23','S665L / S665LN'),
 ('ZTE','A34',NULL),
 ('ZTE','A54',NULL)
)
INSERT INTO devices (brand_id, marketing_name, model_code)
SELECT b.id, i.marketing_name, i.model_code
FROM input i JOIN brands b ON LOWER(b.name)=LOWER(i.brand)
WHERE NOT EXISTS (
 SELECT 1 FROM devices d
 WHERE d.brand_id=b.id AND LOWER(d.marketing_name)=LOWER(i.marketing_name)
);

INSERT INTO compatibilities (device_id, screen_part_id, status, evidence_source, evidence_url, notes)
SELECT d.id, sp.id, 'supplier_listed', 'Combo Universal — Itel, Tecno, Infinix Universal Combo List 2026 (V5.0)',
 'https://combouniversal.com/itel-tecno-infinix-universal-combo-list/',
 'Listed together in the source''s V5.0 Notch LCD/Display group. Treat as a supplier reference; verify panel dimensions, flex connector, pinout, frame and touch before fitting.'
FROM devices d
JOIN brands b ON b.id=d.brand_id
JOIN screen_parts sp ON sp.part_number='CU-TI-2026-001'
WHERE (LOWER(b.name)='infinix' AND d.marketing_name IN ('Smart 7','Smart 7 HD','Smart 7 Plus','Hot 30i'))
   OR (LOWER(b.name)='tecno' AND d.marketing_name IN ('Pop 7','Spark Go 2023','Pop 7 Pro','Spark K10','Spark 10','Spark K10 5G','Spark 10C'))
   OR (LOWER(b.name)='itel' AND d.marketing_name IN ('P40','P55 5G','Colour Pro 5G','A05s','A05i','A50','A60','A60s','A70','S23'))
   OR (LOWER(b.name)='zte' AND d.marketing_name IN ('A34','A54'))
ON CONFLICT (device_id, screen_part_id) DO UPDATE SET
 status='supplier_listed', evidence_source=EXCLUDED.evidence_source,
 evidence_url=EXCLUDED.evidence_url, notes=EXCLUDED.notes;
