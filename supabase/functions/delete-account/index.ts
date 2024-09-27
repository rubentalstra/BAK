import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

Deno.serve(async (req) => {
  try {
    // Step 1: Verify the access token
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Authorization header missing." }),
        { status: 401 }
      );
    }

    const token = authHeader.split("Bearer ")[1];
    if (!token) {
      return new Response(
        JSON.stringify({ error: "Bearer token missing." }),
        { status: 401 }
      );
    }

    // Verify JWT and get the user information from the token
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token." }),
        { status: 401 }
      );
    }

    // Step 2: Parse the request body (handle potential errors)
    let body;
    try {
      body = await req.json();
    } catch (error) {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body." }),
        { status: 400 }
      );
    }

    const { userId } = body;

    // Step 3: Ensure that the request's userId matches the authenticated user's ID
    if (userId !== user.id) {
      return new Response(
        JSON.stringify({ error: "You are not authorized to delete this account." }),
        { status: 403 }
      );
    }

    // Step 4: Delete the user data from the database
    const { error: dbError } = await supabase
      .from('users') // Assuming your users table is named 'users'
      .delete()
      .eq('id', userId);

    if (dbError) {
      console.error("Error deleting user data:", dbError);
      return new Response(
        JSON.stringify({ error: "Error deleting user data." }),
        { status: 500 }
      );
    }

    // Step 5: Delete the user from Supabase Auth
    const { error: authDeleteError } = await supabase.auth.admin.deleteUser(userId);

    if (authDeleteError) {
      console.error("Error deleting auth user:", authDeleteError);
      return new Response(
        JSON.stringify({ error: "Error deleting authentication user." }),
        { status: 500 }
      );
    }

    return new Response(JSON.stringify({ message: "Account deletion successful." }), {
      status: 200,
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(JSON.stringify({ error: "Unexpected error." }), {
      status: 500,
    });
  }
});