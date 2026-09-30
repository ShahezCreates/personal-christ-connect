# Christ Connect

College portal frontend with an Express and MongoDB REST API.

## Run locally

1. Install Node.js 20+ and run `npm install`.
2. Copy `.env.example` to `.env` and provide a MongoDB Atlas connection string and a long JWT secret.
3. Run `npm run dev`.

The API is served at `http://localhost:5000`. Check it with `GET /api/health`.

## API overview

| Resource | Public operations | Protected operations |
| --- | --- | --- |
| `/api/auth` | `POST /register`, `POST /login` | `GET /me` |
| `/api/courses` | `GET /`, `GET /:id` | teachers/admins create or edit; admins delete |
| `/api/notices` | `GET /` | teachers/admins manage their notices; admins manage all |
| `/api/events` | `GET /?upcoming=true` | teachers/admins manage their events; admins manage all |
| `/api/assignments` | — | teachers/admins create; students upload PDF submissions |

Pass `Authorization: Bearer <token>` for protected endpoints. Public registration always creates a `student` account. Promote trusted staff to `teacher` or `admin` directly in MongoDB; roles are deliberately not accepted during registration.

## Deployment

Set `MONGODB_URI`, `JWT_SECRET`, `CLIENT_ORIGIN`, and `PORT` in Render, Railway, or another Node hosting provider. The `uploads/` directory is suitable for local development; use cloud object storage before production deployment because hosted local disks are usually ephemeral.
