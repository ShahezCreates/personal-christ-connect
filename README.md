# Christ Connect · Delhi NCR · V5

A Delhi NCR-specific Christ Connect student platform that keeps the original feature universe while adding a cinematic landing experience, persistent Supabase Auth sessions, student-owned profile data, subject-wise attendance intelligence, Lost & Found workflows, and outlet-specific canteen preorder.

## What changed
- Original Christ Connect editorial palette: cream / dark teal / coral / green / yellow.
- Scrollytelling landing page with sticky story panels, parallax reveals, cursor-follow visual and a pure-CSS 3D campus scene.
- Active imagery is limited to CHRIST Delhi NCR campus/gallery images referenced from the university's public gallery.
- Delhi NCR-only academic directory and student bodies / centres.
- Official 2026–27 Academic Calendar is linked directly to the university publication.
- Persistent Supabase Auth session (`persistSession` + auto refresh + dedicated storage key).
- Student profile is database-backed and scoped to the authenticated registration-number account.
- Attendance intelligence calculates current %, future attended %, future missed %, safe misses at target, and recovery classes.
- Canteen preorder across the ten named food outlets/counters published on the official Delhi NCR Dining Facilities page; each outlet has a distinct prototype menu.
- Preorders are prepaid in the application model, produce an on-site receipt code, save to the student's order history, and can only be cancelled through the server RPC during the first two minutes.
- Lost & Found lets authenticated students report lost/found items and submit claims. Item owners can review claims through their own authenticated view; new claims create notifications.
- Original Christ Connect feature pages are retained: events, today/week/upcoming, workshops, hackathons, competitions, guest lectures, cultural fests, sports, department events, club events, registration, countdown, calendar, skill exchange, marketplace, lost & found, community, campus guide, rewards, notifications, admin, saved events, wishlist, listings, orders, skills, interests, details, department and year.
- `server.js` is preserved exactly from the original project and is not used by the Supabase client workflow.

## Supabase setup
1. Keep the existing `config.js` project URL + publishable key. Never put a service-role/secret key in browser code.
2. If this is an existing Christ Connect Supabase project, run `supabase/v5_migration.sql` once in Supabase SQL Editor.
3. Keep the already-deployed `login-with-registration` and `provision-student` Edge Functions. No redeploy is needed just for the V5 frontend/migration.
4. The current application assumes the existing working registration-number login function returns a Supabase session.
5. Run locally: `python -m http.server 5500`
6. Open: `http://127.0.0.1:5500/`

### Demo login
Registration: `DEMO2026BCA001`
Password: `DemoPass!2026`

These are demo credentials, not official university credentials.

## Canteen payment note
The database/API has a prepaid order contract and stores a payment reference, but this package uses a **demo payment provider/reference**. That is intentionally not real-money processing. For production, replace the demo payment step with a real Razorpay/Stripe-style server-verified payment flow; never mark an order paid from browser-only input.

The public dining page names the campus food outlets but does not expose complete vendor price sheets; therefore the per-outlet prices in `v5_migration.sql` are explicitly prototype/demo values and should be replaced with approved vendor menus before real deployment.

## Data provenance
See `SOURCES_DELHI_NCR.md` for the current official pages used for campus, academics, dining, calendar, student bodies, activity names, social hub and gallery imagery.
