import { createClient } from 'npm:@supabase/supabase-js@2';

// Supabase service role client for admin-level operations (e.g., deleting users from auth)
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')! // This is for admin tasks like deleting users from auth
);

Deno.serve(async (req) => {
  try {
    // Step 1: Verify the access token from the user's session
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Authorization header missing." }),
        { status: 401 }
      );
    }

    const token = authHeader.replace('Bearer ', '')
    if (!token) {
      return new Response(
        JSON.stringify({ error: "Bearer token missing." }),
        { status: 401 }
      );
    }

    // Create a Supabase client for the user using the token to enforce RLS
    const supabaseUserClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Step 2: Fetch the user from the token (no need for userId in the body)
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token." }),
        { status: 401 }
      );
    }

    const userId = user.id; // We get the userId directly from the token

    // Step 3: Delete the user's data from the 'users' table using the user-level client (RLS will enforce security)
    const { error: dbError } = await supabaseUserClient
      .from('users') // Assuming your users table is named 'users'
      .delete()
      .eq('id', userId); // RLS ensures only the logged-in user can delete their own data

    if (dbError) {
      console.error("Error deleting user data:", dbError);
      return new Response(
        JSON.stringify({ error: "Error deleting user data." }),
        { status: 500 }
      );
    }

    // Step 4: Delete the user from Supabase Auth using the service role client
    const { error: authDeleteError } = await supabaseAdmin.auth.admin.deleteUser(userId);
    if (authDeleteError) {
      console.error("Error deleting auth user:", authDeleteError);
      return new Response(
        JSON.stringify({ error: "Error deleting authentication user." }),
        { status: 500 }
      );
    }

    // Step 5: Send success response
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