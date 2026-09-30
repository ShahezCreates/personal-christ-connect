(async()=>{
  const auth=await window.CC_AUTH_READY; if(!auth.session){location.href='portal.html';return;}
  const section=document.body.dataset.section;
  const orgs=(window.CHRIST_NCR_DATA?.organisations||[]);
  const schools=(window.CHRIST_NCR_DATA?.schools||[]);
  const content={
    details:['Basic <em>details.</em>','<div class="form"><label>Full name<input id="fullName"></label><label>University email<input id="email"></label><label>Phone number<input id="phone"></label><label>Campus<input value="Delhi NCR · Mariam Nagar" disabled></label><label class="wide">About me<textarea id="bio"></textarea></label></div>'],
    department:['My <em>department.</em>',`<div class="grid">${schools.map(([name,code])=>`<div class="item"><span class="icon">${code.slice(0,1)}</span><p><b>${name}</b><small>Delhi NCR Campus · ${code}</small></p></div>`).join('')}</div>`],
    year:['My <em>year.</em>','<div class="grid"><div class="item"><span class="icon">1</span><p><b>Your year</b><small>Loaded from your student profile.</small></p></div><div class="item"><span class="icon">#</span><p><b>Your registration number</b><small>Private student data.</small></p></div></div>'],
    skills:['My <em>skills.</em>','<div class="tags"><span>Skills are now managed from your profile.</span></div>'],
    interests:['My <em>interests.</em>','<div class="tags pink"><span>Interests are now managed from your profile.</span></div>'],
    clubs:['University <em>student bodies.</em>',`<div class="grid">${orgs.map(([code,name,kind,desc])=>`<div class="item"><span class="icon">${code.slice(0,1)}</span><p><b>${code} · ${name}</b><small>${kind} · ${desc}</small></p></div>`).join('')}</div>`],
    events:['Saved <em>events.</em>','<div class="empty">Open the live event pages to save campus events to your account.</div>'],
    orders:['Canteen <em>orders.</em>','<div class="empty"><strong>Pre-order from campus dining.</strong><a href="canteen.html">Open Delhi NCR canteen →</a></div>'],
    listings:['My <em>listings.</em>','<div class="empty">Your campus marketplace listings will live here.</div>'],
    lost:['My <em>lost items.</em>','<div class="empty">Use Lost & Found to report or search for an item.</div>'],
    found:['My <em>found items.</em>','<div class="empty">Use Lost & Found to report a found item.</div>'],
    wishlist:['My <em>wishlist.</em>','<div class="empty">Saved marketplace items will appear here.</div>'],
    notifications:['Notifications.','<div class="empty">Open Notifications Center for your live student alerts.</div>'],
    settings:['Settings.','<div class="settings"><p>Notification preferences are managed from your private profile.</p></div>']
  };
  const [title,body]=content[section]||content.details;
  document.body.innerHTML=`<header><a class="brand" href="profile.html"><span>C</span> CHRIST CONNECT</a><a href="profile.html">← Profile overview</a></header><main class="shell"><div class="head"><div><p class="eyebrow">DELHI NCR STUDENT SPACE</p><h1>${title}</h1></div><a class="link-btn" href="profile.html">Open profile</a></div><section class="card">${body}</section></main><div class="toast" id="toast"></div>`;
  const cfg=window.CHRIST_CONNECT_CONFIG;const student=(await fetch(`${cfg.SUPABASE_URL}/rest/v1/student_profiles?select=*&limit=1`,{headers:{apikey:cfg.SUPABASE_ANON_KEY,Authorization:`Bearer ${auth.session.access_token}`}}).then(r=>r.json()))[0];
  if(section==='details'&&student){document.querySelector('#fullName').value=student.full_name||'';document.querySelector('#email').value=student.university_email||'';document.querySelector('#phone').value=student.phone||'';document.querySelector('#bio').value=student.bio||'';}
})();
