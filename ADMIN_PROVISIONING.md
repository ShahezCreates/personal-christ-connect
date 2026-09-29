# Provisioning a demo student

The project intentionally contains no real student data. Deploy `provision-student` and set `CHRIST_CONNECT_ADMIN_SECRET`.

Example request:

```bash
curl -X POST "https://YOUR_PROJECT_REF.supabase.co/functions/v1/provision-student" \
  -H "Content-Type: application/json" \
  -H "x-admin-secret: YOUR_SECRET" \
  -d '{"registrationNumber":"DEMO2026BCA001","password":"DemoPass!2026","universityEmail":"demo.student@example.com","fullName":"Demo Student","school":"School of Computing","department":"Computer Applications","programme":"BCA","batchYear":2026}'
```

Replace the demo email with an address you control. Never put the service-role key in frontend code.
