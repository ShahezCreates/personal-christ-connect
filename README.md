# Christ Connect · Delhi NCR — Deluxe Build

This build restores the large original Christ Connect feature surface while retaining the working Supabase login/backend from the recent connected version.

## What changed
- Original cream / dark-teal / coral palette restored as the primary visual language.
- More scrollytelling on the public home page: chapter sections, sticky storytelling, progressive reveal, parallax accents and scroll progress.
- Glassmorphism + neumorphism added without turning the whole site into a dark UI.
- Nearest metro is shown as **Shaheed Sthal NBA Metro Station**.
- All original feature HTML pages are restored.
- The profile page uses the original first-build composition, but reads the logged-in student's data from Supabase.
- Dashboard, portal login and Supabase Edge Functions are intentionally preserved from the connected build.

## Local run
```powershell
python -m http.server 5500
```
Open `http://127.0.0.1:5500/`.

## Supabase
Do not replace the working `config.js` or the `supabase/` backend files unless you know why. The browser only needs the Supabase URL + publishable/anon key.

The provisioning flow remains admin-controlled; real student details should only be loaded from legitimate university-authorized data.

## Demo data
Events, clubs and some feature-card examples are demo/concept content and must not be presented as official university records.
