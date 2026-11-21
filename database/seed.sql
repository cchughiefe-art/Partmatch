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
INSERT INTO screen_parts
 (part_number, screen_type, assembly_type, manufacturer, notes, color, quality_class, touchscreen, matrix_type, source_title, source_product_id)
SELECT 'FPC6605-5', 'IPS LCD', 'LCD + touch, without frame', 'Aftermarket',
       'Supplier listing identifiers: BF7, BF6, KI5Q and KI5K. Supplier claim only; compare flex position, connector, dimensions and touch before installation.',
       'Black', 'High Copy', 'With touchscreen', 'IPS',
       'LCDs compatible with Tecno Pop 7 (BF6), Pop 7 Pro, Spark 10, Spark Go (2023) (BF7); Infinix Smart 7 (X6515), Smart 7 HD (X6516), black, without frame, High Copy, BF7, BF6, KI5q, KI5k',
       'GsmServer 916763'
WHERE NOT EXISTS (SELECT 1 FROM screen_parts WHERE LOWER(part_number)=LOWER('FPC6605-5'));

UPDATE screen_parts SET
 screen_type='IPS LCD', assembly_type='LCD + touch, without frame', manufacturer='Aftermarket',
 color='Black', quality_class='High Copy', touchscreen='With touchscreen', matrix_type='IPS',
 source_title='LCDs compatible with Tecno Pop 7 (BF6), Pop 7 Pro, Spark 10, Spark Go (2023) (BF7); Infinix Smart 7 (X6515), Smart 7 HD (X6516), black, without frame, High Copy, BF7, BF6, KI5q, KI5k',
 source_product_id='GsmServer 916763'
WHERE LOWER(part_number)=LOWER('FPC6605-5');

