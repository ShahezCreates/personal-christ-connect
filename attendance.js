
(async()=>{
 const auth=await window.CC_AUTH_READY;if(!auth?.session)return;
 const rows=await CC_DB.rest('attendance_records?select=course_code,course_name,sessions_held,sessions_attended,updated_at&order=course_name');
 let selected=rows?.[0]||null;
 const pct=(a,h)=>h?Math.round(a/h*1000)/10:0;
 const esc=CC_DB.esc;
 function calcs(r,target,attend,miss){
   const a=Number(r.sessions_attended||0),h=Number(r.sessions_held||0);
   const cur=pct(a,h), aa=pct(a+attend,h+attend), mm=pct(a,h+miss);
   const safe=Math.max(0,Math.floor(a*100/target-h+1e-9));
   const need=cur<target?Math.max(0,Math.ceil((target*h-100*a)/(100-target)-1e-9)):0;
   return {cur,aa,mm,safe,need};
 }
 document.body.innerHTML=`
 <header class="att-head"><a class="brand" href="dashboard.html"><span>C</span> CHRIST CONNECT</a><div><a href="dashboard.html">← My space</a><a href="profile.html">Profile</a></div></header>
 <main class="att-shell"><section class="att-hero"><div><p class="eyebrow">DELHI NCR · PRIVATE ACADEMICS</p><h1>Attendance, <em>decoded.</em></h1><p>Live subject records from your student profile, with a calculator for future attendance decisions.</p></div><div class="target"><span>Target</span><input id="target" type="number" min="1" max="99" value="75"><b>%</b></div></section>
 <section class="subject-grid" id="subjects"></section>
 <section class="planner" id="planner"><div><p class="eyebrow">WHAT-IF PLANNER</p><h2 id="selTitle">Select a subject</h2><p id="selSummary"></p></div>
 <div class="planner-inputs"><label>Attend next <input id="attend" type="number" min="0" value="1"> classes</label><label>Miss next <input id="miss" type="number" min="0" value="1"> classes</label></div>
 <div class="planner-results"><div><span>Current</span><b id="cur">—</b></div><div><span>After attending</span><b id="aa">—</b><small id="aad">—</small></div><div><span>After missing</span><b id="mm">—</b><small id="mmd">—</small></div><div><span>Can miss & stay at target</span><b id="safe">—</b><small>classes</small></div><div><span>Needed to reach target</span><b id="need">—</b><small>classes</small></div></div></section></main>`;
 function renderSubjects(){document.querySelector('#subjects').innerHTML=rows.length?rows.map((r,i)=>{const p=pct(r.sessions_attended,r.sessions_held);return `<button class="subject ${selected===r?'selected':''}" data-i="${i}"><span>${esc(r.course_code)}</span><h3>${esc(r.course_name)}</h3><b>${p.toFixed(1)}%</b><div class="bar"><i style="width:${Math.min(100,p)}%"></i></div><small>${r.sessions_attended}/${r.sessions_held} attended</small></button>`}).join(''):'<div class="empty"><h2>No attendance records.</h2><p>Ask an administrator to provision your subjects.</p></div>';document.querySelectorAll('.subject').forEach(b=>b.onclick=()=>{selected=rows[Number(b.dataset.i)];renderSubjects();renderPlanner()})}
 function renderPlanner(){if(!selected)return;const target=Number(document.querySelector('#target').value)||75,at=Number(document.querySelector('#attend').value)||0,mi=Number(document.querySelector('#miss').value)||0,c=calcs(selected,target,at,mi);document.querySelector('#selTitle').textContent=selected.course_name;document.querySelector('#selSummary').textContent=`${selected.sessions_attended}/${selected.sessions_held} classes attended · current ${c.cur.toFixed(1)}%`;document.querySelector('#cur').textContent=`${c.cur.toFixed(1)}%`;document.querySelector('#aa').textContent=`${c.aa.toFixed(1)}%`;document.querySelector('#mm').textContent=`${c.mm.toFixed(1)}%`;document.querySelector('#aad').textContent=`${c.aa-c.cur>=0?'+':''}${(c.aa-c.cur).toFixed(1)} pts`;document.querySelector('#mmd').textContent=`${c.mm-c.cur>=0?'+':''}${(c.mm-c.cur).toFixed(1)} pts`;document.querySelector('#safe').textContent=c.safe;document.querySelector('#need').textContent=c.need}
 renderSubjects();renderPlanner();document.querySelector('#target').oninput=renderPlanner;document.querySelector('#attend').oninput=renderPlanner;document.querySelector('#miss').oninput=renderPlanner;
})();
