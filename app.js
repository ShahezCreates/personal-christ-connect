(function(){
  const PUBLIC=['index.html','portal.html','registration.html','christ-connect.html'];
  async function boot(){
    if(!window.CC_AUTH)return;
    const session=await CC_AUTH.session();
    document.querySelectorAll('[data-auth-link="dashboard"]').forEach(a=>{a.href=session?'dashboard.html':'portal.html';a.textContent=session?'My student space →':'Student login →'});
    document.querySelectorAll('[data-auth-only]').forEach(el=>{if(!session)el.hidden=true});
    document.querySelectorAll('[data-private-page]').forEach(async el=>{if(!session)window.location.href='portal.html'});
  }
  window.addEventListener('DOMContentLoaded',boot);
})();
