# Christ Connect · Delhi NCR Deluxe V2

A full static frontend + Supabase-backed private student portal based on the original Christ Connect build.

## What's included

- Restored original Christ Connect feature pages: events, workshops, hackathons, competitions, guest lectures, cultural fests, sports, department events, club events, calendar, countdown, skill exchange, marketplace, lost & found, community, campus guide, rewards, notifications, admin dashboard, profile/account surfaces, and all the original supporting pages.
- Redesigned public landing page with the original cream / dark-teal / coral / green / yellow palette, scroll storytelling, parallax, glassmorphism, neumorphism, responsive layouts, local SVG visuals, and an optional Three.js interactive campus scene.
- Supabase-backed registration-number login using Supabase Auth.
- Private student dashboard and profile that read authenticated data from Postgres using RLS.
- Subject-wise attendance dashboard and what-if calculator:
  - current percentage
  - percentage after attending N future classes
  - percentage after missing N future classes
  - percentage-point gain/loss
  - number of classes that can be missed while staying at target
  - number of classes needed to reach target
- Profile skills, interests and notification preferences stored in Postgres.

## Current Supabase setup

The existing login/provisioning functions from the working project are preserved under `supabase/functions/`.

For a project that already has the base schema, run `supabase/upgrade_v2.sql` once. It adds the attendance/profile enhancements and demo data for `DEMO2026BCA001` only.

For a new project, run `supabase/schema.sql`, then `supabase/upgrade_v2.sql`.

Do not put a service-role or secret key in `config.js`.

## Local testing

Open the folder in VS Code and run:

```powershell
python -m http.server 5500
```

Then open:

```text
http://127.0.0.1:5500/
```

Use a provisioned student account. The demo account created by the included admin workflow is:

```text
Registration: DEMO2026BCA001
Password: DemoPass!2026
```

These values are demo credentials, not official university credentials.

## Supabase functions

Deploy from the project root:

```powershell
supabase functions deploy login-with-registration
supabase functions deploy provision-student --no-verify-jwt
```

The provisioning function expects the `CHRIST_CONNECT_ADMIN_SECRET` secret. Supabase-provided `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` values are consumed server-side by the Edge Function and must not be copied into browser code.

## Note on official data

The project contains demo events, clubs and attendance values only. Replace them with legitimate university-provided data before treating any result as official.


## V3 additions
- Persistent Supabase Auth session across tabs/browser revisits.
- Delhi NCR dining pre-order flow: `canteen.html`.
- Run `supabase/upgrade_v3.sql` after the existing schema/upgrade.
- Delhi NCR-only organization/school directory data.
- Generic photography providers were removed from the active landing/login UI; active photography points to Delhi NCR campus gallery images.
- Existing Edge Functions are intentionally unchanged.

## V5 additions
- Run `supabase/upgrade_v4.sql` after v3. Adds prepaid wallet + ledger, server-enforced 2-minute cancel window with refund, registration-number-stamped e-receipts (`get_order_receipt`), admin-only top-up (`admin_topup_wallet`).
- `canteen.js`: wallet balance, live cancel countdown, on-site e-receipt.
- `app.js`: landing 3D campus now tracks the cursor (beacon, spotlight, leaning tower, custom cursor).
- `academic-calendar.html`: embeds the official 2026-27 calendar page.