WITH input(brand, marketing_name, model_code) AS (VALUES
 ('Tecno','Spark Go (2023)','BF7 / BF7N'),
 ('Tecno','Pop 7','BF6'),
 ('Tecno','Pop 7 Pro','BF7 / BF7H'),
 ('Tecno','Spark 10','KI5Q'),
 ('Tecno','Spark 10C','KI5K / KI5M'),
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
SELECT d.id, sp.id, 'unverified', 'GsmServer product listing',
 'https://gsmserver.com/en/lcd-compatible-with-tecno-pop-7-spark-go-2023-infinix-smart-7-black-without-frame-high-copy-bf7-bf6/',
 'Supplier explicitly lists this device as compatible with FPC6605-5. Aftermarket listing only, physical fit and touch must be tested.'
FROM devices d
JOIN brands b ON b.id=d.brand_id
JOIN screen_parts sp ON LOWER(sp.part_number)=LOWER('FPC6605-5')
WHERE (b.name='Tecno' AND d.marketing_name IN ('Spark Go (2023)','Pop 7','Pop 7 Pro','Spark 10','Spark 10C'))
   OR (b.name='Infinix' AND d.marketing_name IN ('Smart 7','Smart 7 HD'))
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


-- Additional Combo Universal brand pages, 2026.
-- Each CU-* identifier is an internal reference group, NOT a retail flex/part number.
-- Models are grouped only when Combo Universal places them in the same LCD/Combo entry.
-- All records below are supplier-listed claims and require physical verification.

INSERT INTO brands (name, slug) VALUES
 ('Motorola','motorola'),('Samsung','samsung'),('Xiaomi','xiaomi'),
 ('Redmi','redmi'),('Poco','poco'),('Vivo','vivo'),('iQOO','iqoo'),
 ('Oppo','oppo'),('Realme','realme'),('OnePlus','oneplus')
ON CONFLICT (name) DO NOTHING;

-- Motorola groups
INSERT INTO screen_parts (part_number,screen_type,assembly_type,manufacturer,notes)
VALUES
 ('CU-MOTO-2026-001','LCD','Curved LCD / Screen Combo','Combo Universal reference group','Motorola list: Moto G85, Moto G96 5G, Edge 50 Fusion 5G, Edge S50 Neo. Not a retail part number.'),
 ('CU-MOTO-2026-002','LCD','LCD / Screen Combo','Combo Universal reference group','Motorola list: Moto E40 and Moto E30. Not a retail part number.'),
 ('CU-MOTO-2026-003','LCD','Punch-hole Combo','Combo Universal reference group','Motorola list: Moto G13, G45 5G, G34 5G, G53 5G, G23. Not a retail part number.'),
 ('CU-MOTO-2026-004','LCD','LCD / Screen Combo','Combo Universal reference group','Motorola list: Moto G22, Moto E32, Moto E32s. Not a retail part number.')
ON CONFLICT DO NOTHING;

-- Samsung groups
INSERT INTO screen_parts (part_number,screen_type,assembly_type,manufacturer,notes)
VALUES
 ('CU-SAM-2026-001','LCD','Notch LCD / Display Combo','Combo Universal reference group','Samsung list: A02S (SM-A025), M02S, A03 (SM-A035), A03S (A037F), A04E, M04, F04, F02S. Not a retail part number.'),
 ('CU-SAM-2026-002','LCD','Side punch-hole display','Combo Universal reference group','Samsung list: M11 and A11. Not a retail part number.'),
 ('CU-SAM-2026-003','LCD','LCD / Screen Combo','Combo Universal reference group','Samsung list: A30, A30S, A50, A50S. Not a retail part number.'),
 ('CU-SAM-2026-004','LCD','LCD / Screen Combo','Combo Universal reference group','Samsung list: F22, A22 4G, M22. Not a retail part number.'),
 ('CU-SAM-2026-005','LCD','LCD / Screen Combo','Combo Universal reference group','Samsung list: M10 (M105) and A10 (A105). Not a retail part number.')
ON CONFLICT DO NOTHING;

-- Xiaomi / Redmi / Poco groups
INSERT INTO screen_parts (part_number,screen_type,assembly_type,manufacturer,notes)
VALUES
 ('CU-XIA-2026-001','LCD','LCD / Screen Combo','Combo Universal reference group','Xiaomi list: Redmi 5A and Redmi Go. Not a retail part number.'),
 ('CU-XIA-2026-002','LCD','LCD / Screen Combo','Combo Universal reference group','Xiaomi list: Redmi 6A and Redmi 6. Not a retail part number.'),
 ('CU-XIA-2026-003','LCD','Punch-hole display, single flex','Combo Universal reference group','Xiaomi list: Poco X3, Poco X3 Pro, Mi 10i, Redmi Note 9 Pro 5G. Not a retail part number.'),
 ('CU-XIA-2026-004','LCD','Notch LCD','Combo Universal reference group','Xiaomi list: Redmi Note 7, Note 7 Pro, Note 7S. Not a retail part number.'),
 ('CU-XIA-2026-005','LCD','Notch LCD / Display Combo','Combo Universal reference group','Xiaomi list: Poco C61, Redmi A3, Redmi A3X. Not a retail part number.'),
 ('CU-XIA-2026-006','LCD','Notch LCD / Screen','Combo Universal reference group','Xiaomi list: Redmi 13C 4G, 13C 5G, Poco M6 5G, Poco C65. Not a retail part number.')
ON CONFLICT DO NOTHING;

-- Oppo / Realme / OnePlus groups
INSERT INTO screen_parts (part_number,screen_type,assembly_type,manufacturer,notes)
VALUES
 ('CU-ORO-2026-001','LCD','Notch Combo','Combo Universal reference group','Source list: Oppo F11, Oppo A9, Oppo A9X. Not a retail part number.'),
 ('CU-ORO-2026-002','LCD','Side Flex','Combo Universal reference group','Source list: Realme X, Oppo K3, Reno 2Z, Reno 2F. Not a retail part number.'),
 ('CU-ORO-2026-003','LCD','Notch LCD','Combo Universal reference group','Source list: Realme C61 4G, C63 4G, Narzo N63, Note 60 4G, Note 60X. Not a retail part number.'),
 ('CU-ORO-2026-004','LCD','Side Camera Punch-hole display','Combo Universal reference group','Source list: Realme Q3, Oppo A54 5G, A74 5G, A93 5G, OnePlus Nord N200. Not a retail part number.'),
 ('CU-ORO-2026-005','LCD','Notch Combo','Combo Universal reference group','Source list: Realme C2 and Oppo A1K. Not a retail part number.')
ON CONFLICT DO NOTHING;

-- Vivo / iQOO groups
INSERT INTO screen_parts (part_number,screen_type,assembly_type,manufacturer,notes)
VALUES
 ('CU-VIVO-2026-001','LCD','LCD / Combo / Display','Combo Universal reference group','Vivo/iQOO V4.0 source group: Y20 family, Y10, Y11S, Y12 family, Y21 family, Y22 family, Y24A, Y15 family, Y01, Y02S, Y16, Y17S and other models enumerated on source page. Not a retail part number.'),
 ('CU-VIVO-2026-002','LCD','Notch Folder / Combo / Display','Combo Universal reference group','Vivo source group: V9, V9 Youth, V9 Pro, Y85, Z1i, Z1, Z3X. Not a retail part number.'),
 ('CU-VIVO-2026-003','LCD','Notch LCD / Display Combo','Combo Universal reference group','Vivo source group: Y27, Y27 5G, Y27S, Y35 Plus, Y35M Plus, Y27 4G, Y36, Y55T. Not a retail part number.'),
 ('CU-VIVO-2026-004','LCD','Curved LCD / Combo','Combo Universal reference group','Vivo source group: V40E, T3 Pro, iQOO Z9S, iQOO Z9S Pro. Not a retail part number.')
ON CONFLICT DO NOTHING;

WITH group_devices(group_code,brand,phone,model_code) AS (VALUES
 ('CU-MOTO-2026-001','Motorola','Moto G85',NULL),('CU-MOTO-2026-001','Motorola','Moto G96 5G',NULL),('CU-MOTO-2026-001','Motorola','Moto Edge 50 Fusion 5G',NULL),('CU-MOTO-2026-001','Motorola','Moto Edge S50 Neo',NULL),
 ('CU-MOTO-2026-002','Motorola','Moto E40',NULL),('CU-MOTO-2026-002','Motorola','Moto E30',NULL),
 ('CU-MOTO-2026-003','Motorola','Moto G13',NULL),('CU-MOTO-2026-003','Motorola','Moto G45 5G',NULL),('CU-MOTO-2026-003','Motorola','Moto G34 5G',NULL),('CU-MOTO-2026-003','Motorola','Moto G53 5G',NULL),('CU-MOTO-2026-003','Motorola','Moto G23',NULL),
 ('CU-MOTO-2026-004','Motorola','Moto G22',NULL),('CU-MOTO-2026-004','Motorola','Moto E32',NULL),('CU-MOTO-2026-004','Motorola','Moto E32s',NULL),
 ('CU-SAM-2026-001','Samsung','Galaxy A02s','SM-A025'),('CU-SAM-2026-001','Samsung','Galaxy M02s',NULL),('CU-SAM-2026-001','Samsung','Galaxy A03','SM-A035'),('CU-SAM-2026-001','Samsung','Galaxy A03s','A037F'),('CU-SAM-2026-001','Samsung','Galaxy A04e',NULL),('CU-SAM-2026-001','Samsung','Galaxy M04',NULL),('CU-SAM-2026-001','Samsung','Galaxy F04',NULL),('CU-SAM-2026-001','Samsung','Galaxy F02s',NULL),
 ('CU-SAM-2026-002','Samsung','Galaxy M11',NULL),('CU-SAM-2026-002','Samsung','Galaxy A11',NULL),
 ('CU-SAM-2026-003','Samsung','Galaxy A30',NULL),('CU-SAM-2026-003','Samsung','Galaxy A30s',NULL),('CU-SAM-2026-003','Samsung','Galaxy A50',NULL),('CU-SAM-2026-003','Samsung','Galaxy A50s',NULL),
 ('CU-SAM-2026-004','Samsung','Galaxy F22',NULL),('CU-SAM-2026-004','Samsung','Galaxy A22 4G',NULL),('CU-SAM-2026-004','Samsung','Galaxy M22',NULL),
 ('CU-SAM-2026-005','Samsung','Galaxy M10','M105'),('CU-SAM-2026-005','Samsung','Galaxy A10','A105'),
 ('CU-XIA-2026-001','Redmi','Redmi 5A',NULL),('CU-XIA-2026-001','Redmi','Redmi Go',NULL),
 ('CU-XIA-2026-002','Redmi','Redmi 6A',NULL),('CU-XIA-2026-002','Redmi','Redmi 6',NULL),
 ('CU-XIA-2026-003','Poco','Poco X3',NULL),('CU-XIA-2026-003','Poco','Poco X3 Pro',NULL),('CU-XIA-2026-003','Xiaomi','Mi 10i',NULL),('CU-XIA-2026-003','Redmi','Redmi Note 9 Pro 5G',NULL),
 ('CU-XIA-2026-004','Redmi','Redmi Note 7',NULL),('CU-XIA-2026-004','Redmi','Redmi Note 7 Pro',NULL),('CU-XIA-2026-004','Redmi','Redmi Note 7S',NULL),
 ('CU-XIA-2026-005','Poco','Poco C61',NULL),('CU-XIA-2026-005','Redmi','Redmi A3',NULL),('CU-XIA-2026-005','Redmi','Redmi A3X',NULL),
 ('CU-XIA-2026-006','Redmi','Redmi 13C 4G',NULL),('CU-XIA-2026-006','Redmi','Redmi 13C 5G',NULL),('CU-XIA-2026-006','Poco','Poco M6 5G',NULL),('CU-XIA-2026-006','Poco','Poco C65',NULL),
 ('CU-ORO-2026-001','Oppo','Oppo F11',NULL),('CU-ORO-2026-001','Oppo','Oppo A9',NULL),('CU-ORO-2026-001','Oppo','Oppo A9X',NULL),
 ('CU-ORO-2026-002','Realme','Realme X',NULL),('CU-ORO-2026-002','Oppo','Oppo K3',NULL),('CU-ORO-2026-002','Oppo','Oppo Reno 2Z',NULL),('CU-ORO-2026-002','Oppo','Oppo Reno 2F',NULL),
 ('CU-ORO-2026-003','Realme','Realme C61 4G',NULL),('CU-ORO-2026-003','Realme','Realme C63 4G',NULL),('CU-ORO-2026-003','Realme','Realme Narzo N63',NULL),('CU-ORO-2026-003','Realme','Realme Note 60 4G',NULL),('CU-ORO-2026-003','Realme','Realme Note 60X',NULL),
 ('CU-ORO-2026-004','Realme','Realme Q3',NULL),('CU-ORO-2026-004','Oppo','Oppo A54 5G',NULL),('CU-ORO-2026-004','Oppo','Oppo A74 5G',NULL),('CU-ORO-2026-004','Oppo','Oppo A93 5G',NULL),('CU-ORO-2026-004','OnePlus','OnePlus Nord N200',NULL),
 ('CU-ORO-2026-005','Realme','Realme C2',NULL),('CU-ORO-2026-005','Oppo','Oppo A1K',NULL),
 ('CU-VIVO-2026-001','Vivo','Vivo Y20 family',NULL),('CU-VIVO-2026-001','Vivo','Vivo Y10',NULL),('CU-VIVO-2026-001','Vivo','Vivo Y11S',NULL),('CU-VIVO-2026-001','Vivo','Vivo Y12 family',NULL),('CU-VIVO-2026-001','Vivo','Vivo Y21 family',NULL),('CU-VIVO-2026-001','Vivo','Vivo Y22 family',NULL),('CU-VIVO-2026-001','Vivo','Vivo Y24A',NULL),('CU-VIVO-2026-001','Vivo','Vivo Y15 family',NULL),
 ('CU-VIVO-2026-002','Vivo','Vivo V9',NULL),('CU-VIVO-2026-002','Vivo','Vivo V9 Youth',NULL),('CU-VIVO-2026-002','Vivo','Vivo V9 Pro',NULL),('CU-VIVO-2026-002','Vivo','Vivo Y85',NULL),('CU-VIVO-2026-002','Vivo','Vivo Z1i',NULL),('CU-VIVO-2026-002','Vivo','Vivo Z1',NULL),('CU-VIVO-2026-002','Vivo','Vivo Z3X',NULL),
 ('CU-VIVO-2026-003','Vivo','Vivo Y27',NULL),('CU-VIVO-2026-003','Vivo','Vivo Y27 5G',NULL),('CU-VIVO-2026-003','Vivo','Vivo Y27S',NULL),('CU-VIVO-2026-003','Vivo','Vivo Y35 Plus',NULL),('CU-VIVO-2026-003','Vivo','Vivo Y35M Plus',NULL),('CU-VIVO-2026-003','Vivo','Vivo Y27 4G',NULL),('CU-VIVO-2026-003','Vivo','Vivo Y36',NULL),('CU-VIVO-2026-003','Vivo','Vivo Y55T',NULL),
 ('CU-VIVO-2026-004','Vivo','Vivo V40E',NULL),('CU-VIVO-2026-004','Vivo','Vivo T3 Pro',NULL),('CU-VIVO-2026-004','iQOO','iQOO Z9S',NULL),('CU-VIVO-2026-004','iQOO','iQOO Z9S Pro',NULL)
),
new_devices AS (
 INSERT INTO devices (brand_id,marketing_name,model_code)
 SELECT b.id,g.phone,g.model_code FROM group_devices g JOIN brands b ON LOWER(b.name)=LOWER(g.brand)
 WHERE NOT EXISTS (SELECT 1 FROM devices d WHERE d.brand_id=b.id AND LOWER(d.marketing_name)=LOWER(g.phone))
 RETURNING id,brand_id,marketing_name
)
INSERT INTO compatibilities(device_id,screen_part_id,status,evidence_source,evidence_url,notes)
SELECT d.id,sp.id,'supplier_listed','Combo Universal 2026 brand compatibility lists',src.url,
 'Supplier-list grouped compatibility claim only; no retail flex part number is implied. Confirm connector, dimensions and touch before fitting.'
FROM group_devices g
JOIN brands b ON LOWER(b.name)=LOWER(g.brand)
JOIN devices d ON d.brand_id=b.id AND LOWER(d.marketing_name)=LOWER(g.phone)
JOIN screen_parts sp ON sp.part_number=g.group_code
JOIN (VALUES
 ('CU-MOTO-2026-001','https://combouniversal.com/motorola-universal-combo-list/'),
 ('CU-MOTO-2026-002','https://combouniversal.com/motorola-universal-combo-list/'),
 ('CU-MOTO-2026-003','https://combouniversal.com/motorola-universal-combo-list/'),
 ('CU-MOTO-2026-004','https://combouniversal.com/motorola-universal-combo-list/'),
 ('CU-SAM-2026-001','https://combouniversal.com/samsung-universal-combo-list/'),
 ('CU-SAM-2026-002','https://combouniversal.com/samsung-universal-combo-list/'),
 ('CU-SAM-2026-003','https://combouniversal.com/samsung-universal-combo-list/'),
 ('CU-SAM-2026-004','https://combouniversal.com/samsung-universal-combo-list/'),
 ('CU-SAM-2026-005','https://combouniversal.com/samsung-universal-combo-list/'),
 ('CU-XIA-2026-001','https://combouniversal.com/xiaomi-poco-redmi-mi-combo-universal-list/'),
 ('CU-XIA-2026-002','https://combouniversal.com/xiaomi-poco-redmi-mi-combo-universal-list/'),
 ('CU-XIA-2026-003','https://combouniversal.com/xiaomi-poco-redmi-mi-combo-universal-list/'),
 ('CU-XIA-2026-004','https://combouniversal.com/xiaomi-poco-redmi-mi-combo-universal-list/'),
 ('CU-XIA-2026-005','https://combouniversal.com/xiaomi-poco-redmi-mi-combo-universal-list/'),
 ('CU-XIA-2026-006','https://combouniversal.com/xiaomi-poco-redmi-mi-combo-universal-list/'),
 ('CU-ORO-2026-001','https://combouniversal.com/realme-oppo-oneplus-universal-combo-list/'),
 ('CU-ORO-2026-002','https://combouniversal.com/realme-oppo-oneplus-universal-combo-list/'),
 ('CU-ORO-2026-003','https://combouniversal.com/realme-oppo-oneplus-universal-combo-list/'),
 ('CU-ORO-2026-004','https://combouniversal.com/realme-oppo-oneplus-universal-combo-list/'),
 ('CU-ORO-2026-005','https://combouniversal.com/realme-oppo-oneplus-universal-combo-list/'),
 ('CU-VIVO-2026-001','https://combouniversal.com/iqoo-vivo-universal-combo-list/'),
 ('CU-VIVO-2026-002','https://combouniversal.com/iqoo-vivo-universal-combo-list/'),
 ('CU-VIVO-2026-003','https://combouniversal.com/iqoo-vivo-universal-combo-list/'),
 ('CU-VIVO-2026-004','https://combouniversal.com/iqoo-vivo-universal-combo-list/')
) AS src(group_code,url) ON src.group_code=g.group_code
ON CONFLICT(device_id,screen_part_id) DO UPDATE SET
 status='supplier_listed',evidence_source=EXCLUDED.evidence_source,evidence_url=EXCLUDED.evidence_url,notes=EXCLUDED.notes;
