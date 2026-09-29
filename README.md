# Christ Connect — Complete Full-Stack Build

A Delhi NCR campus portal concept rebuilt with scrollytelling, glassmorphism/neumorphism and Supabase-backed authentication/data.

## 1. Supabase
1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. Copy Project URL and publishable/anon key into `config.js`.
4. Install CLI: `npm install -g supabase`
5. `supabase login`
6. `supabase link --project-ref YOUR_PROJECT_REF`
7. Deploy functions:
   - `supabase functions deploy login-with-registration`
   - `supabase functions deploy provision-student`
8. Set the admin secret: `supabase secrets set CHRIST_CONNECT_ADMIN_SECRET=YOUR_SECRET`

## 2. Create a demo student
Follow `ADMIN_PROVISIONING.md`.

## 3. Run locally
From this folder: `python -m http.server 5500` then open `http://localhost:5500`.

## Security
Passwords are handled by Supabase Auth. The frontend never receives the service-role key. Student-owned tables use RLS. The demo database data is not official university data.
