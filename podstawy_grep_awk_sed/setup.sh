#!/bin/bash
# Tworzy pliki do ćwiczeń z grep, awk, sed
# Uruchom: bash setup.sh

mkdir -p ~/warsztat
cd ~/warsztat

# --- access.log — logi nginx ---
cat > access.log << 'EOF'
10.0.0.15 - - [28/Apr/2026:08:01:12 +0000] "GET /api/users HTTP/1.1" 200 1823
10.0.0.23 - - [28/Apr/2026:08:01:45 +0000] "GET /api/products HTTP/1.1" 200 4201
10.0.0.42 - - [28/Apr/2026:08:02:03 +0000] "POST /api/orders HTTP/1.1" 500 342
10.0.0.8  - - [28/Apr/2026:08:02:17 +0000] "GET /api/users/99 HTTP/1.1" 404 89
10.0.0.15 - - [28/Apr/2026:08:02:31 +0000] "GET /api/products HTTP/1.1" 200 4201
10.0.0.42 - - [28/Apr/2026:08:02:44 +0000] "POST /api/orders HTTP/1.1" 500 342
10.0.0.31 - - [28/Apr/2026:08:03:02 +0000] "GET /api/health HTTP/1.1" 200 12
10.0.0.19 - - [28/Apr/2026:08:03:18 +0000] "GET /api/users HTTP/1.1" 200 1823
10.0.0.42 - - [28/Apr/2026:08:03:29 +0000] "POST /api/orders HTTP/1.1" 500 342
10.0.0.55 - - [28/Apr/2026:08:03:47 +0000] "GET /api/products/12 HTTP/1.1" 200 931
10.0.0.8  - - [28/Apr/2026:08:04:01 +0000] "GET /api/users/100 HTTP/1.1" 404 89
10.0.0.23 - - [28/Apr/2026:08:04:15 +0000] "GET /api/orders HTTP/1.1" 200 7823
10.0.0.42 - - [28/Apr/2026:08:04:28 +0000] "POST /api/orders HTTP/1.1" 502 0
10.0.0.31 - - [28/Apr/2026:08:04:44 +0000] "GET /api/health HTTP/1.1" 200 12
10.0.0.15 - - [28/Apr/2026:08:05:02 +0000] "POST /api/login HTTP/1.1" 200 512
10.0.0.42 - - [28/Apr/2026:08:05:19 +0000] "POST /api/orders HTTP/1.1" 500 342
10.0.0.19 - - [28/Apr/2026:08:05:33 +0000] "GET /api/products HTTP/1.1" 200 4201
10.0.0.77 - - [28/Apr/2026:08:05:48 +0000] "GET /api/users HTTP/1.1" 200 1823
10.0.0.42 - - [28/Apr/2026:08:06:01 +0000] "POST /api/orders HTTP/1.1" 500 342
10.0.0.55 - - [28/Apr/2026:08:06:17 +0000] "GET /api/products/5 HTTP/1.1" 200 788
10.0.0.31 - - [28/Apr/2026:08:06:32 +0000] "GET /api/health HTTP/1.1" 200 12
10.0.0.8  - - [28/Apr/2026:08:06:45 +0000] "DELETE /api/users/5 HTTP/1.1" 403 67
10.0.0.42 - - [28/Apr/2026:08:07:02 +0000] "POST /api/orders HTTP/1.1" 502 0
10.0.0.23 - - [28/Apr/2026:08:07:18 +0000] "GET /api/users HTTP/1.1" 200 1823
10.0.0.15 - - [28/Apr/2026:08:07:31 +0000] "GET /api/orders HTTP/1.1" 200 7823
10.0.0.42 - - [28/Apr/2026:08:07:44 +0000] "POST /api/orders HTTP/1.1" 500 342
10.0.0.19 - - [28/Apr/2026:08:08:02 +0000] "GET /api/products HTTP/1.1" 200 4201
10.0.0.77 - - [28/Apr/2026:08:08:15 +0000] "GET /api/users/3 HTTP/1.1" 200 621
10.0.0.42 - - [28/Apr/2026:08:08:29 +0000] "POST /api/orders HTTP/1.1" 500 342
10.0.0.31 - - [28/Apr/2026:08:08:44 +0000] "GET /api/health HTTP/1.1" 200 12
EOF

