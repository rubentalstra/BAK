import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const authHeader = req.headers.get("Authorization")!;
    const token = authHeader.replace("Bearer ", "");

    // Create a Supabase client with the user's token for RLS enforcement
    const supabaseUserClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Create a Supabase admin client for admin-level operations
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Fetch the user using the client (token is used from the client's context)
    const {
      data: { user },
      error: authError,
    } = await supabaseUserClient.auth.getUser(token);

    if (authError || !user) {
      console.error("Error fetching user:", authError);
      return new Response(
        JSON.stringify({ error: "Error fetching user data." }),
        { status: 500 },
      );
    }

    const userId = user.id;

    // Fetch the user's profile_image
    const { data: userData, error: fetchError } = await supabaseUserClient
      .from("users")
      .select("profile_image")
      .eq("id", userId)
      .single();

    if (fetchError) {
      console.error("Error fetching user's profile image:", fetchError);
      return new Response(
        JSON.stringify({ error: "Error fetching user's profile image." }),
        { status: 500 },
      );
    }

    const profileImage = userData?.profile_image;

    if (profileImage) {
      const bucketName = "user-profile-images";
      // Adjust the file path to include 'user-profile-images/' before the profileImage
      const filePath = `user-profile-images/${profileImage}`;

      // Delete the profile image from storage
      const { error: deleteFileError } = await supabaseAdmin.storage
        .from(bucketName)
        .remove([filePath]);

      if (deleteFileError) {
        console.error("Error deleting profile image:", deleteFileError);
        // Decide whether to treat this as a fatal error or not
        // For now, proceed but log the error
      }
    }

    // Delete the user's data from the 'users' table (RLS enforced)
    const { error: dbError } = await supabaseUserClient
      .from("users")
      .delete()
      .eq("id", userId);

    if (dbError) {
      console.error("Error deleting user data:", dbError);
      return new Response(
        JSON.stringify({ error: "Error deleting user data." }),
        { status: 500 },
      );
    }

    // Delete the user from Supabase Auth
    const { error: authDeleteError } = await supabaseAdmin.auth.admin
      .deleteUser(userId);

    if (authDeleteError) {
      console.error("Error deleting auth user:", authDeleteError);
      return new Response(
        JSON.stringify({ error: "Error deleting authentication user." }),
        { status: 500 },
      );
    }

    // Send success response
    return new Response(
      JSON.stringify({ message: "Account deletion successful." }),
      { status: 200 },
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Unexpected error." }),
      { status: 500 },
    );
  }
});
