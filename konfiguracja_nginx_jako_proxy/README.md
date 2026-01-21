# Nginx Reverse Proxy - Spis poleceń

## 1. Prosty backend (Python)

```bash
# Utwórz katalog dla aplikacji
mkdir -p ~/backend
cd ~/backend

# Utwórz prostą stronę
nano index.html

# Uruchom Python HTTP server
python3 -m http.server 8000

# W nowym terminalu - test
curl localhost:8000
```

Przeglądarka: `http://IP_SERWERA:8000`

## 2. Konfiguracja Reverse Proxy

```bash
# Edytuj konfigurację Nginx
sudo nano /etc/nginx/sites-available/default
```

```nginx
location / {
    proxy_pass http://localhost:8000;
}
```

```bash
# Test składni
sudo nginx -t

# Przeładuj
sudo systemctl reload nginx
```

Przeglądarka: `http://IP_SERWERA`

## 3. Proxy Headers

```bash
# Zobacz co backend widzi
python3 -m http.server 8000
# 127.0.0.1 - - [date] "GET / HTTP/1.0" 200 -

# Edytuj config
sudo nano /etc/nginx/sites-available/default
```

```nginx
location / {
    proxy_pass http://localhost:8000;
  
    # Przekaż prawdziwe IP użytkownika
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  
    # Przekaż protokół (http/https)
    proxy_set_header X-Forwarded-Proto $scheme;
  
    # Przekaż oryginalny Host
    proxy_set_header Host $host;
}
```

```bash
# Test i reload
sudo nginx -t
sudo systemctl reload nginx
```

## 4. Wielu backendów

```bash
# Zainstaluj Node jeśli nie masz
sudo apt install nodejs npm -y

# Utwórz prosty serwer Node
mkdir -p ~/api
cd ~/api
nano server.js
```

```javascript
const http = require('http');

const server = http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({message: 'API działa!', port: 3000}));
});

server.listen(3000, () => {
    console.log('API na porcie 3000');
});
```

```bash
# Uruchom
node server.js

# W nowym terminalu - test
curl localhost:3000
# {"message":"API działa!","port":3000}

# Edytuj Nginx config
sudo nano /etc/nginx/sites-available/default
```

```nginx
# API na /api
location /api/ {
    proxy_pass http://localhost:3000/;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
}

# Strona główna na /
location / {
    proxy_pass http://localhost:8000;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
}
```

```bash
# Test i reload
sudo nginx -t
sudo systemctl reload nginx
```

Test w przeglądarce:

- `http://IP_SERWERA/` → Python (strona główna)
- `http://IP_SERWERA/api/` → Node.js (JSON)

## 5. Debugowanie

```bash
# Sprawdź czy backend działa
curl localhost:PORT

# Zobacz logi Nginx
tail /var/log/nginx/error.log

# Test składni
nginx -t
```
