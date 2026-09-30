# Christ Connect Deluxe V4 — setup

## Frontend
1. Keep your existing `config.js` values (Supabase URL + publishable key).
2. Run the site with Live Server or `python -m http.server 5500`.
3. Open `http://127.0.0.1:5500/`.

## Authentication persistence
The site now uses Supabase Auth persistence with a dedicated storage key. Returning students are restored automatically and are redirected to `dashboard.html` when a valid session is already present. Signing out is the explicit way to end the session.

## Canteen preorder
Run `supabase/upgrade_v3.sql` in the Supabase SQL Editor if you have not already run it. It adds:
- Delhi NCR dining outlets
- outlet-linked menu items
- student-only preorders
- pickup date + time slot
- order code generation
- price snapshotting
- order history
- secure RPC-based placement/cancellation

The demo menu names/prices are placeholders until approved vendor prices are available.

## Edge Functions
`supabase/functions/` is intentionally unchanged from the working V3 build. No function redeploy is needed just for the V4 frontend/data pass.

## Delhi NCR content
The active site uses Delhi NCR campus facts, schools, university-level student bodies/centres, current published Delhi NCR activity names, dining outlets, and the official social hub `@christdelhincr`. No unverified individual club Instagram handles are hard-coded.