# --- app.log — logi aplikacji ---
cat > app.log << 'EOF'
2026-04-28 08:00:01 [INFO] Server started on port 8080
2026-04-28 08:00:02 [INFO] Database connection established: db-01.internal:5432
2026-04-28 08:00:15 [INFO] Cache warmed up: 1240 keys loaded
2026-04-28 08:01:03 [INFO] GET /api/users 200 (12ms)
2026-04-28 08:01:44 [INFO] GET /api/products 200 (8ms)
2026-04-28 08:02:03 [WARN] Slow query detected: SELECT * FROM orders took 1823ms
2026-04-28 08:02:04 [ERROR] Order processing failed: database timeout after 30s
2026-04-28 08:02:04 [ERROR] Stack trace: NullPointerException at OrderService.java:142
2026-04-28 08:02:44 [ERROR] Order processing failed: database timeout after 30s
2026-04-28 08:03:01 [INFO] GET /api/health 200 (1ms)
2026-04-28 08:03:18 [INFO] GET /api/users 200 (11ms)
2026-04-28 08:03:29 [ERROR] Order processing failed: database timeout after 30s
2026-04-28 08:03:31 [WARN] Memory usage at 78% — GC pressure increasing
2026-04-28 08:04:01 [INFO] GET /api/products 200 (9ms)
2026-04-28 08:04:28 [ERROR] Upstream connection refused: db-01.internal:5432
2026-04-28 08:04:29 [ERROR] Order processing failed: database timeout after 30s
2026-04-28 08:04:31 [WARN] Retry 1/3 — waiting 5s before reconnect
2026-04-28 08:04:36 [WARN] Retry 2/3 — waiting 5s before reconnect
2026-04-28 08:04:41 [WARN] Retry 3/3 — waiting 5s before reconnect
2026-04-28 08:04:46 [ERROR] Database reconnect failed after 3 attempts
2026-04-28 08:04:47 [INFO] Fallback to read-only mode activated
2026-04-28 08:05:19 [ERROR] Order processing failed: service in read-only mode
2026-04-28 08:05:33 [INFO] GET /api/products 200 (8ms)
2026-04-28 08:05:48 [INFO] GET /api/users 200 (14ms)
2026-04-28 08:06:01 [ERROR] Order processing failed: service in read-only mode
2026-04-28 08:06:32 [INFO] GET /api/health 200 (1ms)
2026-04-28 08:06:51 [INFO] Database connection re-established: db-01.internal:5432
2026-04-28 08:06:52 [INFO] Read-only mode deactivated
2026-04-28 08:07:02 [ERROR] Order processing failed: stale connection in pool
2026-04-28 08:07:18 [INFO] GET /api/users 200 (12ms)
2026-04-28 08:07:44 [ERROR] Order processing failed: stale connection in pool
2026-04-28 08:08:02 [INFO] Connection pool reset completed
2026-04-28 08:08:29 [INFO] GET /api/orders 200 (23ms)
2026-04-28 08:08:44 [INFO] GET /api/health 200 (1ms)
EOF

# --- servers.txt — inwentarz serwerów ---
cat > servers.txt << 'EOF'
web-01 192.168.1.10 prod 12
web-02 192.168.1.11 prod 15
web-03 192.168.1.12 prod 9
web-04 192.168.1.13 staging 8
api-01 192.168.1.20 prod 23
api-02 192.168.1.21 prod 187
api-03 192.168.1.22 staging 19
db-01  192.168.1.30 prod 45
db-02  192.168.1.31 prod 312
cache-01 192.168.1.40 prod 3
cache-02 192.168.1.41 prod 4
worker-01 192.168.1.50 prod 67
worker-02 192.168.1.51 prod 145
monitor-01 192.168.1.60 prod 11
EOF

# --- config.conf — konfiguracja nginx ---
cat > config.conf << 'EOF'
upstream backend {
    server 192.168.1.10:8080 weight=3;
    server 192.168.1.11:8080 weight=3;
    server 192.168.1.12:8080 weight=1;  # słabszy node
}

server {
    listen 80;
    server_name api.example.com;

    location /api/ {
        proxy_pass http://192.168.1.10:8080;
        proxy_set_header Host $host;
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
    }

    # stary endpoint — do usunięcia
    location /legacy/ {
        proxy_pass http://192.168.1.99:8080;
    }
}

server {
    listen 80;
    server_name admin.example.com;

    location / {
        proxy_pass http://192.168.1.10:8080/admin;
        allow 192.168.1.0/24;
        deny all;
    }
}
EOF

# --- backend.conf — drugi config z tym samym IP ---
cat > backend.conf << 'EOF'
# backend service configuration
upstream_host = 192.168.1.10
upstream_port = 8080
admin_host = 192.168.1.10
metrics_endpoint = http://192.168.1.10:9090/metrics
log_level = debug
EOF

echo "Pliki gotowe w ~/warsztat:"
ls -lh ~/warsztat
