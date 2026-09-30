const progress=document.querySelector('.scroll-progress span');
const revealObserver=new IntersectionObserver(entries=>entries.forEach(entry=>{if(entry.isIntersecting){entry.target.classList.add('visible');revealObserver.unobserve(entry.target)}}),{threshold:.12});
document.querySelectorAll('.reveal').forEach(el=>revealObserver.observe(el));
const links=[...document.querySelectorAll('.sidebar nav a')];
const sections=links.map(a=>document.querySelector(a.getAttribute('href'))).filter(Boolean);
const navObserver=new IntersectionObserver(entries=>entries.forEach(entry=>{if(entry.isIntersecting)links.forEach(link=>link.classList.toggle('active',link.getAttribute('href')==='#'+entry.target.id));}),{rootMargin:'-38% 0px -50%'});
sections.forEach(s=>navObserver.observe(s));
window.addEventListener('scroll',()=>{const max=document.documentElement.scrollHeight-innerHeight;progress.style.width=(max>0?(scrollY/max)*100:0)+'%';document.querySelectorAll('.parallax').forEach(el=>{const depth=Number(el.dataset.depth||6);const y=(scrollY-innerHeight*.2)/depth;el.style.transform=`translate3d(0,${Math.max(-24,Math.min(24,y))}px,0)`})},{passive:true});
document.querySelector('#mobileMenu')?.addEventListener('click',()=>document.querySelector('.sidebar')?.classList.toggle('open'));

