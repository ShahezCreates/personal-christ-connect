(() => {
  const cfg = window.CHRIST_CONNECT_CONFIG;
  const PRIVATE = document.body?.dataset.private === 'true';
  const READY = (async () => {
    if (!cfg?.SUPABASE_URL || !cfg?.SUPABASE_ANON_KEY || cfg.SUPABASE_URL.includes('YOUR_PROJECT')) {
      throw new Error('Supabase configuration missing.');
    }
    if (!window.supabase) {
      await new Promise((resolve, reject) => {
        const s = document.createElement('script');
        s.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
        s.onload = resolve;
        s.onerror = () => reject(new Error('Supabase client failed to load.'));
        document.head.appendChild(s);
      });
    }
    const client = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: false,
        storageKey: 'christconnect-auth',
        flowType: 'pkce'
      }
    });

    // One-time migration from the first Christ Connect prototype.
    const legacy = localStorage.getItem('cc_session');
    if (legacy) {
      try {
        const session = JSON.parse(legacy);
        if (session?.access_token && session?.refresh_token) {
          await client.auth.setSession({
            access_token: session.access_token,
            refresh_token: session.refresh_token
          });
        }
      } catch (_) {}
      localStorage.removeItem('cc_session'); localStorage.setItem('cc_last_auth_restore', new Date().toISOString());
    }

    let { data: { session } } = await client.auth.getSession();
    window.CC_AUTH = { client, session };
    document.documentElement.dataset.auth = session ? 'signed-in' : 'signed-out';

    client.auth.onAuthStateChange((event, nextSession) => {
      window.CC_AUTH.session = nextSession;
      document.documentElement.dataset.auth = nextSession ? 'signed-in' : 'signed-out';
      if (!nextSession && PRIVATE && !location.pathname.endsWith('/portal.html')) {
        location.href = 'portal.html';
      }
      window.dispatchEvent(new CustomEvent('cc-auth-change', { detail: { event, session: nextSession } }));
    });

    if (PRIVATE && !session) {
      location.href = 'portal.html';
      return { client, session: null };
    }
    return { client, session };
  })();

  window.CC_AUTH_READY = READY;
  window.CC_REQUIRE_AUTH = () => READY.then(x => x.session);
})();
