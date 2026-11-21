"use client";
import { FormEvent, useState } from "react";
type Result = {
 screen_part_id:number; part_number:string; screen_type:string|null; assembly_type:string|null; manufacturer:string|null; color:string|null; quality_class:string|null; touchscreen:string|null; matrix_type:string|null; source_title:string|null; source_product_id:string|null;
 device_id:number; brand:string; marketing_name:string; model_code:string|null; region:string|null; status:string;
 evidence_source:string|null; evidence_url:string|null; notes:string|null; checked_at:string|null;
};
const statusLabels:Record<string,string> = {verified:"Verified",supplier_listed:"Supplier listed",unverified:"Unverified",disputed:"Disputed"};
export default function Home() {
 const [query,setQuery]=useState(""); const [results,setResults]=useState<Result[]>([]);
 const [loading,setLoading]=useState(false); const [searched,setSearched]=useState(false); const [error,setError]=useState("");
 async function handleSearch(event:FormEvent<HTMLFormElement>) {
  event.preventDefault(); if(query.trim().length<2)return;
  setLoading(true);setError("");setSearched(true);
  try {
   const response=await fetch("/api/search?q="+encodeURIComponent(query.trim()));
   const data=await response.json(); if(!response.ok)throw new Error(data.error||"Search could not be completed.");
   setResults(data.results||[]);
  } catch(err) {setResults([]);setError(err instanceof Error?err.message:"Something went wrong.");}
  finally {setLoading(false);}
 }
 const grouped=results.reduce<Record<number,{part:Result;devices:Result[]}>>((acc,item)=>{
  if(!acc[item.screen_part_id])acc[item.screen_part_id]={part:item,devices:[]};
  acc[item.screen_part_id].devices.push(item);return acc;
 },{});
 return <main className="shell">
  <header className="topbar"><a className="brandmark" href="/"><span className="brand-icon">P</span>part<span>match</span></a><span className="top-note">PHONE PARTS REFERENCE</span></header>
  <section className="hero">
   <div className="eyebrow"><span className="pulse"/> LCD COMPATIBILITY DATABASE</div>
   <h1>Find the right screen.<br/><em>Before you fit it.</em></h1>
   <p className="intro">Search by phone name, model code, or LCD part number. See which devices share a display assembly and check the evidence behind each match.</p>
   <form className="searchbox" onSubmit={handleSearch}>
    <span className="search-symbol">⌕</span>
    <input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Try Moto G Power, BG6, or a screen part number" aria-label="Search phones, model codes, or screen part numbers" minLength={2}/>
    <button type="submit" disabled={loading||query.trim().length<2}>{loading?"Searching…":"Search"}</button>
   </form>
   <div className="search-hints"><span>SEARCH BY</span><b>Phone model</b><i>·</i><b>Model code</b><i>·</i><b>LCD part number</b></div>
  </section>
  <section className="results-section" aria-live="polite">
   {error&&<div className="notice error">{error}</div>}
   {!searched&&!error&&<div className="empty-state"><div className="empty-icon">⌕</div><h2>One search. Multiple ways to match.</h2><p>Enter a device model, its internal model code, or the part number printed on a replacement screen.</p><div className="feature-row"><div><strong>01</strong><span>Search model codes</span></div><div><strong>02</strong><span>Group shared screens</span></div><div><strong>03</strong><span>Check evidence status</span></div></div></div>}
   {searched&&!loading&&!error&&results.length===0&&<div className="empty-state compact"><h2>No matching records yet</h2><p>Try another spelling or model code. A missing result means this database has no matching entry yet—not that the screen is incompatible.</p></div>}
   {results.length>0&&<><div className="results-heading"><div><span className="eyebrow">MATCH RESULTS</span><h2>{results.length} compatible device record{results.length===1?"":"s"}</h2></div><span className="group-count">{Object.keys(grouped).length} screen group{Object.keys(grouped).length===1?"":"s"}</span></div>
    <div className="result-list">{Object.values(grouped).map(({part,devices})=><article className="part-card" key={part.screen_part_id}>
     <div className="part-head"><div><span className="card-label">SCREEN / LCD PART</span><h3>{part.part_number}</h3></div><span className="device-count">{devices.length} device{devices.length===1?"":"s"}</span></div>
     <div className="part-meta">{part.screen_type&&<span>{part.screen_type}</span>}{part.assembly_type&&<span>{part.assembly_type}</span>}{part.manufacturer&&<span>{part.manufacturer}</span>}{part.color&&<span>{part.color}</span>}{part.quality_class&&<span>{part.quality_class}</span>}{part.touchscreen&&<span>{part.touchscreen}</span>}{part.matrix_type&&<span>{part.matrix_type}</span>}</div>
     <div className="device-list">{devices.map(device=><div className="device-row" key={device.device_id}><div><strong>{device.brand} {device.marketing_name}</strong><small>{device.model_code||"Model code not recorded"}{device.region?" · "+device.region:""}</small></div><span className={"status status-"+device.status}>{statusLabels[device.status]||device.status}</span></div>)}</div>
     {(part.evidence_source||part.evidence_url||part.notes)&&<div className="evidence"><span className="card-label">EVIDENCE &amp; NOTES</span><p>{part.evidence_source||"Source not recorded"}{part.notes?" — "+part.notes:""}</p>{part.evidence_url&&<a href={part.evidence_url} target="_blank" rel="noreferrer">Open evidence ↗</a>}</div>}
    </article>)}</div></>}
  </section>
  <footer><span>PARTMATCH <b>·</b> REFERENCE TOOL</span><span>Compatibility should be confirmed before installation.</span></footer>
 </main>;
}
