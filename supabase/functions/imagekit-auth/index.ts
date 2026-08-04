import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";
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
    // 1. Read Environment Secrets
    const publicKey = Deno.env.get("IMAGEKIT_PUBLIC_KEY");
    const privateKey = Deno.env.get("IMAGEKIT_PRIVATE_KEY");
    const urlEndpoint = Deno.env.get("IMAGEKIT_URL_ENDPOINT");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!publicKey || !privateKey || !urlEndpoint) {
      return new Response(
        JSON.stringify({ error: "Server misconfiguration: ImageKit secrets missing" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 500,
        }
      );
    }

    // 2. Validate Authenticated Supabase User
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Unauthorized: Missing Authorization header" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 401,
        }
      );
    }

    const jwtToken = authHeader.replace("Bearer ", "");
    if (supabaseUrl && supabaseAnonKey) {
      const supabase = createClient(supabaseUrl, supabaseAnonKey);
      const { data: { user }, error: authError } = await supabase.auth.getUser(jwtToken);

      if (authError || !user) {
        return new Response(
          JSON.stringify({ error: "Unauthorized: Invalid or expired Supabase token" }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 401,
          }
        );
      }
    }

    // 3. Generate ImageKit Signature
    const token = crypto.randomUUID();
    const expire = Math.floor(Date.now() / 1000) + 1800; // 30 minutes validity

    const encoder = new TextEncoder();
    const keyData = encoder.encode(privateKey);
    const messageData = encoder.encode(token + expire.toString());

    const hmacKey = await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "HMAC", hash: "SHA-1" },
      false,
      ["sign"]
    );

    const signatureBuffer = await crypto.subtle.sign("HMAC", hmacKey, messageData);
    const signatureArray = Array.from(new Uint8Array(signatureBuffer));
    const signature = signatureArray
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    // 4. Return Full Auth Credentials JSON
    return new Response(
      JSON.stringify({
        token,
        signature,
        expire,
        publicKey,
        urlEndpoint,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
