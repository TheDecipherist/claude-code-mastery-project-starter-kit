---
name: nginx
description: Production NGINX configuration best practices, especially as a reverse proxy in front of containerized backends. Use when writing or editing nginx.conf, server blocks, upstreams, SSL, proxy caching, security headers, structured logging, or stream (TCP/UDP) proxying. Covers the Docker-DNS resolver that keeps upstreams from going stale, separate access-controlled health ports, the stream-block placement gotcha, and headers that must be sent on errors too. Kept separate from the docker and docker-swarm skills.
when_to_use: |
  - Writing or editing nginx.conf, a server block, an upstream, or an SSL block
  - Putting NGINX in front of containerized services as a reverse proxy
  - Upstreams that resolve once at startup and then break when a container is replaced
  - Structured logging, proxy caching, security headers, or TCP/UDP (stream) proxying
  - Do NOT use for Dockerfile or Swarm deploy concerns, those are the docker and docker-swarm skills
---

# NGINX: Production Reverse-Proxy Config

Aimed at NGINX in front of containerized backends. The defaults are fine for a static site, these are the things that bite in production.

## Resolve upstreams through Docker DNS with a short TTL

By default NGINX resolves an upstream host once, at startup, and caches the IP forever. In Docker that IP belongs to a container that will be replaced, so the proxy keeps sending traffic to a dead address. Point NGINX at Docker's internal DNS and force re-resolution:

```nginx
http {
    resolver 127.0.0.11 ipv6=off valid=10s;   # Docker DNS, re-resolve every 10s
}
```

`valid=10s` is what makes NGINX pick up the new container after a restart or scale. This is the NGINX side of "never hardcode IPs", see the docker-swarm skill for the principle.

## Upstreams by service name, with keepalive

Reference backends by service name, never IP. Reuse connections with `keepalive`, which needs HTTP/1.1 and a cleared Connection header:

```nginx
upstream backend {
    server backend-service:8080;
    keepalive 32;
}
server {
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

## Structured JSON logs to stdout/stderr

Log JSON so an aggregator can parse it, and write to stdout/stderr so Docker's logging driver captures it. Never log to a file inside the container.

```nginx
log_format json_log escape=json '{'
    '"time":$msec,"method":"$request_method","status":$status,'
    '"uri":"$request_uri","rt":$request_time,'
    '"upstream":"$upstream_addr","cache":"$upstream_cache_status",'
    '"client":"$remote_addr","xff":"$http_x_forwarded_for"'
'}';
access_log /dev/stdout json_log;
error_log  /dev/stderr warn;
```

## Health and status on separate, access-restricted ports

Keep health checks and metrics off the production port: different access control, no log noise, no interference with real traffic. Restrict to internal networks and turn off access logging.

```nginx
server {                          # load balancer health check
    listen 82;
    allow 10.0.0.0/8; allow 172.16.0.0/12; allow 127.0.0.1; deny all;
    location /health { access_log off; return 200 "OK"; }
}
server {                          # stub_status for Prometheus/Datadog
    listen 81;
    allow 10.0.0.0/8; allow 127.0.0.1; deny all;
    location /nginx_status { stub_status on; }
}
```

A deep health check that proxies an upstream's own `/health` is worth a third port when a service's liveness depends on its backend being reachable.

## Stream (TCP/UDP) blocks go OUTSIDE the http block

Proxying a non-HTTP protocol like MongoDB or a database uses the `stream` module, which is a top-level block, not inside `http`. Putting it inside `http` is a silent misconfiguration. HTTP services (an Elasticsearch REST proxy, say) stay inside `http`.

```nginx
load_module modules/ngx_stream_module.so;
include /etc/nginx/mongo.conf;    # stream { ... }  OUTSIDE http
http {
    include /etc/nginx/elasticsearch.conf;   # HTTP proxy, INSIDE http
}
```

## SSL and security headers

Modern protocols and ciphers, session cache, OCSP stapling. When certs come from Docker secrets they are mounted at `/run/secrets/<name>`:

```nginx
ssl_certificate     /run/secrets/server_pem;
ssl_certificate_key /run/secrets/server_key;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_session_cache shared:SSL:60m;
ssl_stapling on; ssl_stapling_verify on;
```

Send security headers with `always` so they are present on error responses too, not just 2xx/3xx:

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

## Always add a Content-Security-Policy, this is the one that gets skipped

CSP is the highest-value security header and the one almost always left out. The others harden edges; CSP is the primary defense against XSS and content injection, it tells the browser which sources are allowed to load scripts, styles, images, and frames, so an injected `<script>` from an attacker simply doesn't execute. A site without a CSP has no second line of defense once markup injection gets through. Add it by default, do not wait to be asked.

`default-src 'self'` alone is technically a CSP but it breaks most real apps (CDNs, inline styles, analytics) and lulls you into thinking you're covered, so set the directives explicitly:

```nginx
add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'self'" always;
```

Rules that matter:
- **Avoid `'unsafe-inline'` and `'unsafe-eval'` in `script-src`.** They re-open the XSS hole CSP exists to close. If you have inline scripts, use a per-request nonce or a hash, not a blanket unsafe allow.
- **`object-src 'none'` and `base-uri 'self'`** are free wins that block plugin and base-tag injection. Set them every time.
- **`frame-ancestors`** controls who can iframe you and supersedes `X-Frame-Options`, so put your clickjacking policy here.
- **Roll out with report-only first.** A too-strict CSP breaks the page silently. Ship `Content-Security-Policy-Report-Only` to collect violations without enforcing, watch what trips, tighten, then promote to the enforcing header. The real policy is app-specific and is built by tuning, not guessed in one line.

## Proxy caching for read-heavy upstreams

Cache GET/HEAD, and serve stale on upstream error or timeout so a backend hiccup doesn't reach users:

```nginx
proxy_cache es_cache;
proxy_cache_methods GET HEAD;
proxy_cache_valid 200 1m;
proxy_cache_key $host$uri$args;
proxy_cache_use_stale updating error timeout http_500 http_502 http_503 http_504;
proxy_hide_header X-Powered-By;
add_header X-Proxy-Cache $upstream_cache_status;
```

## Watch line endings in config files

NGINX config copied in with Windows CRLF line endings can fail to parse or behave oddly in a Linux container, which is why production NGINX images often run `dos2unix` on the configs at build time. If `nginx -t` reports something that makes no sense, check the line endings first, see the dev-pitfalls skill.

---

This skill is built to grow. Add a directive when a real production NGINX problem has a stable, defensible fix. ModSecurity/WAF setup (build as a dynamic module, `load_module`) is deep enough to deserve its own section when needed.
