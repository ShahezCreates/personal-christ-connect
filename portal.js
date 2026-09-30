(async () => {
  const form = document.querySelector('#loginForm');
  const message = document.querySelector('#loginMessage');
  const auth = await window.CC_AUTH_READY;
  const client = auth.client;
  if (auth.session) {
    location.href = 'dashboard.html';
    return;
  }

  form.addEventListener('submit', async e => {
    e.preventDefault();
    const registrationNumber = form.registrationNumber.value.trim().toUpperCase();
    const password = form.password.value;
    if (!registrationNumber || !password) {
      message.textContent = 'Enter both your registration number and password.';
      return;
    }
    message.textContent = 'Authenticating…';
    try {
      const c = window.CHRIST_CONNECT_CONFIG;
      const r = await fetch(`${c.SUPABASE_URL}/functions/v1/login-with-registration`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${c.SUPABASE_ANON_KEY}`
        },
        body: JSON.stringify({ registrationNumber, password })
      });
      const raw = await r.text();
      let data = {};
      try { data = JSON.parse(raw); } catch (_) {}
      if (!r.ok) throw new Error(data.error || `Login failed (HTTP ${r.status})`);
      if (!data.session) throw new Error('Login succeeded but no session was returned.');

      // Hand the session to Supabase Auth so it persists and refreshes across visits/tabs.
      const { error: sessionError } = await client.auth.setSession({
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token
      });
      if (sessionError) throw sessionError;

      message.textContent = 'Signed in. Opening your space…';
      location.href = 'dashboard.html';
    } catch (err) {
      console.error('Christ Connect login error:', err);
      message.textContent = err.message || 'Unable to sign in right now.';
    }
  });
})();
