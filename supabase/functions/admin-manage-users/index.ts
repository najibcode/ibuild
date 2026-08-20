import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") || "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Server misconfiguration: missing Supabase credentials" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Authenticate caller via JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Unauthorized: Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const jwtToken = authHeader.replace("Bearer ", "");
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey);
    const { data: { user: callerUser }, error: authError } = await supabaseClient.auth.getUser(jwtToken);

    if (authError || !callerUser) {
      return new Response(
        JSON.stringify({ error: "Unauthorized: Invalid token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Authorize caller — verify admin role in user_roles or admin email
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const isEmailAdmin = callerUser.email?.toLowerCase().includes("admin");
    const { data: userRoleData } = await supabaseAdmin
      .from("user_roles")
      .select("roles(name)")
      .eq("user_id", callerUser.id)
      .maybeSingle();

    const roleName = (userRoleData as any)?.roles?.name?.toLowerCase();
    const isAdmin = roleName === "admin" || isEmailAdmin;

    if (!isAdmin) {
      return new Response(
        JSON.stringify({ error: "Forbidden: Admin privileges required" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch caller's profile for logging
    const { data: callerProfile } = await supabaseAdmin
      .from("profiles")
      .select("full_name")
      .eq("id", callerUser.id)
      .maybeSingle();
    const actorName = callerProfile?.full_name || callerUser.email || "System Admin";

    // 3. Process action
    const body = await req.json();
    const action = body.action;

    switch (action) {
      case "create_user": {
        const { email, password, full_name, role_name, phone, company_name, custom_permissions } = body;
        if (!email || !password) {
          return new Response(
            JSON.stringify({ error: "Email and password are required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Create Auth User
        const { data: newUserData, error: createError } = await supabaseAdmin.auth.admin.createUser({
          email: email.trim().toLowerCase(),
          password: password,
          email_confirm: true,
          user_metadata: { full_name: full_name || email.split("@")[0] },
        });

        if (createError || !newUserData.user) {
          return new Response(
            JSON.stringify({ error: createError?.message || "Failed to create user" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const newUserId = newUserData.user.id;

        // Upsert Profile with custom permissions
        await supabaseAdmin.from("profiles").upsert({
          id: newUserId,
          full_name: full_name || email.split("@")[0],
          phone: phone || "",
          company_name: company_name || "IBUILD",
          role_display: role_name || "employee",
          custom_permissions: custom_permissions || [],
          is_disabled: false,
          updated_at: new Date().toISOString(),
        });

        // Assign Role
        const targetRoleName = (role_name || "employee").toLowerCase();
        const { data: roleRow } = await supabaseAdmin
          .from("roles")
          .select("id")
          .eq("name", targetRoleName)
          .maybeSingle();

        if (roleRow) {
          await supabaseAdmin.from("user_roles").upsert(
            { user_id: newUserId, role_id: roleRow.id },
            { onConflict: "user_id" }
          );
        }

        // Log to audit_logs
        await supabaseAdmin.from("audit_logs").insert({
          actor_id: callerUser.id,
          actor_name: actorName,
          action: "user.created",
          target_type: "user",
          target_id: newUserId,
          details: {
            email,
            full_name,
            role: targetRoleName,
            functions_count: (custom_permissions || []).length,
          },
        });

        return new Response(
          JSON.stringify({
            success: true,
            user_id: newUserId,
            message: `User ${email} created successfully with role ${targetRoleName} and ${(custom_permissions || []).length} assigned functions`,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "update_permissions": {
        const { user_id, custom_permissions } = body;
        if (!user_id) {
          return new Response(
            JSON.stringify({ error: "user_id is required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        await supabaseAdmin.from("profiles").update({
          custom_permissions: custom_permissions || [],
          updated_at: new Date().toISOString(),
        }).eq("id", user_id);

        await supabaseAdmin.from("audit_logs").insert({
          actor_id: callerUser.id,
          actor_name: actorName,
          action: "permissions.updated",
          target_type: "user",
          target_id: user_id,
          details: { functions_count: (custom_permissions || []).length },
        });

        return new Response(
          JSON.stringify({ success: true, message: "User functions and permissions updated successfully" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "update_email": {
        const { user_id, new_email } = body;
        if (!user_id || !new_email) {
          return new Response(
            JSON.stringify({ error: "user_id and new_email are required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(user_id, {
          email: new_email.trim().toLowerCase(),
          email_confirm: true,
        });

        if (updateError) {
          return new Response(
            JSON.stringify({ error: updateError.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Log audit
        await supabaseAdmin.from("audit_logs").insert({
          actor_id: callerUser.id,
          actor_name: actorName,
          action: "user.email_updated",
          target_type: "user",
          target_id: user_id,
          details: { new_email },
        });

        return new Response(
          JSON.stringify({ success: true, message: `Email updated to ${new_email}` }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "update_password": {
        const { user_id, new_password } = body;
        if (!user_id || !new_password) {
          return new Response(
            JSON.stringify({ error: "user_id and new_password are required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const { error: pwdError } = await supabaseAdmin.auth.admin.updateUserById(user_id, {
          password: new_password,
        });

        if (pwdError) {
          return new Response(
            JSON.stringify({ error: pwdError.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Log audit
        await supabaseAdmin.from("audit_logs").insert({
          actor_id: callerUser.id,
          actor_name: actorName,
          action: "password.reset_by_admin",
          target_type: "user",
          target_id: user_id,
          details: { reset_by: actorName },
        });

        return new Response(
          JSON.stringify({ success: true, message: "Password updated successfully" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "reset_password_email": {
        const { email } = body;
        if (!email) {
          return new Response(
            JSON.stringify({ error: "email is required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const { error: resetError } = await supabaseClient.auth.resetPasswordForEmail(email);

        if (resetError) {
          return new Response(
            JSON.stringify({ error: resetError.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Log audit
        await supabaseAdmin.from("audit_logs").insert({
          actor_id: callerUser.id,
          actor_name: actorName,
          action: "password.reset_email_sent",
          target_type: "user",
          target_id: email,
          details: { recipient_email: email },
        });

        return new Response(
          JSON.stringify({ success: true, message: `Password reset email dispatched to ${email}` }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "list_users": {
        const { data: usersData, error: listError } = await supabaseAdmin.auth.admin.listUsers({
          page: 1,
          perPage: 100,
        });

        if (listError) {
          return new Response(
            JSON.stringify({ error: listError.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        return new Response(
          JSON.stringify({ success: true, users: usersData.users }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      default:
        return new Response(
          JSON.stringify({ error: `Unknown action: ${action}` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
