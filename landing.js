(function(){
  const d=window.CC_CAMPUS;if(!d)return;
  const sg=document.querySelector('#schoolGrid'),bg=document.querySelector('#bodyGrid'),gg=document.querySelector('#groupStrip'),dr=document.querySelector('#diningRail');
  sg.innerHTML=d.schools.map((x,i)=>`<a class="school-card ${x[2]==='science'?'featured':''} reveal" href="department.html?school=${encodeURIComponent(x[0])}"><span>0${i+1}</span><div><small>${x[2].toUpperCase()}</small><h3>${x[0]}</h3><p>${x[1]}</p></div><b>→</b></a>`).join('');
  bg.innerHTML=d.bodies.map((x,i)=>`<article class="body-card reveal"><span>${String(i+1).padStart(2,'0')}</span><b>${x[0]}</b><h3>${x[1]}</h3><p>${x[2]}</p></article>`).join('');
  gg.innerHTML=d.groups.map(x=>`<span class="group-pill">${x[0]} <small>${x[1]}</small></span>`).join('');
  dr.innerHTML=d.dining.slice(0,8).map((x,i)=>`<a class="dining-card reveal tilt" href="canteen.html?outlet=${encodeURIComponent(x.name)}"><small>0${i+1} · ${x.tag}</small><h3>${x.name}</h3><p>${x.area}</p><span>Preorder →</span></a>`).join('');
  document.querySelectorAll('.tilt').forEach(el=>el.addEventListener('pointermove',e=>{const r=el.getBoundingClientRect(),x=(e.clientX-r.left)/r.width-.5,y=(e.clientY-r.top)/r.height-.5;el.style.transform=`perspective(900px) rotateX(${(-y*4).toFixed(2)}deg) rotateY(${(x*5).toFixed(2)}deg)`}),el=>el.addEventListener('pointerleave',()=>el.style.transform=''));
  const scene=document.querySelector('#scene3d');addEventListener('pointermove',e=>{if(!scene)return;const x=(e.clientX/innerWidth-.5),y=(e.clientY/innerHeight-.5);scene.style.setProperty('--mx',`${x*18}deg`);scene.style.setProperty('--my',`${y*-10}deg`)});addEventListener('scroll',()=>{document.documentElement.style.setProperty('--scrollY',`${scrollY*0.04}px`);const p=Math.min(1,scrollY/(document.body.scrollHeight-innerHeight));document.querySelector('.scroll-progress span').style.width=`${p*100}%`},{passive:true});
})();