function initThree(){
  const canvas=document.querySelector('#campus3d'); if(!canvas||matchMedia('(prefers-reduced-motion: reduce)').matches)return;
  const script=document.createElement('script');script.src='https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js';
  script.onload=()=>{
    if(!window.THREE)return;
    const scene=new THREE.Scene();
    const camera=new THREE.PerspectiveCamera(34,1,.1,100);camera.position.set(7,6,9);
    const renderer=new THREE.WebGLRenderer({canvas,alpha:true,antialias:true});renderer.setPixelRatio(Math.min(devicePixelRatio,2));
    const resize=()=>{const box=canvas.getBoundingClientRect();renderer.setSize(box.width,box.height,false);camera.aspect=box.width/box.height;camera.updateProjectionMatrix()};
    resize();addEventListener('resize',resize);
    scene.add(new THREE.AmbientLight(0xffffff,2.2));const light=new THREE.DirectionalLight(0xffffff,3);light.position.set(5,10,5);scene.add(light);
    const group=new THREE.Group();scene.add(group);
    const mat=(color)=>new THREE.MeshStandardMaterial({color,roughness:.78,metalness:.05});
    const ground=new THREE.Mesh(new THREE.CylinderGeometry(5.2,5.5,.35,48),mat(0xf3efe4));ground.position.y=-1;group.add(ground);
    const colors=[0x1b303d,0xe96447,0xcfe0ae,0xb8dfe4,0xe7d576];
    const coords=[[-2.7,1.2,-1.5,1.4],[-.8,2.6,-.6,1.8],[1.2,1.5,-.9,1.15],[2.5,2.2,.4,1.55],[-.1,1.1,1.8,.85],[-2.2,.8,1.7,.7],[2.2,.65,2.4,.65]];
    coords.forEach(([x,h,z,s],i)=>{const b=new THREE.Mesh(new THREE.BoxGeometry(s,h,s),mat(colors[i%colors.length]));b.position.set(x,h/2-0.8,z);b.rotation.y=(i*.3);group.add(b);});
    for(let i=0;i<18;i++){const tree=new THREE.Mesh(new THREE.ConeGeometry(.18,.6,10),mat(0x6f8e6a));tree.position.set(Math.sin(i*1.7)*4.2,.1,Math.cos(i*1.4)*4.2);group.add(tree)}
    const ring=new THREE.Mesh(new THREE.TorusGeometry(3.6,.035,8,96),new THREE.MeshBasicMaterial({color:0xe96447,transparent:true,opacity:.55}));ring.rotation.x=Math.PI/2;ring.position.y=-.72;group.add(ring);
    // Cursor-tracking: the whole campus turns toward the pointer, a glowing beacon + spotlight follow it, and the tallest tower leans toward it.
    const beacon=new THREE.Mesh(new THREE.SphereGeometry(.16,24,24),new THREE.MeshBasicMaterial({color:0xe96447}));scene.add(beacon);
    const halo=new THREE.Mesh(new THREE.RingGeometry(.3,.38,48),new THREE.MeshBasicMaterial({color:0xe96447,transparent:true,opacity:.5,side:THREE.DoubleSide}));halo.rotation.x=-Math.PI/2;scene.add(halo);
    const spot=new THREE.PointLight(0xe96447,18,9);scene.add(spot);
    const tower=group.children[2]; const tower0=tower.rotation.y;
    let nx=0,ny=0,px=0,py=0,cx=0,cy=0;
    addEventListener('pointermove',e=>{nx=(e.clientX/innerWidth-.5)*2;ny=(e.clientY/innerHeight-.5)*2},{passive:true});
    // custom cursor ring (desktop only)
    if(matchMedia('(pointer:fine)').matches){const c=document.createElement('div');c.style.cssText='position:fixed;left:0;top:0;width:34px;height:34px;margin:-17px 0 0 -17px;border:1.5px solid #e96447;border-radius:50%;pointer-events:none;z-index:999;transition:width .2s,height .2s,margin .2s,background .2s';document.body.appendChild(c);
      addEventListener('pointermove',e=>{c.style.transform=`translate(${e.clientX}px,${e.clientY}px)`});
      document.querySelectorAll('a,button').forEach(el=>{el.addEventListener('pointerenter',()=>{c.style.width=c.style.height='54px';c.style.margin='-27px 0 0 -27px';c.style.background='#e9644718'});el.addEventListener('pointerleave',()=>{c.style.width=c.style.height='34px';c.style.margin='-17px 0 0 -17px';c.style.background='none'})});}
    let t=0;(function animate(){t+=.008;px+=(nx-px)*.06;py+=(ny-py)*.06;
      group.rotation.y+=((px*.7)-group.rotation.y)*.06; group.rotation.x+=((py*.3)-group.rotation.x)*.06;
      camera.position.x=7+px*1.2;camera.position.y=6-py*.9;camera.lookAt(0,.3,0);
      const gx=px*3.6,gz=py*3.6; beacon.position.set(gx,-.45+Math.sin(t*4)*.08,gz);halo.position.set(gx,-.7,gz);halo.scale.setScalar(1+Math.sin(t*4)*.15);spot.position.set(gx,1.2,gz);
      tower.rotation.z+=((-px*.12)-tower.rotation.z)*.08; tower.rotation.x+=((py*.12)-tower.rotation.x)*.08;
      group.position.y=Math.sin(t)*.08;renderer.render(scene,camera);requestAnimationFrame(animate)})();
  };document.head.appendChild(script);
}
initThree();


window.CC_AUTH_READY?.then(({session})=>{
  document.querySelectorAll('[data-auth-link="dashboard"]').forEach(link=>{
    if(session){ link.href='dashboard.html'; link.innerHTML='My student space <span>→</span>'; }
  });
  document.querySelectorAll('[data-auth-only]').forEach(el=>el.hidden=!session);
}).catch(()=>{});

// Richer scroll choreography for sections that are intentionally story-like.
const storySections=[...document.querySelectorAll('.story-panel,.scrolly-chapter,.image-story,.club-story,.campus-pulse,.dining-preview')];
const storyObs=new IntersectionObserver(entries=>entries.forEach(entry=>{
  entry.target.classList.toggle('story-active', entry.isIntersecting);
}),{threshold:.18});
storySections.forEach(s=>storyObs.observe(s));
