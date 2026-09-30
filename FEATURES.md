# Christ Connect · Feature Inventory

This build preserves the original Christ Connect feature surface while using the working Supabase authentication/backend from the current build.

## Public / campus hub
- Delhi NCR scrollytelling home
- Campus Bulletin / announcements
- Event discovery and filters
- Club discovery
- Lost & Found
- Marketplace
- Skill Exchange
- Campus Guide
- Rewards
- Notifications
- Community
- Today / This Week / Upcoming event views
- Workshops / Hackathons / Competitions / Guest Lectures / Cultural Fests / Sports
- Department Events / Club Events
- Event Registration / Countdown / Calendar
- Student account feature pages
- Admin dashboard concept page

## Authenticated student experience
- Registration-number + password login via Supabase Auth
- Student dashboard
- Original-style student profile with Supabase-backed identity/academics/activity
- Profile editing for full name and bio
- Saved events, joined clubs, notifications, orders, listings, lost/found, wishlist and settings surfaces

## Security
- Password verification remains inside Supabase Auth.
- Student data stays behind authenticated access and PostgreSQL RLS.
- No service-role/secret key is shipped to the browser.

Demo-only content on feature pages is labelled or intentionally kept as concept UI; it should not be treated as official university data.
