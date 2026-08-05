# HAProxy load balancer - automatyczny failover gdy backend padnie

---

## SEO

**Tytuł:**
```
HAProxy load balancer - automatyczny failover gdy backend padnie
```

**Opis:**
```
HAProxy - konfiguracja load balancera z automatycznym failoverem. Pokazuję jak rozłożyć ruch między dwa backendy i wykryć że jeden padł.

Link do plików z odcinka:
https://github.com/PawelCyrklaf/odcinki-yt/tree/main/linux_haproxy

#linux #haproxy #devops
```

**Słowa kluczowe:**
```
haproxy linux, haproxy konfiguracja, haproxy tutorial, haproxy load balancer, haproxy failover, haproxy backend, load balancer linux, haproxy health check, reverse proxy linux, high availability linux, load balancing tutorial, haproxy vs nginx, haproxy cfg, wysoka dostępność serwera, devops linux, linux serwer, systemctl haproxy, round robin load balancer
```

**Przypięty komentarz:**
```
Masz już load balancer w swoim środowisku? Napisz w komentarzu czego używasz - HAProxy, Nginx, coś innego 👇
```

---

## Pliki do przygotowania

Trzy maszyny Linux w tej samej sieci:
- **HAPROXY**: `3.120.244.170`
- **BACKEND1**: `3.76.41.172`
- **BACKEND2**: `3.127.148.197`

Podmień IP na swoje - reszta działa tak samo.

Security Group na maszynie HAPROXY musi mieć otwarty inbound TCP port 80 (ruch widzów/testów) - bez tego `curl` na public IP wisi bez odpowiedzi. Na BACKEND1 i BACKEND2 otwórz inbound TCP port 8080 tylko dla IP maszyny HAPROXY.

Na BACKEND1 i BACKEND2 ustaw hostname zgodny z rolą, żeby response z `/tmp/app.py` (używa `socket.gethostname()`) pokazywał `backend1`/`backend2` a nie domyślną nazwę AWS:

```bash
# na BACKEND1
sudo hostnamectl set-hostname backend1
# na BACKEND2
sudo hostnamectl set-hostname backend2
```

**setup.sh** - uruchom na BACKEND1 i BACKEND2

```bash
#!/bin/bash
sudo apt install -y python3 2>/dev/null

# Prosta aplikacja HTTP zwracająca nazwę hosta
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

## Scenariusz

### PREVIEW (20 sek) - nagrywaj osobno po zakończeniu sesji

Na HAProxy:

```bash
curl 3.120.244.170
curl 3.120.244.170
curl 3.120.244.170
```

Widać odpowiedzi na zmianę z BACKEND1 i BACKEND2. Zatrzymujemy BACKEND1 - kolejne `curl` zwracają tylko BACKEND2. *"Zaraz to zbudujesz."* Bez wyjaśnień.

---

### HOOK (10 sek)

`Masz serwis na jednym serwerze. Pada - aplikacja niedostępna, użytkownicy widzą błąd. HAProxy siedzi przed backendami, sprawdza co sekundę czy żyją i przełącza ruch automatycznie gdy jeden pada.`

---

### 1. INSTALACJA I BACKENDY

Instalujemy HAProxy na maszynie HAPROXY:

```bash
sudo apt install haproxy
haproxy -v
```

**Output:**
```
HAProxy version 2.8.5-1ubuntu3
```

Na BACKEND1 i BACKEND2 odpalamy prostą aplikację HTTP (setup.sh z repozytorium):

```bash
bash setup.sh
```

**Output:**
```
Backend działa na porcie 8080
Response from: backend1
```

Weryfikujemy z HAProxy że backendy odpowiadają:

```bash
curl 3.76.41.172:8080
curl 3.127.148.197:8080
```

**Output:**
```
Response from: backend1
Response from: backend2
```

Mamy dwa działające backendy.

> **Micro-hook:** *"Teraz piszemy config - to jedna sekcja i HAProxy zaczyna działać."*

---

### 2. KONFIGURACJA - haproxy.cfg

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

Zastępujemy domyślny config:

```
global
    log /dev/log local0
    maxconn 2000

