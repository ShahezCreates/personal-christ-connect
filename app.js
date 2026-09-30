(() => {
  const root = document.documentElement;
  const progress = document.querySelector('.scroll-progress span');
  const revealNodes = [...document.querySelectorAll('.reveal')];
  const revealObserver = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        revealObserver.unobserve(entry.target);
      }
    });
  }, { threshold: .14 });
  revealNodes.forEach(node => revealObserver.observe(node));

  const navLinks = [...document.querySelectorAll('.sidebar nav a')];
  const sections = navLinks
    .map(link => document.querySelector(link.getAttribute('href')))
    .filter(Boolean);
  const navObserver = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      navLinks.forEach(link => link.classList.toggle('active', link.getAttribute('href') === `#${entry.target.id}`));
    });
  }, { rootMargin:'-30% 0px -58% 0px' });
  sections.forEach(section => navObserver.observe(section));

  const onScroll = () => {
    const max = Math.max(1, document.documentElement.scrollHeight - innerHeight);
    const pct = Math.max(0, Math.min(1, scrollY / max));
    if (progress) progress.style.height = `${pct * 100}%`;
    root.style.setProperty('--scroll-depth', pct.toFixed(3));
  };
  addEventListener('scroll', onScroll, { passive:true });
  onScroll();

  const parallaxNodes = [...document.querySelectorAll('[data-depth]')];
  if (!matchMedia('(prefers-reduced-motion: reduce)').matches && parallaxNodes.length) {
    addEventListener('pointermove', e => {
      const nx = e.clientX / innerWidth - .5;
      const ny = e.clientY / innerHeight - .5;
      parallaxNodes.forEach(el => {
        const depth = Number(el.dataset.depth) || 4;
        el.style.transform = `translate3d(${nx * depth}px, ${ny * depth}px, 0)`;
      });
    }, { passive:true });
  }

  const menu = document.querySelector('.mobile-menu');
  const sidebarNav = document.querySelector('.sidebar nav');
  menu?.addEventListener('click', () => sidebarNav?.classList.toggle('mobile-open'));
  sidebarNav?.addEventListener('click', e => {
    if (e.target.closest('a')) sidebarNav.classList.remove('mobile-open');
  });
})();
