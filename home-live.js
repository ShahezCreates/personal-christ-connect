
(async()=>{
  try{
    const cfg=window.CHRIST_CONNECT_CONFIG;
    if(!cfg?.SUPABASE_URL)return;
    const base={apikey:cfg.SUPABASE_ANON_KEY};
    const get=async path=>{
      const r=await fetch(`${cfg.SUPABASE_URL}/rest/v1/${path}`,{headers:base});
      if(!r.ok)throw new Error(await r.text());
      return r.json();
    };
    const [orgs,shops]=await Promise.all([
      get('campus_organizations?select=id,code,name,kind,active&active=eq.true'),
      get('canteen_shops?select=id,name,active&active=eq.true')
    ]);
    const orgEl=document.querySelector('#campusOrgCount');
    const diningEl=document.querySelector('#diningCount');
    if(orgEl)orgEl.textContent=(orgs?.length||0)+'+';
    if(diningEl)diningEl.textContent=(shops?.length||0);
    const links=document.querySelectorAll('[data-live-org]');
    links.forEach((el,i)=>{ if(orgs?.[i]) el.textContent=orgs[i].name; });
    const outletStrip=document.querySelector('#liveDiningStrip');
    if(outletStrip && shops?.length){
      outletStrip.innerHTML=shops.map(s=>`<div><span>CAMPUS DINING</span><b>${String(s.name).replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]))}</b></div>`).join('');
    }
  }catch(e){console.warn('Christ Connect public live data unavailable',e)}
})();
