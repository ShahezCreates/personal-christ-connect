import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const secret = req.headers.get("x-admin-secret");

    if (!secret || secret !== Deno.env.get("CHRIST_CONNECT_ADMIN_SECRET")) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    const body = await req.json();

    const required = [
      "registrationNumber",
      "password",
      "universityEmail",
      "fullName"
    ];

    for (const key of required) {
      if (!body[key]) {
        return new Response(
          JSON.stringify({ error: `Missing ${key}` }),
          {
            status: 400,
            headers: { "Content-Type": "application/json" }
          }
        );
      }
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl) {
      throw new Error("SUPABASE_URL is missing");
    }

    if (!serviceRoleKey) {
      throw new Error("SUPABASE_SERVICE_ROLE_KEY is missing");
    }

    const admin = createClient(
      supabaseUrl,
      serviceRoleKey
    );

    // Create the Auth account
    const {
      data: authData,
      error: authError
    } = await admin.auth.admin.createUser({
      email: body.universityEmail.toLowerCase(),
      password: body.password,
      email_confirm: true
    });

    if (authError) {
      return new Response(
        JSON.stringify({
          stage: "auth",
          error: authError.message
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    if (!authData.user) {
      throw new Error("Auth user was not returned");
    }

    // Create the student profile
    const {
      error: profileError
    } = await admin
      .from("student_profiles")
      .insert({
        id: authData.user.id,
        registration_number:
          body.registrationNumber.toUpperCase(),
        university_email:
          body.universityEmail.toLowerCase(),
        full_name: body.fullName,
        school: body.school || null,
        department: body.department || null,
        programme: body.programme || null,
        batch_year: body.batchYear || null
      });

    if (profileError) {
      // Roll back Auth account if profile creation fails
      await admin.auth.admin.deleteUser(authData.user.id);

      return new Response(
        JSON.stringify({
          stage: "profile",
          error: profileError.message,
          details: profileError.details,
          hint: profileError.hint
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        id: authData.user.id,
        registrationNumber:
          body.registrationNumber.toUpperCase()
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" }
      }
    );

  } catch (error) {

    console.error("Provisioning error:", error);

    return new Response(
      JSON.stringify({
        stage: "server",
        error:
          error instanceof Error
            ? error.message
            : String(error)
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" }
      }
    );
  }
});