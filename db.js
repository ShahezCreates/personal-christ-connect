
(() => {
  const cfg = window.CHRIST_CONNECT_CONFIG;
  if (!cfg?.SUPABASE_URL || !cfg?.SUPABASE_ANON_KEY) {
    console.warn("Christ Connect: Supabase config missing.");
    return;
  }

  const esc = (v) => String(v ?? '').replace(/[&<>'"]/g, c => ({
    '&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'
  }[c]));

  async function ready() {
    const auth = await window.CC_AUTH_READY;
    if (!auth?.session) throw new Error('Session expired. Please sign in again.');
    return auth;
  }

  async function rest(path, opts = {}) {
    const auth = await ready();
    const headers = {
      apikey: cfg.SUPABASE_ANON_KEY,
      Authorization: `Bearer ${auth.session.access_token}`,
      ...(opts.headers || {})
    };
    const res = await fetch(`${cfg.SUPABASE_URL}/rest/v1/${path}`, { ...opts, headers });
    const raw = await res.text();
    let data = null;
    try { data = raw ? JSON.parse(raw) : null; } catch (_) { data = raw; }
    if (!res.ok) {
      const message = typeof data === 'object' && data?.message ? data.message :
                      typeof data === 'object' && data?.error ? data.error :
                      raw || `Request failed (${res.status})`;
      throw new Error(message);
    }
    return data;
  }

  async function rpc(fn, args = {}) {
    const auth = await ready();
    const { data, error } = await auth.client.rpc(fn, args);
    if (error) throw error;
    return data;
  }

  async function student() {
    const rows = await rest('student_profiles?select=*&limit=1');
    return rows?.[0] || null;
  }

  window.CC_DB = { cfg, esc, ready, rest, rpc, student };
})();
