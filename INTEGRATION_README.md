# Christ Connect · Integrated V6

This package connects the supplied Christ Connect UI to the existing Supabase backend.

## Already connected
- Supabase Auth with persistent sessions (`christconnect-auth`)
- Registration-number + password login via Edge Function
- Student profile
- Attendance records + live what-if calculator
- Event registrations
- Club memberships + Delhi NCR organisation directory
- Notifications
- Canteen outlets + outlet-specific menus
- Prepaid wallet orders
- Two-minute server-side cancellation/refund
- Website e-receipts
- Lost & Found reports + claim messages
- Student order history

## Supabase migration
Run these after your existing schema/v2/v3/v4 scripts:

`supabase/integration_v6.sql`

## Local run
```powershell
python -m http.server 5500
```

Open:
`http://127.0.0.1:5500/`

The existing Edge Functions are not replaced by this frontend integration.

## Important
Canteen menu prices in the prototype database are demo values unless an administrator replaces them with verified vendor prices. The wallet/prepaid layer is real database logic, but this package does not pretend that a third-party payment gateway has been integrated.
