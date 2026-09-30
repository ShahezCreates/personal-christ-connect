
(async()=>{
  const auth=await window.CC_AUTH_READY; if(!auth?.session)return;
  const esc=CC_DB.esc, rest=CC_DB.rest;
  let clubs=[], orgs=[], joined=[];
  try {
    clubs=await rest('clubs?select=id,name,level,school,department,description,official_url&active=eq.true&order=level,name');
    orgs=await rest('campus_organizations?select=code,name,kind,description,official_url&active=eq.true&order=kind,name');
    joined=await rest('club_memberships?select=club_id');
  } catch(e){ console.error(e); }

  const joinedSet=new Set((joined||[]).map(x=>x.club_id));
  document.body.innerHTML=`
  <header class="cc-live-header"><a class="brand" href="dashboard.html"><span>C</span> CHRIST CONNECT</a><div><a href="dashboard.html">← My space</a><a href="index.html">Campus</a></div></header>
  <main class="cc-live-shell">
    <section class="cc-live-hero"><div><p class="eyebrow">DELHI NCR · COMMUNITIES</p><h1>Find your <em>people.</em></h1><p>Live directory data from Christ Connect PostgreSQL. University bodies and active clubs are shown separately.</p></div></section>
    <section class="org-group"><div class="group-head"><p class="eyebrow">UNIVERSITY BODIES & CENTRES</p><h2>Campus-wide <em>communities.</em></h2></div>
      <div class="org-grid">${(orgs||[]).map(o=>`<article class="org-card"><small>${esc(o.kind).toUpperCase()}</small><h3>${esc(o.code)} · ${esc(o.name)}</h3><p>${esc(o.description||'Delhi NCR campus organisation')}</p>${o.official_url?`<a href="${esc(o.official_url)}" target="_blank" rel="noopener">Official page ↗</a>`:''}</article>`).join('')}</div>
    </section>
    <section class="org-group"><div class="group-head"><p class="eyebrow">CLUB DIRECTORY</p><h2>Student <em>clubs.</em></h2></div>
      <div class="org-grid">${(clubs||[]).map(c=>`<article class="org-card"><small>${esc(c.level).toUpperCase()}${c.school?' · '+esc(c.school):''}</small><h3>${esc(c.name)}</h3><p>${esc(c.description||'Student club')}</p><div class="org-actions">${c.official_url?`<a href="${esc(c.official_url)}" target="_blank" rel="noopener">Official ↗</a>`:''}<button data-join="${c.id}" data-joined="${joinedSet.has(c.id)}">${joinedSet.has(c.id)?'Joined ✓':'Join club'}</button></div></article>`).join('')}</div>
    </section>
  </main><div class="cc-toast" id="ccToast"></div>`;
  const toast=document.querySelector('#ccToast');
  document.querySelectorAll('[data-join]').forEach(btn=>btn.onclick=async()=>{
    try{
      const id=btn.dataset.join, isJoined=btn.dataset.joined==='true';
      if(isJoined){
        await rest(`club_memberships?club_id=eq.${encodeURIComponent(id)}&student_id=eq.${encodeURIComponent(auth.session.user.id)}`,{method:'DELETE'});
        btn.dataset.joined='false'; btn.textContent='Join club';
        toast.textContent='Left the club.'; 
      } else {
        await rest('club_memberships',{method:'POST',headers:{'Content-Type':'application/json','Prefer':'return=minimal'},body:JSON.stringify({student_id:auth.session.user.id,club_id:id})});
        btn.dataset.joined='true'; btn.textContent='Joined ✓';
        toast.textContent='Joined the club.';
      }
      toast.classList.add('show');setTimeout(()=>toast.classList.remove('show'),1800);
    }catch(e){toast.textContent=e.message||'Could not update club membership.';toast.classList.add('show');setTimeout(()=>toast.classList.remove('show'),2200);}
  });
})();
