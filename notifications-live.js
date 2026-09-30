
(async()=>{
 const auth=await window.CC_AUTH_READY;if(!auth?.session)return;
 let rows=[];
 try{rows=await CC_DB.rest('notifications?select=id,title,body,is_read,created_at&order=created_at.desc&limit=50')}catch(e){console.error(e)}
 const esc=CC_DB.esc;
 document.body.innerHTML=`<header class="cc-live-header"><a class="brand" href="dashboard.html"><span>C</span> CHRIST CONNECT</a><div><a href="dashboard.html">← My space</a><a href="profile.html">Profile</a></div></header><main class="cc-live-shell"><section class="cc-live-hero"><p class="eyebrow">DELHI NCR · PRIVATE UPDATES</p><h1>Your <em>notifications.</em></h1><p>Live notifications tied to your authenticated student account.</p><button id="readAll" class="cc-live-pill" type="button">Mark all as read</button></section><section class="notice-stack">${rows.length?rows.map(n=>`<article class="notice-row ${n.is_read?'read':''}"><div class="notice-dot">${n.is_read?'◌':'✦'}</div><div><small>${new Date(n.created_at).toLocaleString('en-IN')}</small><h2>${esc(n.title)}</h2><p>${esc(n.body||'')}</p></div></article>`).join(''):'<div class="cc-empty"><h2>You’re all caught up.</h2></div>'}</section></main><div class="cc-toast" id="toast"></div>`;
 const toast=(t)=>{const x=document.querySelector('#toast');x.textContent=t;x.classList.add('show');setTimeout(()=>x.classList.remove('show'),1800)};
 document.querySelector('#readAll').onclick=async()=>{try{await CC_DB.rest(`notifications?student_id=eq.${encodeURIComponent(auth.session.user.id)}&is_read=eq.false`,{method:'PATCH',headers:{'Content-Type':'application/json'},body:JSON.stringify({is_read:true})});toast('All notifications marked as read.');setTimeout(()=>location.reload(),500)}catch(e){toast(e.message||'Could not update notifications.')}};
})();
