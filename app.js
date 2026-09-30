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
    scene.add(new THREE.AmbientLight(0xffffff,1.1));const key=new THREE.DirectionalLight(0xffffff,2.2);key.position.set(6,10,4);scene.add(key);
    // Architectural massing model: translucent glass volumes, crisp navy edges, floor-slab lines, blueprint ground.
    const group=new THREE.Group();scene.add(group);
    const NAVY=0x1b303d,CORAL=0xe96447;
    const grid=new THREE.GridHelper(12,24,0xbcc8c1,0xd9dfd8);grid.position.y=-.01;group.add(grid);
    const plaza=new THREE.Mesh(new THREE.RingGeometry(1.5,1.56,96),new THREE.MeshBasicMaterial({color:CORAL,side:THREE.DoubleSide}));plaza.rotation.x=-Math.PI/2;plaza.position.y=.01;group.add(plaza);
    const blocks=[];
    // [x,z,w,d,floors,name]
    [[-2.6,-1.2,2.6,1.5,5],[0,-3,3.4,1.3,4],[2.7,-.6,1.6,3,6],[-2.4,2.2,2,1.4,3],[1.2,2.6,2.6,1.2,2],[0,0,1,1,9]].forEach(([x,z,w,d,f],i)=>{
      const fh=.42,h=f*fh,bld=new THREE.Group();bld.position.set(x,0,z);
      const glass=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),new THREE.MeshStandardMaterial({color:i==5?0xe8f1f4:0xa9c8d2,transparent:true,opacity:i==5?.55:.38,roughness:.15,metalness:.4,emissive:CORAL,emissiveIntensity:0}));glass.position.y=h/2;bld.add(glass);
      bld.add(Object.assign(new THREE.LineSegments(new THREE.EdgesGeometry(glass.geometry),new THREE.LineBasicMaterial({color:NAVY})),{position:glass.position}));
      for(let k=1;k<f;k++){const sl=new THREE.Mesh(new THREE.BoxGeometry(w+.06,.03,d+.06),new THREE.MeshBasicMaterial({color:NAVY,transparent:true,opacity:.55}));sl.position.y=k*fh;bld.add(sl)}
      const roof=new THREE.Mesh(new THREE.BoxGeometry(w+.1,.05,d+.1),new THREE.MeshStandardMaterial({color:NAVY}));roof.position.y=h+.02;bld.add(roof);
      bld.userData={glass,wx:x,wz:z};blocks.push(bld);group.add(bld)});
    const dust=new THREE.BufferGeometry();dust.setAttribute('position',new THREE.BufferAttribute(new Float32Array(Array.from({length:240},(_,i)=>(Math.sin(i*12.9)*5)).map((v,i)=>i%3==1?Math.abs(v)*.9+.3:v)),3));
    group.add(new THREE.Points(dust,new THREE.PointsMaterial({color:CORAL,size:.04,transparent:true,opacity:.7})));
    const target=new THREE.Mesh(new THREE.RingGeometry(.28,.34,48),new THREE.MeshBasicMaterial({color:CORAL,side:THREE.DoubleSide}));target.rotation.x=-Math.PI/2;target.position.y=.03;group.add(target);
    const spot=new THREE.PointLight(CORAL,10,6);scene.add(spot);
    let nx=0,ny=0,px=0,py=0;
    addEventListener('pointermove',e=>{nx=(e.clientX/innerWidth-.5)*2;ny=(e.clientY/innerHeight-.5)*2},{passive:true});
    if(matchMedia('(pointer:fine)').matches){const c=document.createElement('div');c.style.cssText='position:fixed;left:0;top:0;width:34px;height:34px;margin:-17px 0 0 -17px;border:1.5px solid #e96447;border-radius:50%;pointer-events:none;z-index:999;transition:width .2s,height .2s,margin .2s,background .2s';document.body.appendChild(c);
      addEventListener('pointermove',e=>{c.style.transform=`translate(${e.clientX}px,${e.clientY}px)`});
      document.querySelectorAll('a,button').forEach(el=>{el.addEventListener('pointerenter',()=>{c.style.width=c.style.height='54px';c.style.margin='-27px 0 0 -27px';c.style.background='#e9644718'});el.addEventListener('pointerleave',()=>{c.style.width=c.style.height='34px';c.style.margin='-17px 0 0 -17px';c.style.background='none'})});}
    let t=0;(function animate(){t+=.01;px+=(nx-px)*.06;py+=(ny-py)*.06;
      group.rotation.y=-.6+px*.55;group.rotation.x=py*.12;camera.position.set(7,6.2-py*.8,9);camera.lookAt(0,1,0);
      const gx=px*3.5,gz=py*3.5;target.position.x=gx;target.position.z=gz;target.scale.setScalar(1+Math.sin(t*5)*.12);spot.position.set(gx,1.4,gz);
      blocks.forEach(b=>{const d=Math.hypot(b.userData.wx-gx,b.userData.wz-gz),near=Math.max(0,1-d/2.4);b.position.y+=(near*.18-b.position.y)*.1;b.userData.glass.material.emissiveIntensity+=(near*.35-b.userData.glass.material.emissiveIntensity)*.1});
      renderer.render(scene,camera);requestAnimationFrame(animate)})();
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
