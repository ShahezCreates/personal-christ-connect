
(async()=>{
 const auth=await window.CC_AUTH_READY;if(!auth?.session)return;
 const rest=CC_DB.rest,esc=CC_DB.esc,client=auth.client;
 const rows=await rest('canteen_orders?select=id,order_code,status,total,created_at,pickup_date,pickup_slot,cancel_until,payment_status,canteen_shops(name,location)&order=created_at.desc&limit=50');
 const fmt=d=>new Date(d).toLocaleString('en-IN',{dateStyle:'medium',timeStyle:'short'});
 document.body.innerHTML=`
 <header class="orders-head"><a class="brand" href="dashboard.html"><span>C</span> CHRIST CONNECT</a><div><a href="canteen.html">← Canteen</a><a href="profile.html">Profile</a></div></header>
 <main class="orders-shell"><section class="orders-hero"><p class="eyebrow">DELHI NCR · ACCOUNT ACTIVITY</p><h1>Your <em>orders.</em></h1><p>Every preorder is tied to your authenticated student profile. Receipts are generated from the database.</p></section>
 <section class="orders-grid">${rows?.length?rows.map(o=>`
 <article class="order-card"><div class="order-top"><span>${esc(o.order_code||'ORDER')}</span><b class="${o.status==='cancelled'?'muted':''}">${esc(o.status)}</b></div>
 <h2>${esc(o.canteen_shops?.name||'Campus dining')}</h2><p>${esc(o.canteen_shops?.location||'Delhi NCR campus')}</p>
 <div class="order-meta"><span>Placed<br><b>${fmt(o.created_at)}</b></span><span>Pickup<br><b>${esc(o.pickup_date)} · ${esc(o.pickup_slot)}</b></span><span>Total<br><b>₹${Number(o.total||0).toFixed(0)}</b></span></div>
 <div class="order-actions"><button data-receipt="${o.id}">View e-receipt</button>${o.status==='placed'?`<button class="cancel" data-cancel="${o.id}" ${new Date(o.cancel_until)<=new Date()?'disabled':''}>Cancel</button>`:''}</div></article>`).join(''):'<div class="empty"><h2>No orders yet.</h2><a href="canteen.html">Open campus dining →</a></div>'}</section></main><div class="cc-toast" id="toast"></div>`;
 function toast(t){const el=document.querySelector('#toast');el.textContent=t;el.classList.add('show');setTimeout(()=>el.classList.remove('show'),2200)}
 document.querySelectorAll('[data-receipt]').forEach(b=>b.onclick=async()=>{
   try{const {data,error}=await client.rpc('get_order_receipt',{p_order_id:b.dataset.receipt});if(error)throw error;
     const r=data;const items=(r.items||[]).map(i=>`<div class="receipt-row"><span>${i.qty} × ${esc(i.name)}</span><b>₹${Number(i.line_total).toFixed(0)}</b></div>`).join('');
     const modal=document.createElement('div');modal.className='receipt-modal';modal.innerHTML=`<div class="receipt"><button class="x">×</button><p class="eyebrow">E-RECEIPT · ${esc(r.payment_status||'paid')}</p><h2>${esc(r.order_code)}</h2><p><b>${esc(r.student_name)}</b><br>${esc(r.registration_number)}</p><p>${esc(r.outlet)} · ${esc(r.location||'')}<br>${esc(r.pickup_date)} · ${esc(r.pickup_slot)}</p><hr>${items}<hr><div class="receipt-total"><span>Total paid</span><b>₹${Number(r.total||0).toFixed(0)}</b></div></div>`;document.body.appendChild(modal);modal.onclick=e=>{if(e.target===modal)modal.remove()};modal.querySelector('.x').onclick=()=>modal.remove();}
   catch(e){toast(e.message||'Could not load receipt.')}
 });
 document.querySelectorAll('[data-cancel]').forEach(b=>b.onclick=async()=>{
   try{const {error}=await client.rpc('cancel_canteen_order',{p_order_id:b.dataset.cancel});if(error)throw error;toast('Order cancelled and refunded.');setTimeout(()=>location.reload(),800);}catch(e){toast(e.message||'Cancellation window closed.')}
 });
})();
