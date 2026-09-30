# Christ Connect V5 setup

## 1. Keep your existing working configuration
`config.js` already contains the same Supabase project URL + publishable key used by the working login.

## 2. Database migration
In Supabase SQL Editor, run:

`supabase/v5_migration.sql`

This migration is idempotent and adds the profile fields, skills/interests/preferences, ten Delhi NCR dining outlets with distinct prototype menus, prepaid order fields, two-minute server-enforced cancellation, Lost & Found tables/claims/notifications, and current public Delhi NCR university body records.

## 3. Existing authentication
The already-deployed `login-with-registration` and `provision-student` functions are intentionally preserved. Do not place service-role/secret keys in frontend code.

## 4. Run locally

```powershell
python -m http.server 5500
```

Open:

`http://127.0.0.1:5500/`

## 5. Demo student

Registration: `DEMO2026BCA001`
Password: `DemoPass!2026`

## 6. Production payment
The preorder contract is prepaid and stores payment metadata. In this prototype, the payment provider is `demo` so no real money is moved. A real launch must connect a server-verified payment provider and only call the paid-order RPC after verified payment.
