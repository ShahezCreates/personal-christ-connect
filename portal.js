const form = document.querySelector("#loginForm"),
  message = document.querySelector("#loginMessage");
form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const registrationNumber = form.registrationNumber.value.trim().toUpperCase(),
    password = form.password.value;
  if (!registrationNumber || !password) {
    message.textContent = "Enter both your registration number and password.";
    return;
  }
  message.textContent = "Authenticating…";
  try {
    const c = window.CHRIST_CONNECT_CONFIG;
    if (!c || c.SUPABASE_URL.includes("YOUR_PROJECT"))
      throw new Error("config");
   const r = await fetch(`${c.SUPABASE_URL}/functions/v1/login-with-registration`, {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        registrationNumber,
        password
    })
});

const raw = await r.text();

console.log("LOGIN HTTP STATUS:", r.status);
console.log("LOGIN RAW RESPONSE:", raw);

let data;

try {
    data = JSON.parse(raw);
} catch {
    data = { error: raw };
}

if (!r.ok) {
    throw new Error(
        `HTTP ${r.status}: ${data.error || data.message || raw || 'Unknown error'}`
    );
}
    localStorage.setItem("cc_session", JSON.stringify(data.session));
    window.location.href = "dashboard.html";
  } catch(err) {
    console.error("CHRIST CONNECT LOGIN ERROR:", err);

    message.textContent =
        "LOGIN DEBUG: " + (err?.message || String(err));

    console.error("Full error:", err);
}
});
