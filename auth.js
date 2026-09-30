
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

    let { data: { session } } = await client.auth.getSession();

    window.CC_AUTH = { client, session, student: null };
    document.documentElement.dataset.auth = session ? 'signed-in' : 'signed-out';

    if (session) {
      try {
        const res = await fetch(
          `${cfg.SUPABASE_URL}/rest/v1/student_profiles?select=*&limit=1`,
          { headers: { apikey: cfg.SUPABASE_ANON_KEY, Authorization: `Bearer ${session.access_token}` } }
        );
        if (res.ok) {
          const rows = await res.json();
          window.CC_AUTH.student = rows?.[0] || null;
          if (window.CC_AUTH.student) {
            localStorage.setItem('cc_student_snapshot', JSON.stringify({
              id: window.CC_AUTH.student.id,
              registration_number: window.CC_AUTH.student.registration_number,
              full_name: window.CC_AUTH.student.full_name
            }));
          }
        }
      } catch (_) {}
    }

    client.auth.onAuthStateChange((event, nextSession) => {
      window.CC_AUTH.session = nextSession;
      document.documentElement.dataset.auth = nextSession ? 'signed-in' : 'signed-out';
      if (!nextSession) {
        window.CC_AUTH.student = null;
        localStorage.removeItem('cc_student_snapshot');
        if (PRIVATE && !location.pathname.endsWith('/portal.html')) {
          location.href = 'portal.html';
          return;
        }
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
