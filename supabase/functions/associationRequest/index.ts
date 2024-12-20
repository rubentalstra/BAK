import { createClient } from "npm:@supabase/supabase-js@2";
import { v4 as uuidv4 } from "npm:uuid";

interface AssociationRequest {
  id: string;
  user_id: string;
  name: string;
  website_url: string;
  status: string;
  processed: boolean;
}

interface WebhookPayload {
  type: "UPDATE";
  table: string;
  record: AssociationRequest;
  schema: "public";
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  if (req.method === "POST") {
    try {
      const payload: WebhookPayload = await req.json();

      if (
        payload.type === "UPDATE" && payload.table === "association_requests"
      ) {
        await handleRequestStatusUpdate(payload.record);
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { "Content-Type": "application/json" },
      });
    } catch (error) {
      console.error("Error in webhook handler:", error);
      return new Response(
        JSON.stringify({
          error: error instanceof Error ? error.message : "Unknown error",
        }),
        {
          headers: { "Content-Type": "application/json" },
          status: 400,
        },
      );
    }
  }

  return new Response("Not Found", { status: 404 });
});

const handleRequestStatusUpdate = async (request: AssociationRequest) => {
  if (request.processed) {
    // If the request has already been processed, do nothing
    return;
  }

  // Update the request status to processed
  await supabase
    .from("association_requests")
    .update({ processed: true })
    .eq("id", request.id)
    .single();

  // Handle approval
  if (request.status === "Approved") {
    // Generate a UUID for the association
    const associationId = uuidv4();

    // Create the association
    await supabase
      .from("associations")
      .insert({
        id: associationId,
        name: request.name,
        website_url: request.website_url,
      })
      .select();

    // Assign the requester full permissions using the new structure
    const permissions = {
      hasAllPermissions: true,
      canManagePermissions: false,
      canInviteMembers: false,
      canRemoveMembers: false,
      canManageRoles: false,
      canManageBaks: false,
      canApproveBaks: false,
    };

    await supabase.from("association_members").insert({
      association_id: associationId,
      user_id: request.user_id,
      role: "Admin",
      permissions: permissions,
    });

    // Insert into notifications table
    await supabase.from("notifications").insert({
      user_id: request.user_id,
      title: "Association Request Approved",
      body:
        `Your request to create the association "${request.name}" has been approved.`,
    });
  } else if (request.status === "Declined") {
    // Insert into notifications table for declined requests
    await supabase.from("notifications").insert({
      user_id: request.user_id,
      title: "Association Request Declined",
      body: "Your request to create an association has been declined.",
    });
  }
};
