(function(){
  const orb=document.querySelector('.cursor-orb')||document.createElement('div'); if(!orb.parentNode){orb.className='cursor-orb';document.body.appendChild(orb)}
  document.addEventListener('pointermove',e=>{orb.style.transform=`translate(${e.clientX}px,${e.clientY}px)`},{passive:true});
  const reveal=()=>document.querySelectorAll('.reveal').forEach((el,i)=>{const r=el.getBoundingClientRect();if(r.top<innerHeight*.9&&r.bottom>0){el.classList.add('in');el.style.transitionDelay=`${Math.min(i%5,4)*60}ms`}});
  addEventListener('scroll',reveal,{passive:true}); addEventListener('load',reveal);
  document.querySelectorAll('.tilt').forEach(el=>{
    el.addEventListener('pointermove',e=>{const r=el.getBoundingClientRect();const nx=(e.clientX-r.left)/r.width-.5,ny=(e.clientY-r.top)/r.height-.5;el.style.transform=`perspective(1100px) rotateX(${(-ny*4).toFixed(2)}deg) rotateY(${(nx*6).toFixed(2)}deg) translateY(-3px)`});
    el.addEventListener('pointerleave',()=>el.style.transform='');
  });
  const bar=document.querySelector('.scroll-progress span'); if(bar)addEventListener('scroll',()=>{const h=document.documentElement.scrollHeight-innerHeight;bar.style.width=`${h?Math.min(100,scrollY/h*100):0}%`},{passive:true});
})();
