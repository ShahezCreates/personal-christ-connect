# Christ Connect V6 · Setup

## Database
If the base `supabase/schema.sql` is already installed, run `supabase/INSTALL_V6.sql` in the Supabase SQL Editor.
If you already ran V2/V3/V4, run only `supabase/integration_v6.sql`.

## Existing authentication
The working Edge Functions are intentionally untouched:
- `login-with-registration`
- `provision-student`

Keep only the publishable/anon key in `config.js`. Never put a service-role or `sb_secret_...` key in browser code.

## Local run
```powershell
python -m http.server 5500
```
Open `http://127.0.0.1:5500/`

## Connected live surfaces
- Persistent Supabase Auth session
- Student profile and editable profile text
- Subject attendance + what-if calculator
- Event list + student registrations
- Club directory + memberships
- Private notifications
- Canteen outlets + outlet-specific menus
- Prepaid wallet + server-side preorder
- Two-minute server-side order cancellation/refund
- Website e-receipts
- Lost & Found reports + claims
- My Orders

## Prototype-data note
Demo attendance and demo canteen prices are explicitly prototype values. The UI is database-backed, but vendor prices/payment gateway credentials must be configured with verified production data before treating the canteen flow as a real-money deployment.
