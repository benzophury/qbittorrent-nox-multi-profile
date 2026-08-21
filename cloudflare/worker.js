/**
 * Streamix-style Cloudflare Worker Redirector for qBittorrent Multi-Profile
 * 
 * Routes permanent Worker URLs (/private and /public) to dynamic Quick Tunnels (*.trycloudflare.com)
 * backed by Cloudflare KV storage.
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // 1. Secret-protected Update Endpoint: /set?secret=SECRET&user=private|public&url=https://xyz.trycloudflare.com
    if (url.pathname === "/set" || url.searchParams.has("url")) {
      const secret = url.searchParams.get("secret");
      const user = (url.searchParams.get("user") || "private").toLowerCase();
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

    // Determine requested profile route (/private vs /public)
    let profile = "private";
    if (url.pathname.startsWith("/public")) {
      profile = "public";
    } else if (url.pathname.startsWith("/private")) {
      profile = "private";
    }

    const kvKey = `QB_URL_${profile.toUpperCase()}`;
    let target = null;

    if (env.QB_KV) {
      target = await env.QB_KV.get(kvKey);
    }

    // If root path '/' requested with no target set, return dashboard HTML
    if (url.pathname === "/" && !target) {
      let privateTarget = env.QB_KV ? await env.QB_KV.get("QB_URL_PRIVATE") : null;
      let publicTarget = env.QB_KV ? await env.QB_KV.get("QB_URL_PUBLIC") : null;

      const html = `
        <!DOCTYPE html>
        <html>
        <head>
          <title>qBittorrent Multi-Profile Router</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { font-family: -apple-system, sans-serif; background: #0f172a; color: #f8fafc; padding: 2rem; }
            .card { background: #1e293b; border-radius: 12px; padding: 1.5rem; margin-bottom: 1rem; border: 1px solid #334155; }
            a { color: #38bdf8; text-decoration: none; font-weight: bold; font-size: 1.1rem; }
            a:hover { text-decoration: underline; }
            .status { font-size: 0.85rem; color: #94a3b8; margin-top: 0.5rem; }
          </style>
        </head>
        <body>
          <h2>qBittorrent Multi-Profile Dashboard</h2>
          <div class="card">
            <h3>🔒 Private Profile</h3>
            ${privateTarget ? `<a href="/private" target="_blank">Launch Private WebUI ➔</a><div class="status">Tunnel: ${privateTarget}</div>` : `<div class="status">Offline / Tunnel Not Synced</div>`}
          </div>
          <div class="card">
            <h3>🌐 Public Profile</h3>
            ${publicTarget ? `<a href="/public" target="_blank">Launch Public WebUI ➔</a><div class="status">Tunnel: ${publicTarget}</div>` : `<div class="status">Offline / Tunnel Not Synced</div>`}
          </div>
        </body>
        </html>
      `;
      return new Response(html, { headers: { "Content-Type": "text/html;charset=UTF-8" } });
    }

    if (!target) {
      return new Response(`qBittorrent instance for '${profile}' is currently offline or tunnel not synced.`, { status: 503 });
    }

    const cleanTarget = target.replace(/\/+$/, "");
    const targetPath = url.pathname.replace(/^\/(private|public)/, "");
    
    // HTTP 302 Redirect to live Quick Tunnel
    return Response.redirect(cleanTarget + targetPath + url.search, 302);
  }
};
