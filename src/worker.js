export default {
  async fetch(request, env) {
    const method = request.method.toUpperCase();
    const origin = request.headers.get("Origin") || "";

    // 1. Strictly block TRACE, CONNECT, TRACK
    if (method === "TRACE" || method === "CONNECT" || method === "TRACK") {
      return new Response("Method Not Allowed", {
        status: 405,
        statusText: "Method Not Allowed",
        headers: {
          "Content-Type": "text/plain",
          "Allow": "GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD",
        },
      });
    }

    const isAllowedOrigin = origin === "https://ibuild.najibcode.workers.dev" || origin.endsWith(".najibcode.workers.dev");
    const allowOriginHeader = isAllowedOrigin ? origin : "https://ibuild.najibcode.workers.dev";

    // 2. Handle Preflight OPTIONS
    if (method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": allowOriginHeader,
          "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD",
          "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With, apikey, Prefer",
          "Access-Control-Max-Age": "86400",
          "Vary": "Origin",
        },
      });
    }

    // 3. Serve asset from ASSETS binding
    let response;
    try {
      response = await env.ASSETS.fetch(request);
    } catch (err) {
      return new Response("Not Found", { status: 404 });
    }

    // 4. Wrap response with strict CORS and Security Headers
    const headers = new Headers(response.headers);
    headers.set("Access-Control-Allow-Origin", allowOriginHeader);
    headers.set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD");
    headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, apikey, Prefer");
    headers.set("X-Content-Type-Options", "nosniff");
    headers.set("X-Frame-Options", "DENY");
    headers.set("X-XSS-Protection", "1; mode=block");
    headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
    headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=()");

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  },
};
