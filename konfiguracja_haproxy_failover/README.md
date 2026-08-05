# HAProxy - komendy z odcinka

Trzy serwery Linux w tej samej sieci. W przykładzie:
- **HAPROXY**: `3.120.244.170`
- **BACKEND1**: `3.76.41.172`
- **BACKEND2**: `3.127.148.197`

Podmień IP na swoje - reszta działa tak samo.

Security Group na HAPROXY musi mieć otwarty inbound TCP 80. Na BACKEND1 i BACKEND2 otwórz inbound TCP 8080 tylko dla IP maszyny HAPROXY.

---

## BACKEND1 i BACKEND2

Ustaw hostname zgodny z rolą:

```bash
sudo hostnamectl set-hostname backend1
```

Na BACKEND2 analogicznie: `backend2`.

Uruchom aplikację testową (setup.sh z repozytorium):

```bash
bash setup.sh
```

setup.sh:

```bash
#!/bin/bash
sudo apt install -y python3 2>/dev/null

cat > /tmp/app.py << 'EOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import socket

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(f"Response from: {socket.gethostname()}\n".encode())
    def log_message(self, format, *args):
        pass

HTTPServer(('0.0.0.0', 8080), Handler).serve_forever()
EOF

sudo python3 /tmp/app.py &
sleep 1
echo "Backend działa na porcie 8080"
curl localhost:8080
```

---

## HAPROXY

Instalacja:

```bash
sudo apt install haproxy
haproxy -v
```

Sprawdź, czy backendy odpowiadają:

```bash
curl 3.76.41.172:8080
curl 3.127.148.197:8080
```

Edytuj konfigurację:

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

```
frontend http_front
    bind *:80
    default_backend servers

backend servers
    balance roundrobin
    option httpchk GET /
    server backend1 3.76.41.172:8080 check
    server backend2 3.127.148.197:8080 check
```

Zastosuj i uruchom serwis:

```bash
sudo systemctl enable --now haproxy
sudo systemctl restart haproxy
sudo systemctl status haproxy
```

---

## Test - load balancing

```bash
curl 3.120.244.170
```

Wywołane kilkukrotnie pod rząd - odpowiedzi na zmianę z `backend1` i `backend2`.

---

## Symulacja awarii

Na BACKEND1:

```bash
sudo pkill -f /tmp/app.py
```

Na HAPROXY - sprawdź stan backendów:

```bash
echo "show servers state" | sudo socat stdio /run/haproxy/admin.sock
```

Ponowny test:

```bash
curl 3.120.244.170
```

---

## Przywrócenie backendu

Na BACKEND1:

```bash
bash setup.sh
```
