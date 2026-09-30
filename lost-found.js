
(async()=>{
 const auth=await window.CC_AUTH_READY;if(!auth?.session)return;
 const esc=CC_DB.esc,rest=CC_DB.rest,studentId=auth.session.user.id;
 let rows=[];
 const qs=(v)=>encodeURIComponent(v);
 async function load(){
   rows=await rest('lost_found_items?select=id,type,title,description,category,location,item_date,status,created_at,student_id&status=eq.open&order=created_at.desc&limit=100');
   render(rows);
 }
 function render(data){
   document.querySelector('#results').innerHTML=data.length?data.map(x=>`
    <article class="lf-card"><div class="lf-badge ${x.type==='lost'?'lost':'found'}">${x.type.toUpperCase()}</div>
      <div><small>${esc(x.category||'Other')} · ${esc(x.location||'Campus')}</small><h3>${esc(x.title)}</h3>
      <p>${esc(x.description||'No description provided.')}</p><span>${x.item_date?new Date(x.item_date).toLocaleDateString('en-IN'):'Date not given'}</span>
      </div>
      ${x.student_id===studentId?'<button class="lf-own" disabled>Your report</button>':`<button data-claim="${x.id}">I may have this →</button>`}
    </article>`).join(''):'<div class="lf-empty"><h2>No open reports.</h2><p>The database is clear right now.</p></div>';
   document.querySelectorAll('[data-claim]').forEach(b=>b.onclick=async()=>{
     const id=b.dataset.claim;
     const note=prompt('Add a short message for the reporter:');
     if(!note?.trim())return;
     try{await rest('lost_found_claims',{method:'POST',headers:{'Content-Type':'application/json','Prefer':'return=minimal'},body:JSON.stringify({item_id:id,claimer_id:studentId,message:note.trim()})});b.textContent='Claim sent ✓';b.disabled=true;flash('Claim sent to the reporter.');}
     catch(e){flash(e.message||'Could not send claim.');}
   });
 }
 function flash(t){const el=document.querySelector('#toast');el.textContent=t;el.classList.add('show');setTimeout(()=>el.classList.remove('show'),2200)}
 document.body.innerHTML=`
 <header class="lf-head"><a class="brand" href="dashboard.html"><span>C</span> CHRIST CONNECT</a><div><a href="dashboard.html">← My space</a><a href="canteen.html">Canteen</a></div></header>
 <main class="lf-shell"><section class="lf-hero"><div><p class="eyebrow">DELHI NCR · CAMPUS HELP</p><h1>Lost & <em>found.</em></h1><p>A student-owned reporting layer for misplaced IDs, bottles, chargers, devices, books and more. Reports live in Supabase and are scoped to authenticated campus users.</p></div></section>
 <section class="lf-layout"><article class="lf-report glass"><p class="eyebrow">REPORT AN ITEM</p><div class="lf-form">
 <select id="type"><option value="lost">I lost something</option><option value="found">I found something</option></select>
 <input id="title" maxlength="120" placeholder="What is it?">
 <select id="category"><option>ID / card</option><option>Electronics</option><option>Books</option><option>Bag</option><option>Clothing</option><option>Bottle</option><option>Keys</option><option>Other</option></select>
 <input id="location" maxlength="120" placeholder="Where on campus?">
 <input id="itemDate" type="date">
 <textarea id="description" maxlength="500" rows="5" placeholder="Describe colour, brand, markings, or other identifying details…"></textarea>
 <button id="reportBtn">Publish report →</button><small id="reportMsg"></small></div></article>
 <article class="lf-browse"><div class="lf-toolbar"><div><p class="eyebrow">OPEN REPORTS</p><h2>Search the <em>campus.</em></h2></div><input id="search" placeholder="Search item, place, category…"></div><div id="results"></div></article></section></main><div class="cc-toast" id="toast"></div>`;
 document.querySelector('#itemDate').value=new Date().toISOString().slice(0,10);
 document.querySelector('#itemDate').max=document.querySelector('#itemDate').value;
 document.querySelector('#reportBtn').onclick=async()=>{
   const body={student_id:studentId,type:document.querySelector('#type').value,title:document.querySelector('#title').value.trim(),description:document.querySelector('#description').value.trim(),category:document.querySelector('#category').value,location:document.querySelector('#location').value.trim()||null,item_date:document.querySelector('#itemDate').value||null};
   if(!body.title){document.querySelector('#reportMsg').textContent='Add a title.';return;}
   try{await rest('lost_found_items',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});document.querySelector('#reportMsg').textContent='Report published.';['title','description','location'].forEach(id=>document.querySelector('#'+id).value='');await load();flash('Lost & Found report published.');}
   catch(e){document.querySelector('#reportMsg').textContent=e.message||'Could not publish.';}
 };
 document.querySelector('#search').oninput=(e)=>{const q=e.target.value.toLowerCase();render(rows.filter(r=>`${r.title} ${r.description} ${r.category} ${r.location}`.toLowerCase().includes(q)))};
 await load();
})();
