-- Christ Connect: PostgreSQL starter schema. Run only on a private server.
-- Do NOT store passwords, attendance, or student data in the browser or a public Git repository.
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_number CITEXT UNIQUE NOT NULL,
  university_email CITEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  school TEXT, department TEXT, programme TEXT, batch_year SMALLINT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended','graduated')),
  email_verified_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE student_sessions (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE, token_hash TEXT UNIQUE NOT NULL, expires_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE attendance_records (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE, course_code TEXT NOT NULL, course_name TEXT NOT NULL, sessions_held SMALLINT NOT NULL CHECK(sessions_held>=0), sessions_attended SMALLINT NOT NULL CHECK(sessions_attended>=0 AND sessions_attended<=sessions_held), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), UNIQUE(student_id,course_code));
CREATE TABLE events (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), title TEXT NOT NULL, starts_at TIMESTAMPTZ NOT NULL, location TEXT, capacity INTEGER, published BOOLEAN NOT NULL DEFAULT false);
CREATE TABLE event_registrations (student_id UUID REFERENCES students(id) ON DELETE CASCADE, event_id UUID REFERENCES events(id) ON DELETE CASCADE, registered_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY(student_id,event_id));
CREATE TABLE clubs (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name TEXT UNIQUE NOT NULL, level TEXT NOT NULL CHECK(level IN ('university','department')), school TEXT, department TEXT, description TEXT, official_url TEXT, active BOOLEAN NOT NULL DEFAULT true);
CREATE TABLE club_memberships (student_id UUID REFERENCES students(id) ON DELETE CASCADE, club_id UUID REFERENCES clubs(id) ON DELETE CASCADE, role TEXT NOT NULL DEFAULT 'member', joined_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY(student_id,club_id));
CREATE TABLE canteen_items (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name TEXT NOT NULL, price_paise INTEGER NOT NULL CHECK(price_paise>=0), available BOOLEAN NOT NULL DEFAULT true);
CREATE TABLE canteen_orders (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), student_id UUID NOT NULL REFERENCES students(id), status TEXT NOT NULL DEFAULT 'placed' CHECK(status IN ('placed','accepted','ready','collected','cancelled')), pickup_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE canteen_order_items (order_id UUID REFERENCES canteen_orders(id) ON DELETE CASCADE, item_id UUID REFERENCES canteen_items(id), quantity SMALLINT NOT NULL CHECK(quantity>0), price_paise INTEGER NOT NULL CHECK(price_paise>=0), PRIMARY KEY(order_id,item_id));
CREATE TABLE audit_log (id BIGSERIAL PRIMARY KEY, student_id UUID REFERENCES students(id), action TEXT NOT NULL, ip_address INET, created_at TIMESTAMPTZ NOT NULL DEFAULT now());

-- Authorize every query by authenticated student ID on the server. Never accept a student ID from the client.
-- Store password_hash using Argon2id; use an HttpOnly, Secure, SameSite cookie for sessions; rate-limit login and require university-email OTP/MFA.
