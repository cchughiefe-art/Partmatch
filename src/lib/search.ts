import { db } from "@/lib/db";

export type SearchResult = {
 screen_part_id:number;
 part_number:string;
 screen_type:string|null;
 assembly_type:string|null;
 manufacturer:string|null;
 color:string|null; quality_class:string|null; touchscreen:string|null; matrix_type:string|null; source_title:string|null; source_product_id:string|null;
 device_id:number;
 brand:string;
 marketing_name:string;
 model_code:string|null;
 region:string|null;
 status:"verified"|"supplier_listed"|"unverified"|"disputed"|"rejected";
 evidence_source:string|null;
 evidence_url:string|null;
 notes:string|null;
};

export async function searchCompatibility(term:string):Promise<SearchResult[]> {
 if (!db) throw new Error("DATABASE_NOT_CONFIGURED");
 const q = term.trim().slice(0,100);
 if (q.length < 2) return [];
 const pattern = "%" + q + "%";
 const rows = await db.query(
  "SELECT sp.id AS screen_part_id, sp.part_number, sp.screen_type, sp.assembly_type, sp.manufacturer, sp.color, sp.quality_class, sp.touchscreen, sp.matrix_type, sp.source_title, sp.source_product_id, d.id AS device_id, b.name AS brand, d.marketing_name, d.model_code, d.region, c.status, c.evidence_source, c.evidence_url, c.notes FROM compatibilities c JOIN devices d ON d.id=c.device_id JOIN brands b ON b.id=d.brand_id JOIN screen_parts sp ON sp.id=c.screen_part_id WHERE c.status <> 'rejected' AND (d.marketing_name ILIKE $1 OR COALESCE(d.model_code,'') ILIKE $1 OR COALESCE(d.model_aliases,'') ILIKE $1 OR sp.part_number ILIKE $1 OR COALESCE(sp.search_aliases,'') ILIKE $1 OR COALESCE(sp.source_title,'') ILIKE $1 OR b.name ILIKE $1 OR COALESCE(sp.manufacturer,'') ILIKE $1) ORDER BY CASE c.status WHEN 'verified' THEN 1 WHEN 'supplier_listed' THEN 2 WHEN 'unverified' THEN 3 WHEN 'disputed' THEN 4 ELSE 5 END, b.name, d.marketing_name LIMIT 100",
  [pattern]
 );
 return rows as SearchResult[];
}
