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
    let tx=0,ty=0;addEventListener('pointermove',e=>{tx=(e.clientX/innerWidth-.5)*.35;ty=(e.clientY/innerHeight-.5)*.25},{passive:true});
    let t=0;(function animate(){t+=.005;group.rotation.y+=(tx-group.rotation.y)*.025;group.rotation.x+=(ty-group.rotation.x)*.02;group.position.y=Math.sin(t)*.08;renderer.render(scene,camera);requestAnimationFrame(animate)})();
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
