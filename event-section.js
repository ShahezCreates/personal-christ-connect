
(async () => {
  const auth = await window.CC_AUTH_READY;
  if (!auth?.session) return;
  const key = document.body.dataset.eventPage || 'events';
  const cfg = window.CHRIST_CONNECT_CONFIG;
  const esc = window.CC_DB?.esc || (v => String(v ?? ''));
  const api = async (path, opts={}) => window.CC_DB ? CC_DB.rest(path, opts) : null;
  const titleMap = {
    events:'Campus <em>events.</em>', today:'Today on <em>campus.</em>', week:'This <em>week.</em>',
    upcoming:'Upcoming <em>events.</em>', workshops:'Workshops <em>& learning.</em>',
    hackathons:'Hackathons <em>& building.</em>', competitions:'Competitions <em>& fests.</em>',
    lectures:'Guest <em>lectures.</em>', fests:'Cultural <em>life.</em>',
    sports:'Sports <em>& games.</em>', department:'Department <em>events.</em>',
    club:'Club <em>events.</em>', registration:'Event <em>registration.</em>',
    countdown:'Event <em>countdown.</em>', calendar:'Campus <em>calendar.</em>'
  };

  const classify = e => {
    const text = `${e.title} ${e.description || ''}`.toLowerCase();
    if (/hack|startup|ai|code|tech|innovation/.test(text)) return 'hackathon';
    if (/workshop|masterclass|training|lab/.test(text)) return 'workshop';
    if (/sport|football|basketball|cricket|athletics/.test(text)) return 'sports';
    if (/festival|fest|cultur|music|dance|theatre|cinema/.test(text)) return 'cultural';
    if (/lecture|seminar|conference|research|paper|symposium/.test(text)) return 'academic';
    if (/club|society/.test(text)) return 'club';
    if (/department|school/.test(text)) return 'department';
    return 'campus';
  };

  const now = new Date();
  let events = [];
  try {
    events = await api('events?select=id,title,description,starts_at,ends_at,location,capacity,published&published=eq.true&order=starts_at.asc&limit=100') || [];
  } catch (e) {
    console.error(e);
  }

  const inDays = (d, days) => (new Date(d) - now) <= days * 86400000;
  let list = events.filter(e => new Date(e.starts_at) >= now);

  if (key === 'today') list = list.filter(e => new Date(e.starts_at).toDateString() === now.toDateString());
  if (key === 'week') list = list.filter(e => inDays(e.starts_at, 7));
  if (key === 'upcoming') list = list;
  if (key === 'workshops') list = list.filter(e => classify(e) === 'workshop');
  if (key === 'hackathons') list = list.filter(e => classify(e) === 'hackathon');
  if (key === 'competitions') list = list.filter(e => /competition|contest|challenge|fest/i.test(`${e.title} ${e.description || ''}`));
  if (key === 'lectures') list = list.filter(e => classify(e) === 'academic');
  if (key === 'fests') list = list.filter(e => classify(e) === 'cultural');
  if (key === 'sports') list = list.filter(e => classify(e) === 'sports');
  if (key === 'department') list = list.filter(e => classify(e) === 'department');
  if (key === 'club') list = list.filter(e => classify(e) === 'club');

  const html = `
    <header class="cc-live-header">
      <a class="brand" href="index.html"><span>C</span> CHRIST CONNECT</a>
      <div>
        <a href="dashboard.html">← My space</a>
        <a href="calendar-view.html">Calendar</a>
      </div>
    </header>
    <main class="cc-live-shell">
      <section class="cc-live-hero">
        <div>
          <p class="eyebrow">DELHI NCR CAMPUS · LIVE DATA</p>
          <h1>${titleMap[key] || titleMap.events}</h1>
          <p>These event cards are loaded from the Christ Connect PostgreSQL database for your authenticated student session.</p>
        </div>
        <a class="cc-live-pill" href="https://ncr.christuniversity.in/" target="_blank" rel="noopener">Official campus site ↗</a>
      </section>
      <section class="cc-event-list">
        ${list.length ? list.map((e,i) => `
          <article class="cc-event-row">
            <div class="num">${String(i+1).padStart(2,'0')}</div>
            <div class="event-main">
              <small>${classify(e).toUpperCase()} · ${new Date(e.starts_at).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</small>
              <h2>${esc(e.title)}</h2>
              <p>${esc(e.description || 'Campus event') }</p>
              <div class="meta"><span>⌖ ${esc(e.location || 'Delhi NCR Campus')}</span><span>◷ ${new Date(e.starts_at).toLocaleTimeString('en-IN',{hour:'numeric',minute:'2-digit'})}</span></div>
            </div>
            <button class="cc-event-save" data-event="${e.id}">Save to my events</button>
          </article>
        `).join('') : `<div class="cc-empty"><h2>No matching events yet.</h2><p>When published Delhi NCR events are added to the database, this page updates automatically.</p></div>`}
      </section>
    </main>
    <div class="cc-toast" id="ccToast"></div>`;
  document.body.innerHTML = html;

  const toast = document.querySelector('#ccToast');
  document.querySelectorAll('[data-event]').forEach(btn => {
    btn.addEventListener('click', async () => {
      try {
        const eventId = btn.dataset.event;
        const existing = await api(`event_registrations?select=event_id&event_id=eq.${encodeURIComponent(eventId)}&limit=1`);
        if (existing?.length) {
          await api(`event_registrations?event_id=eq.${encodeURIComponent(eventId)}&student_id=eq.${encodeURIComponent(auth.session.user.id)}`,{method:'DELETE'});
          btn.textContent = 'Removed';
        } else {
          await api('event_registrations',{method:'POST',headers:{'Content-Type':'application/json','Prefer':'return=minimal'},body:JSON.stringify({student_id:auth.session.user.id,event_id:eventId})});
          btn.textContent = 'Saved ✓';
        }
        toast.textContent = btn.textContent === 'Saved ✓' ? 'Added to your events.' : 'Removed from your events.';
        toast.classList.add('show'); setTimeout(()=>toast.classList.remove('show'),1800);
      } catch(e) {
        toast.textContent = e.message || 'Could not update event.';
        toast.classList.add('show'); setTimeout(()=>toast.classList.remove('show'),2200);
      }
    });
  });
})();
