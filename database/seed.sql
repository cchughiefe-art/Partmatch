-- Minimal, idempotent first supplier listing for PartMatch.
-- Source title preserved verbatim. Compatibility is supplier-listed, not bench verified.
INSERT INTO brands (name, slug) VALUES ('Tecno','tecno'), ('Infinix','infinix')
ON CONFLICT (name) DO NOTHING;

INSERT INTO screen_parts
 (part_number, screen_type, assembly_type, manufacturer, notes, color, quality_class, touchscreen, matrix_type, source_title, source_product_id, search_aliases)
SELECT
 'FPC6605-5', 'IPS LCD', 'LCD + touch, without frame', 'Aftermarket',
 'Supplier-listed compatibility only. Confirm dimensions, flex position, connector, pinout and touch before fitting.',
 'Black', 'High Copy', 'With touchscreen', 'IPS',
 'LCDs compatible with Tecno Pop 7 (BF6), Pop 7 Pro, Spark 10, Spark Go (2023) (BF7); Infinix Smart 7 (X6515), Smart 7 HD (X6516), (black, without frame, High Copy, BF7, BF6, KI5q, KI5k) #FPC6605-5',
 'Supplier listing supplied by user',
 'BF7 BF6 KI5Q KI5K'
WHERE NOT EXISTS (SELECT 1 FROM screen_parts WHERE LOWER(part_number)='fpc6605-5');

UPDATE screen_parts SET
 screen_type='IPS LCD',
 assembly_type='LCD + touch, without frame',
 manufacturer='Aftermarket',
 notes='Supplier-listed compatibility only. Confirm dimensions, flex position, connector, pinout and touch before fitting.',
 color='Black', quality_class='High Copy', touchscreen='With touchscreen', matrix_type='IPS',
 source_title='LCDs compatible with Tecno Pop 7 (BF6), Pop 7 Pro, Spark 10, Spark Go (2023) (BF7); Infinix Smart 7 (X6515), Smart 7 HD (X6516), (black, without frame, High Copy, BF7, BF6, KI5q, KI5k) #FPC6605-5',
 source_product_id='Supplier listing supplied by user',
 search_aliases='BF7 BF6 KI5Q KI5K'
WHERE LOWER(part_number)='fpc6605-5';

WITH input(brand, marketing_name, model_code) AS (VALUES
 ('Tecno','Pop 7','BF6'),
 ('Tecno','Pop 7 Pro',NULL),
 ('Tecno','Spark 10','KI5Q'),
 ('Tecno','Spark Go (2023)','BF7'),
 ('Infinix','Smart 7','X6515'),
 ('Infinix','Smart 7 HD','X6516')
)
INSERT INTO devices (brand_id, marketing_name, model_code)
SELECT b.id, i.marketing_name, i.model_code
FROM input i
JOIN brands b ON LOWER(b.name)=LOWER(i.brand)
WHERE NOT EXISTS (
 SELECT 1 FROM devices d
 WHERE d.brand_id=b.id AND LOWER(d.marketing_name)=LOWER(i.marketing_name)
);

DELETE FROM compatibilities c USING devices d, brands b, screen_parts sp
WHERE c.device_id=d.id AND d.brand_id=b.id AND c.screen_part_id=sp.id
  AND LOWER(sp.part_number)='fpc6605-5'
  AND LOWER(b.name)='tecno' AND LOWER(d.marketing_name)='spark 10c';

INSERT INTO compatibilities (device_id, screen_part_id, status, evidence_source, evidence_url, notes)
SELECT d.id, sp.id, 'supplier_listed',
 'Supplier listing supplied by user',
 NULL,
 'Phone is explicitly named in the supplied listing. Supplier claim only; physical fit is not independently verified.'
FROM devices d
JOIN brands b ON b.id=d.brand_id
JOIN screen_parts sp ON LOWER(sp.part_number)='fpc6605-5'
WHERE (LOWER(b.name)='tecno' AND LOWER(d.marketing_name) IN ('pop 7','pop 7 pro','spark 10','spark go (2023)'))
   OR (LOWER(b.name)='infinix' AND LOWER(d.marketing_name) IN ('smart 7','smart 7 hd'))
ON CONFLICT (device_id, screen_part_id) DO UPDATE SET
 status='supplier_listed',
 evidence_source=EXCLUDED.evidence_source,
 evidence_url=EXCLUDED.evidence_url,
 notes=EXCLUDED.notes;
