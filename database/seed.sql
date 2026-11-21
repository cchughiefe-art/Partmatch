-- PartMatch starter dataset. Every row is supplier-listed, NOT bench-verified.
-- Sources are the supplier product pages that explicitly enumerate compatible devices.
-- Re-running this file is safe: brands, devices, parts and compatibility links are deduplicated.

INSERT INTO brands (name, slug) VALUES
 ('Tecno','tecno'), ('Infinix','infinix')
ON CONFLICT (name) DO NOTHING;

-- Supplier listing: GsmServer product #916763, FPC6605-5 / FPC6605-05 family.
-- The listing explicitly names these seven device families.
INSERT INTO screen_parts (part_number, screen_type, assembly_type, manufacturer, notes)
SELECT 'FPC6605-5', 'IPS LCD', 'LCD + touch, without frame', 'Aftermarket',
       'Supplier listing also labels the family BF6, BF7, KI5Q and KI5K. Confirm flex and connector before fitting.'
WHERE NOT EXISTS (SELECT 1 FROM screen_parts WHERE LOWER(part_number)=LOWER('FPC6605-5'));

WITH input(brand, marketing_name, model_code) AS (VALUES
 ('Tecno','Spark Go (2023)','BF7'),
 ('Tecno','Spark 10',NULL),
 ('Tecno','Spark 10C',NULL),
 ('Tecno','Pop 7','BF6'),
 ('Tecno','Pop 7 Pro',NULL),
 ('Infinix','Smart 7','X6515'),
 ('Infinix','Smart 7 HD','X6516')
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
SELECT d.id, sp.id, 'supplier_listed', 'GsmServer product listing',
 'https://gsmserver.com/en/lcd-compatible-with-tecno-pop-7-spark-go-2023-infinix-smart-7-black-without-frame-high-copy-bf7-bf6/',
 'Supplier explicitly lists this device as compatible with FPC6605-5. Aftermarket listing only; physical fit and touch must be tested.'
FROM devices d
JOIN brands b ON b.id=d.brand_id
JOIN screen_parts sp ON LOWER(sp.part_number)=LOWER('FPC6605-5')
WHERE (b.name='Tecno' AND d.marketing_name IN ('Spark Go (2023)','Spark 10','Spark 10C','Pop 7','Pop 7 Pro'))
   OR (b.name='Infinix' AND d.marketing_name IN ('Smart 7','Smart 7 HD'))
ON CONFLICT (device_id, screen_part_id) DO UPDATE SET
 status='supplier_listed', evidence_source=EXCLUDED.evidence_source,
 evidence_url=EXCLUDED.evidence_url, notes=EXCLUDED.notes;

-- Supplier listing: Dama Mobile Spares SKU BG6CL. Separate replacement assembly.
INSERT INTO screen_parts (part_number, screen_type, assembly_type, manufacturer, notes)
SELECT 'BG6CL', 'LCD', 'LCD + touch, without frame', 'Aftermarket',
       'Supplier SKU BG6CL. Do not assume it is interchangeable with FPC6605-5; this is a separate listed assembly.'
WHERE NOT EXISTS (SELECT 1 FROM screen_parts WHERE LOWER(part_number)=LOWER('BG6CL'));

WITH input(brand, marketing_name, model_code) AS (VALUES
 ('Tecno','Spark Go 2024','BG6'),
 ('Tecno','Spark 20','KJ5'),
 ('Infinix','Smart 8','X6525'),
 ('Infinix','Smart 8 Plus','X6526'),
 ('Infinix','Hot 40i','X6528 / X6528B')
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
SELECT d.id, sp.id, 'supplier_listed', 'Dama Mobile Spares product listing (SKU BG6CL)',
 'https://damamobilespares.co.ke/product/tecno-bg6-comp-lcd/',
 'Supplier listing explicitly groups this model with SKU BG6CL. Aftermarket supplier claim; verify connector, flex layout and physical fit.'
FROM devices d
JOIN brands b ON b.id=d.brand_id
JOIN screen_parts sp ON LOWER(sp.part_number)=LOWER('BG6CL')
WHERE (b.name='Tecno' AND d.marketing_name IN ('Spark Go 2024','Spark 20'))
   OR (b.name='Infinix' AND d.marketing_name IN ('Smart 8','Smart 8 Plus','Hot 40i'))
ON CONFLICT (device_id, screen_part_id) DO UPDATE SET
 status='supplier_listed', evidence_source=EXCLUDED.evidence_source,
 evidence_url=EXCLUDED.evidence_url, notes=EXCLUDED.notes;
