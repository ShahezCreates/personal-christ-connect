const form = document.querySelector('#loginForm');
const message = document.querySelector('#loginMessage');

form.addEventListener('submit', async event => {
  event.preventDefault();
  const registrationNumber = form.registrationNumber.value.trim().toUpperCase();
  const password = form.password.value;
  if (!registrationNumber || !password) {
    message.textContent = 'Enter both your registration number and password.';
    return;
  }
  message.textContent = 'Checking secure student access…';
  try {
    const response = await fetch('/api/auth/login', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      credentials: 'include', body: JSON.stringify({ registrationNumber, password })
    });
    if (!response.ok) throw new Error('not-authorized');
    window.location.href = '/dashboard';
  } catch {
    message.textContent = 'The secure login service has not been connected yet. Student data is not available in this static prototype.';
  }
});
