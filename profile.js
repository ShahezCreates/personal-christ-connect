(() => {
  const cfg = window.CHRIST_CONNECT_CONFIG;
  const stored = JSON.parse(localStorage.getItem('cc_session') || 'null');
  const token = stored?.access_token || stored?.session?.access_token;
  if (!token || !cfg || !cfg.SUPABASE_URL || cfg.SUPABASE_URL.includes('YOUR_PROJECT')) {
    location.href = 'portal.html';
    return;
  }

  const tabs = [...document.querySelectorAll('[data-tab]')];
  const panels = [...document.querySelectorAll('.panel')];
  const validSections = panels.map(p => p.id);
  const toast = document.querySelector('#toast');
  let timer;
  const state = { profile:null, clubs:[], events:[], notifications:[] };

  function note(text) {
    toast.textContent = text;
    toast.classList.add('show');
    clearTimeout(timer);
    timer = setTimeout(() => toast.classList.remove('show'), 2300);
  }
  function initials(name='Student') { return name.split(/\s+/).filter(Boolean).map(x => x[0]).join('').slice(0,2).toUpperCase(); }
  function esc(text='') { const d=document.createElement('div'); d.textContent=String(text); return d.innerHTML; }
  function fmtDate(value) { if (!value) return ''; return new Date(value).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'numeric',minute:'2-digit'}); }

  async function api(path, opts={}) {
    const r = await fetch(`${cfg.SUPABASE_URL}/rest/v1/${path}`, {
      ...opts,
      headers: {
        apikey: cfg.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${token}`,
        ...(opts.headers || {})
      }
    });
    if (r.status === 401) { localStorage.removeItem('cc_session'); location.href='portal.html'; throw new Error('Session expired'); }
    if (!r.ok) throw new Error(await r.text());
    return r.status === 204 ? null : r.json();
  }

  function show(id) {
    const section = validSections.includes(id) ? id : 'overview';
    tabs.forEach(tab => tab.classList.toggle('active', tab.dataset.tab === section));
    panels.forEach(panel => panel.classList.toggle('active', panel.id === section));
    history.replaceState(null,'',`profile.html?section=${encodeURIComponent(section)}`);
    window.scrollTo({top:0,behavior:'smooth'});
    if (section === 'notifications') markNotificationsRendered();
  }
  tabs.forEach(tab => tab.addEventListener('click', () => show(tab.dataset.tab)));
  document.querySelectorAll('[data-go]').forEach(btn => btn.addEventListener('click', () => show(btn.dataset.go)));
  show(new URLSearchParams(location.search).get('section') || 'overview');

  async function load() {
    try {
      const p = (await api('student_profiles?select=*&limit=1'))[0];
      if (!p) throw new Error('Student profile not found');
      state.profile = p;
      const [clubs, events, notifications] = await Promise.all([
        api('club_memberships?select=joined_at,club_id,clubs(name,level,description)&order=joined_at.desc'),
        api('event_registrations?select=registered_at,event_id,events(title,starts_at,location)&order=registered_at.desc&limit=20'),
        api('notifications?select=id,title,body,is_read,created_at&order=created_at.desc&limit=20')
      ]);
      state.clubs = clubs || [];
      state.events = events || [];
      state.notifications = notifications || [];
      render();
    } catch (e) {
      console.error(e);
      note('Could not load all profile data.');
    }
  }

  function render() {
    const p=state.profile;
    document.querySelector('#name').textContent=p.full_name || 'Student';
    document.querySelector('#meta').textContent=[p.programme,p.department,p.batch_year && `Batch ${p.batch_year}`].filter(Boolean).join(' · ') || 'Christ Connect student';
    document.querySelector('#avatar').firstChild.textContent=initials(p.full_name);
    document.querySelector('#heroStatus').textContent=(p.status || 'ACTIVE').toUpperCase();
    document.querySelector('#heroCampus').textContent='Delhi NCR';
    document.querySelector('#fullNameInput').value=p.full_name || '';
    document.querySelector('#emailInput').value=p.university_email || '';
    document.querySelector('#regInput').value=p.registration_number || '';
    document.querySelector('#bioInput').value=p.bio || '';
    document.querySelector('#school').textContent=p.school || '—';
    document.querySelector('#department').textContent=p.department || '—';
    document.querySelector('#programme').textContent=p.programme || '—';
    document.querySelector('#batch').textContent=p.batch_year || '—';

    const prefs = JSON.parse(localStorage.getItem('cc_profile_preferences') || '{}');
    const skills = prefs.skills || ['Figma','JavaScript','Photography','Public speaking'];
    const interests = prefs.interests || ['Design','Music','Startups','Football','Film'];
    renderTags('#skillTags',skills,true);
    renderTags('#interestTags',interests,false);

    document.querySelector('#clubsSummary').textContent=`${state.clubs.length} clubs joined`;
    document.querySelector('#clubsSummaryText').textContent=state.clubs.length ? state.clubs.slice(0,3).map(x=>x.clubs?.name).filter(Boolean).join(' · ') : 'Explore campus communities.';
    document.querySelector('#eventsSummary').textContent=`${state.events.length} events saved`;
    document.querySelector('#eventsSummaryText').textContent=state.events.length ? 'Your registered events are here.' : 'No registered events yet.';

    const complete=[p.full_name,p.university_email,p.registration_number,p.school,p.department,p.programme,p.batch_year,p.bio].filter(Boolean).length;
    const pct=Math.round(complete/8*100);
    document.querySelector('#profileComplete').textContent=`${pct}%`;
    document.querySelector('#profileCompleteText').textContent=pct>=88?'Profile looks complete.':`Add a bio and missing academic details to reach ${Math.min(100,pct+12)}%.`;
    const unread=state.notifications.filter(n=>!n.is_read).length;
    document.querySelector('#notificationBadge').textContent=unread;

    document.querySelector('#clubItems').innerHTML = state.clubs.length ? state.clubs.map((m,i)=>`<div><span class="orb ${['red','yellow','blue'][i%3]}">${i===0?'⌘':i===1?'◒':'◈'}</span><p><b>${esc(m.clubs?.name || 'Club')}</b><small>${esc(m.clubs?.description || m.clubs?.level || 'Campus community')}</small></p></div>`).join('') : '<div><span class="orb">◌</span><p><b>No clubs joined yet.</b><small>Explore the clubs directory from Home.</small></p></div>';
    document.querySelector('#eventItems').innerHTML = state.events.length ? state.events.map((r,i)=>`<div><span class="orb yellow">${r.events?.starts_at ? new Date(r.events.starts_at).getDate() : '◫'}</span><p><b>${esc(r.events?.title || 'Campus event')}</b><small>${esc(r.events?.location || 'Campus')} · ${esc(fmtDate(r.events?.starts_at))}</small></p></div>`).join('') : '<div><span class="orb yellow">◫</span><p><b>No registered events yet.</b><small>Explore events to start building your calendar.</small></p></div>';
    document.querySelector('#ordersText').textContent='Canteen order history is ready for the connected backend; no student orders are currently recorded.';
    document.querySelector('#notificationsList').innerHTML = state.notifications.length ? state.notifications.map(n=>`<li>${n.is_read?'◌':'✦'} <span><b>${esc(n.title)}</b><small>${esc(n.body || '')} · ${esc(fmtDate(n.created_at))}</small></span></li>`).join('') : '<li>◌ <span><b>You are all caught up.</b><small>No notifications yet.</small></span></li>';
    const recent=[];
    state.events.slice(0,3).forEach(r=>recent.push(`◫|${r.events?.title || 'Campus event'}|${fmtDate(r.registered_at || r.events?.starts_at)}`));
    state.clubs.slice(0,2).forEach(r=>recent.push(`◌|Joined ${r.clubs?.name || 'a club'}|${fmtDate(r.joined_at)}`));
    state.notifications.filter(n=>!n.is_read).slice(0,2).forEach(n=>recent.push(`✦|${n.title}|${fmtDate(n.created_at)}`));
    document.querySelector('#recentActivity').innerHTML=recent.length?recent.slice(0,6).map(x=>{const [icon,title,when]=x.split('|');return `<li>${icon} <span><b>${esc(title)}</b><small>${esc(when)}</small></span></li>`}).join(''):'<li>◌ <span><b>Nothing new yet.</b><small>Your account activity will appear here.</small></span></li>';

    const pref=JSON.parse(localStorage.getItem('cc_settings')||'{}');
    document.querySelector('#prefEmail').checked=pref.email!==false;
    document.querySelector('#prefMarket').checked=pref.market!==false;
    document.querySelector('#prefSkills').checked=pref.skills===true;
  }

  function renderTags(selector, values, removable) {
    const container=document.querySelector(selector);
    container.innerHTML=values.map((value,i)=>`<span>${esc(value)}${removable?` <button type="button" data-skill-index="${i}">×</button>`:''}</span>`).join('');
    if (removable) container.onclick=e=>{const btn=e.target.closest('[data-skill-index]');if(!btn)return;const prefs=JSON.parse(localStorage.getItem('cc_profile_preferences')||'{}');const skills=prefs.skills||['Figma','JavaScript','Photography','Public speaking'];skills.splice(Number(btn.dataset.skillIndex),1);prefs.skills=skills;localStorage.setItem('cc_profile_preferences',JSON.stringify(prefs));renderTags(selector,skills,true);note('Skill removed.');};
  }

  document.querySelector('#addSkill').addEventListener('click',()=>{const value=prompt('Add a skill you can share:');if(!value?.trim())return;const prefs=JSON.parse(localStorage.getItem('cc_profile_preferences')||'{}');const skills=prefs.skills||['Figma','JavaScript','Photography','Public speaking'];skills.push(value.trim());prefs.skills=skills;localStorage.setItem('cc_profile_preferences',JSON.stringify(prefs));renderTags('#skillTags',skills,true);note('Skill added.');});

  function startEdit() {
    const form=document.querySelector('#profileForm');
    form.classList.add('editing');
    form.querySelectorAll('input,textarea').forEach(el=>{ if(!['emailInput','regInput'].includes(el.id)) el.disabled=false; });
    note('You can now update your details.');
  }
  document.querySelector('#edit').addEventListener('click',startEdit);
  document.querySelector('#save').addEventListener('click',async()=>{
    const payload={full_name:document.querySelector('#fullNameInput').value.trim(),bio:document.querySelector('#bioInput').value.trim()||null};
    if(!payload.full_name){note('Name cannot be empty.');return;}
    try{
      const p=state.profile;
      const r=await api(`student_profiles?id=eq.${encodeURIComponent(p.id)}`,{method:'PATCH',headers:{'Content-Type':'application/json',Prefer:'return=representation'},body:JSON.stringify(payload)});
      state.profile=r[0]||{...p,...payload};
      document.querySelector('#profileForm').classList.remove('editing');
      document.querySelector('#fullNameInput').disabled=true;document.querySelector('#bioInput').disabled=true;
      render();note('Profile details saved.');
    }catch(e){console.error(e);note('Could not save profile details.');}
  });

  async function markNotificationsRendered(){
    if(!state.notifications.some(n=>!n.is_read))return;
    // Do not auto-mark on navigation; user controls it.
  }
  document.querySelector('#read').addEventListener('click',async()=>{
    try{
      await api('notifications?student_id=eq.me&is_read=eq.false',{method:'PATCH',headers:{'Content-Type':'application/json'},body:JSON.stringify({is_read:true})});
    }catch(e){
      // RLS does not expose student_id="me" syntax, so update each allowed notification directly.
      await Promise.all(state.notifications.filter(n=>!n.is_read).map(n=>api(`notifications?id=eq.${n.id}`,{method:'PATCH',headers:{'Content-Type':'application/json'},body:JSON.stringify({is_read:true})})));
    }
    state.notifications=state.notifications.map(n=>({...n,is_read:true}));render();note('Notifications marked as read.');
  });

  function signOut(){localStorage.removeItem('cc_session');location.href='portal.html';}
  document.querySelector('#logout').addEventListener('click',signOut);
  document.querySelector('#logoutTop').addEventListener('click',signOut);
  document.querySelectorAll('[data-local-remove]').forEach(btn=>btn.addEventListener('click',()=>{btn.closest('.items>div')?.remove();note('Removed from wishlist.');}));

  // local settings
  ['prefEmail','prefMarket','prefSkills'].forEach(id=>document.querySelector('#'+id).addEventListener('change',()=>{
    localStorage.setItem('cc_settings',JSON.stringify({email:document.querySelector('#prefEmail').checked,market:document.querySelector('#prefMarket').checked,skills:document.querySelector('#prefSkills').checked}));
    note('Preference saved.');
  }));

  const observer=new IntersectionObserver(entries=>entries.forEach(e=>{if(e.isIntersecting)e.target.classList.add('visible')}),{threshold:.12});
  document.querySelectorAll('.reveal').forEach(el=>observer.observe(el));
  load();
})();