defaults
    log     global
    mode    http
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend http_front
    bind *:80
    default_backend servers

backend servers
    balance roundrobin
    option httpchk GET /
    server backend1 3.76.41.172:8080 check
    server backend2 3.127.148.197:8080 check
```

`frontend http_front` - nasłuchuje na porcie 80, przekazuje ruch do backendu. `backend servers` - lista backendów. `balance roundrobin` - ruch rozłożony równomiernie, każde zapytanie idzie do kolejnego serwera. `option httpchk GET /` - health check: HAProxy co sekundę wysyła GET / do każdego backendu. `check` przy serwerze - włącza health check dla tego backendu.

```bash
sudo systemctl enable --now haproxy
sudo systemctl restart haproxy
sudo systemctl status haproxy
```

`restart` na końcu jest ważny - jeśli HAProxy już działał wcześniej (np. domyślny config po `apt install`), samo `enable --now` nie przeładuje nowego configu.

**Output:**
```
● haproxy.service - HAProxy Load Balancer
     Active: active (running)
```

Testujemy:

```bash
curl 3.120.244.170
curl 3.120.244.170
curl 3.120.244.170
curl 3.120.244.170
```

**Output:**
```
Response from: backend1
Response from: backend2
Response from: backend1
Response from: backend2
```

Ruch idzie na zmianę do obu backendów - ale to nie jest jeszcze failover.

> **Micro-hook:** *"Teraz zatrzymujemy jeden backend i patrzymy co robi HAProxy."*

---

### 3. FAILOVER - BACKEND PADA

Zatrzymujemy BACKEND1:

```bash
# Na BACKEND1
sudo pkill -f /tmp/app.py
```

Na HAProxy sprawdzamy status backendów przez stats socket:

```bash
echo "show servers state" | sudo socat stdio /run/haproxy/admin.sock
```

**Output:**
```
1 servers 2 backend1 3.76.41.172 8080 0 0 1 0 ... DOWN
1 servers 2 backend2 3.127.148.197 8080 1 1 1 0 ... UP
```

`DOWN` - HAProxy wykrył że backend1 nie odpowiada na health check. Pierwszy `curl` zaraz po padnięciu backendu może dostać `503 Service Unavailable` - health check jeszcze nie zdążył wykryć awarii (sprawdza co sekundę). Kolejne requesty już poprawnie omijają martwy backend:

```bash
curl 3.120.244.170
curl 3.120.244.170
curl 3.120.244.170
```

**Output:**
```
Response from: backend2
Response from: backend2
Response from: backend2
```

Żadnego błędu - użytkownik nie widzi że backend1 padł.

**[CTA #1]** *"Masz już load balancer w swoim środowisku? Napisz w komentarzu czego używasz. Jeśli film Ci się podoba - zostaw lajka."*

Przywracamy backend1:

```bash
# Na BACKEND1
bash setup.sh
```

```bash
curl 3.120.244.170
curl 3.120.244.170
curl 3.120.244.170
curl 3.120.244.170
```

**Output:**
```
Response from: backend2
Response from: backend1
Response from: backend2
Response from: backend1
```

HAProxy automatycznie wrócił do rozłożenia ruchu na oba backendy.

---

### PAYOFF

Jeden serwer pada - użytkownik nic nie widzi. HAProxy sprawdza backendy co sekundę i przełącza ruch automatycznie. Wraca - wchodzi z powrotem do rotacji. Bez ręcznej interwencji.

---

### OUTRO

Podmień IP backendów na swoje serwery - HAProxy działa tak samo dla Nginx, aplikacji Node, Pythona, czegokolwiek co odpowiada na HTTP.

**[CTA #2]** *"Masz kogoś kto traci czas na ręczne przełączanie serwisów gdy serwer pada - podeślij mu ten film."*
