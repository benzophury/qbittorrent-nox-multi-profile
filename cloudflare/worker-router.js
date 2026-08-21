/**
 * Cloudflare Worker Router for Multi-Profile qBittorrent-nox
 * 
 * Routes incoming HTTP requests to separate qBittorrent-nox instances 
 * based on subdomains or request path prefix.
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Profile 1 Origin (e.g. cloudflared tunnel endpoint or public URL)
    const USER1_ORIGIN = env.USER1_ORIGIN || "http://user1-qb.internal";
    
    // Profile 2 Origin
    const USER2_ORIGIN = env.USER2_ORIGIN || "http://user2-qb.internal";

    let targetOrigin = USER1_ORIGIN;

    // Subdomain-based routing logic
    if (url.hostname.startsWith("user2") || url.pathname.startsWith("/user2")) {
      targetOrigin = USER2_ORIGIN;
    } else if (url.hostname.startsWith("user1") || url.pathname.startsWith("/user1")) {
      targetOrigin = USER1_ORIGIN;
    }

    const destinationUrl = new URL(url.pathname + url.search, targetOrigin);

    // Forward request to selected qBittorrent instance
    const modifiedRequest = new Request(destinationUrl.toString(), {
      method: request.method,
      headers: request.headers,
      body: request.body,
      redirect: 'manual'
    });

    return fetch(modifiedRequest);
  }
};
