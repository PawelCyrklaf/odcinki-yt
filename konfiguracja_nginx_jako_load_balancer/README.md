# Nginx Load Balancing - Spis poleceń

## Setup - 2 backendy

### Backend 1

```bash
# Utwórz katalog
mkdir -p ~/backend1
cd ~/backend1

# Utwórz prostą stronę
nano index.html

# Uruchom na porcie 8001
python3 -m http.server 8001
```

### Backend 2

```bash
# Utwórz katalog
mkdir -p ~/backend2
cd ~/backend2

# Utwórz prostą stronę
nano index.html

# Uruchom na porcie 8002
python3 -m http.server 8002
```

### Test backendów

```bash
curl localhost:8001
curl localhost:8002
```

---

## Upstream + Round-Robin

### Konfiguracja Nginx

```bash
# Edytuj konfigurację
sudo nano /etc/nginx/sites-available/default
```

```nginx
upstream backend_servers {
    server localhost:8001;
    server localhost:8002;
}

server {
    listen 80;
    server_name _;
  
    location / {
        proxy_pass http://backend_servers;
    
        # Proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    
        # Wyłącz cache
        proxy_no_cache 1;
        proxy_cache_bypass 1;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
        expires off;
    }
}
```

### Test i reload

```bash
# Test składni
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Test load balancingu

```bash
# Test 10 requestów
for i in {1..10}; do curl -s http://localhost | grep -o "backend[12]"; done

# Test z liczeniem
for i in {1..20}; do curl -s http://localhost | grep -o "backend[12]"; done | sort | uniq -c
```

---

## Weight - Priorytet serwerów

### Konfiguracja

```bash
sudo nano /etc/nginx/sites-available/default
```

```nginx
upstream backend_servers {
    server localhost:8001 weight=3;  # 75% ruchu
    server localhost:8002 weight=1;  # 25% ruchu
}
```

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Test weight

```bash
# Test 20 requestów
for i in {1..20}; do curl -s http://localhost | grep -o "backend[12]"; done | sort | uniq -c

# Test 100 requestów (dokładniejszy)
for i in {1..100}; do curl -s http://localhost | grep -o "backend[12]"; done | sort | uniq -c
```

---

## Inne metody load balancingu

### least_conn

```nginx
upstream backend_servers {
    least_conn;
    server localhost:8001;
    server localhost:8002;
}
```

### ip_hash

```nginx
upstream backend_servers {
    ip_hash;
    server localhost:8001;
    server localhost:8002;
}
```

---

## Health Checks - Failover

### Test failover

```bash
# Wyłącz backend1 (Ctrl+C w terminalu z backend1)

# Test - cały ruch idzie do backend2
for i in {1..10}; do curl -s http://localhost | grep -o "backend[12]"; done | sort | uniq -c
```

### Konfiguracja health checks

```bash
sudo nano /etc/nginx/sites-available/default
```

```nginx
upstream backend_servers {
    server localhost:8001 max_fails=3 fail_timeout=30s;
    server localhost:8002 max_fails=3 fail_timeout=30s;
}
```

### Włącz backend1 z powrotem

```bash
cd ~/backend1
python3 -m http.server 8001

# Poczekaj ~10 sekund, potem test
for i in {1..20}; do curl -s http://localhost | grep -o "backend[12]"; done | sort | uniq -c
```

---

## Pomocne polecenia

### Sprawdź oba backendy bezpośrednio

```bash
curl localhost:8001
curl localhost:8002
```

### Restart/Reload Nginx

```bash
# Restart
sudo systemctl restart nginx

# Reload
sudo systemctl reload nginx

# Status
sudo systemctl status nginx
```

### Logi Nginx

```bash
# Access log
sudo tail -f /var/log/nginx/access.log

# Error log
sudo tail -f /var/log/nginx/error.log
```

### Sprawdź procesy Python

```bash
ps aux | grep "python3 -m http.server"
```

### Zatrzymaj backendy

```bash
# Znajdź PID i zabij
pkill -f "python3 -m http.server"
```
