/**
 * Cloudflare Worker KV Dynamic Redirector for Multi-User qBittorrent-nox
 * 
 * Supports free Cloudflare Quick Tunnels (*.trycloudflare.com) or changing IPs.
 * Automatically redirects permanent URLs (e.g. /user1 or /user2) to active tunnels.
 * 
 * Secret-protected update endpoint:
 *   GET /set?secret=YOUR_SECRET&user=user1&url=https://random.trycloudflare.com
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // 1. Sync / Update Endpoint
    if (url.pathname === "/set" || url.searchParams.has("url")) {
      const secret = url.searchParams.get("secret");
      const user = url.searchParams.get("user") || "user1";
      const targetUrl = url.searchParams.get("url");

      if (env.SECRET_KEY && secret !== env.SECRET_KEY) {
        return new Response("Unauthorized", { status: 401 });
      }

      if (targetUrl) {
        const kvKey = `QB_URL_${user.toUpperCase()}`;
        if (env.QB_KV) {
          await env.QB_KV.put(kvKey, targetUrl);
        }
        return new Response(`OK: ${user} target URL set to ${targetUrl}`);
      }
    }

    # 2. Redirect Endpoint
    let user = "user1";
    if (url.pathname.startsWith("/user2")) {
      user = "user2";
    } else if (url.pathname.startsWith("/user1")) {
      user = "user1";
    }

    const kvKey = `QB_URL_${user.toUpperCase()}`;
    let target = null;
    
    if (env.QB_KV) {
      target = await env.QB_KV.get(kvKey);
    }

    if (!target) {
      return new Response(`qBittorrent instance for '${user}' is currently offline.`, { status: 503 });
    }

    const cleanTarget = target.replace(/\/+$/, "");
    // Remove /user1 or /user2 prefix when redirecting if needed, or pass full path
    const targetPath = url.pathname.replace(/^\/(user1|user2)/, "");
    
    return Response.redirect(cleanTarget + targetPath + url.search, 302);
  }
};
