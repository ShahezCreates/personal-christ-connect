(function(){
  const cfg=window.CHRIST_CONNECT_CONFIG;
  window.CC_AUTH={
    client:null,
    async init(){
      if(this.client) return this.client;
      if(!cfg?.SUPABASE_URL || !cfg?.SUPABASE_ANON_KEY) return null;
      if(!window.supabase) return null;
      this.client=window.supabase.createClient(cfg.SUPABASE_URL,cfg.SUPABASE_ANON_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:false,storageKey:'christconnect-auth-v5'}});
      const raw=localStorage.getItem('cc_session');
      if(raw){try{const s=JSON.parse(raw);if(s?.access_token&&s?.refresh_token){await this.client.auth.setSession({access_token:s.access_token,refresh_token:s.refresh_token});}}catch(e){localStorage.removeItem('cc_session')}}
      return this.client;
    },
    async session(){const c=await this.init(); if(!c)return null; const {data}=await c.auth.getSession(); return data.session||null},
    async token(){const s=await this.session();return s?.access_token||null},
    async setSession(s){const c=await this.init();if(!c||!s?.access_token||!s?.refresh_token)return false;await c.auth.setSession(s);localStorage.setItem('cc_session',JSON.stringify(s));return true},
    async signOut(){const c=await this.init();if(c)await c.auth.signOut();localStorage.removeItem('cc_session');window.location.href='index.html'},
    async requireAuth(){const s=await this.session();if(!s){window.location.href='portal.html';return null}return s}
  };
  window.CC_READY=CC_AUTH.init();
})();
