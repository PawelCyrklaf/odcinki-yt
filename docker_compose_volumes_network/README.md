# Docker ep.2 — komendy z opisem

---

## Setup aplikacji demo

```bash
mkdir docker-demo && cd docker-demo
```
Tworzy katalog roboczy dla demo.

### app.py

```python
from flask import Flask, request, jsonify
import psycopg2, os

app = Flask(__name__)

def get_conn():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"]
    )

@app.route("/")
def notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS notes (id SERIAL, content TEXT)")
    conn.commit()
    cur.execute("SELECT id, content FROM notes")
    rows = cur.fetchall()
    conn.close()
    return jsonify(rows)

@app.route("/add", methods=["POST"])
def add():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO notes (content) VALUES (%s)", (request.json["content"],))
    conn.commit()
    conn.close()
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

### Dockerfile

```dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN pip install flask psycopg2-binary
COPY app.py .
CMD ["python", "app.py"]
```

### compose.yaml (wersja początkowa — bez volumenu)

```yaml
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      DB_HOST: db
      DB_NAME: notes
      DB_USER: postgres
      DB_PASSWORD: haslo

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: notes
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: haslo
```

```bash
docker compose up -d
```
Uruchamia stack w tle (app + db).

```bash
curl localhost:5000
```
Sprawdza czy aplikacja odpowiada. Oczekiwany wynik: `[]`

```bash
curl -X POST localhost:5000/add \
  -H "Content-Type: application/json" \
  -d '{"content": "moja pierwsza notatka"}'

curl localhost:5000
```
Dodaje notatkę i weryfikuje że jest w bazie. Oczekiwany wynik: `[[1, "moja pierwsza notatka"]]`

---

## Problem — dane znikają

```bash
docker compose down
docker compose up -d
curl localhost:5000
```
Symuluje aktualizację aplikacji. Po `down` + `up` dane znikają — oczekiwany wynik: `[]`

```bash
docker volume ls
```
Pokazuje listę volumenów. Bez named volume widać wolumen z losowym hashem (anonimowy) — Docker nie wie który przypisać do nowego kontenera.

---

## Named volumes — naprawienie problemu

### compose.yaml (z named volume)

```yaml
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      DB_HOST: db
      DB_NAME: notes
      DB_USER: postgres
      DB_PASSWORD: haslo

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: notes
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: haslo
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

```bash
docker compose up -d

curl -X POST localhost:5000/add \
  -H "Content-Type: application/json" \
  -d '{"content": "ta notatka przeżyje restart"}'
```
Uruchamia stack z named volume i dodaje testową notatkę.

```bash
docker volume ls
```
Weryfikuje że `docker-demo_pgdata` istnieje. Czytelna nazwa zamiast losowego hasha.

```bash
docker volume inspect docker-demo_pgdata
```
Pokazuje gdzie na hoście Docker przechowuje dane volumenu (`/var/lib/docker/volumes/docker-demo_pgdata/_data`). Tego katalogu nie ruszasz ręcznie — zarządzasz przez `docker volume` komendy.

```bash
docker compose down
docker compose up -d
curl localhost:5000
```
Symuluje restart. Dane powinny przeżyć — oczekiwany wynik: `[[1, "ta notatka przeżyje restart"]]`

```bash
# To zostawia dane:
docker compose down

# To usuwa WSZYSTKO łącznie z named volumes:
docker compose down -v
```
`down` bez `-v` — usuwa kontenery i sieci, **nie usuwa named volumes**. `down -v` — usuwa wszystko. Nigdy na produkcji bez świadomej decyzji.

---

## Bind mounts — development workflow

### compose.yaml (z bind mount dla app)

```yaml
  app:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - ./app.py:/app/app.py
    environment:
      DB_HOST: db
      DB_NAME: notes
      DB_USER: postgres
      DB_PASSWORD: haslo
```

```bash
docker compose up -d
```
Montuje lokalny `app.py` do kontenera — zmiany w pliku na hoście są natychmiast widoczne w kontenerze.

### app.py (zaktualizowana wersja z licznikiem)

```python
@app.route("/")
def notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS notes (id SERIAL, content TEXT)")
    conn.commit()
    cur.execute("SELECT id, content FROM notes")
    rows = cur.fetchall()
    conn.close()
    return jsonify({"notes": rows, "total": len(rows)})
```

```bash
docker compose restart app
curl localhost:5000
```
Po zmianie w lokalnym `app.py` — restartuje tylko serwis app. Zmiana widoczna bez `docker build`.
Oczekiwany wynik: `{"notes": [[1, "ta notatka przeżyje restart"]], "total": 1}`

---

## Sieć — jak kontenery rozmawiają

```bash
docker network inspect docker-demo_default \
  --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
```
Wyświetla nazwy kontenerów i ich adresy IP w sieci. Pokazuje że oba kontenery są w tej samej sieci.

```bash
docker exec -it docker-demo-app-1 bash
```
Wchodzi do kontenera app interaktywnie.

```bash
apt-get update && apt-get install -y iputils-ping
ping db
```
Wewnątrz kontenera: instaluje ping i sprawdza że nazwa `db` (serwis z compose.yaml) rozwiązuje się na IP kontenera bazy. Docker ma wbudowany DNS na `127.0.0.11`.

```bash
cat /etc/resolv.conf
```
Wewnątrz kontenera: pokazuje `nameserver 127.0.0.11` — wbudowany DNS Docker.

```bash
exit
```
Wychodzi z kontenera.

---

## Compose best practices

### .env

```
POSTGRES_PASSWORD=haslo
DB_PASSWORD=haslo
DB_NAME=notes
DB_USER=postgres
```
Hasła i konfiguracja poza `compose.yaml`. Plik trafia na serwer, nie do repozytorium. W repo trzymasz `.env.example` z kluczami ale bez wartości.

```bash
echo ".env" >> .gitignore
```
Dodaje `.env` do gitignore — hasła nie trafiają do repozytorium.

### compose.yaml (z .env i restart policy)

```yaml
services:
  app:
    build: .
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - ./app.py:/app/app.py
    environment:
      DB_HOST: db
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

- `restart: unless-stopped` — Docker restartuje kontener gdy padnie, ale nie rusza gdy ręcznie zatrzymasz przez `docker compose stop`.

```bash
docker compose config
```
Pokazuje finalny `compose.yaml` z podstawionymi zmiennymi z `.env`. Używaj przed uruchomieniem na produkcji żeby zweryfikować poprawność.

---

## Update kontenera bez utraty danych

```bash
# NIE RÓB TEGO — down -v usuwa named volumes razem z danymi bazy
docker compose down -v
docker compose up -d
```

```bash
# Pobierz nowe obrazy (dla serwisów z image:)
docker compose pull

# Przebuduj własny obraz
docker compose build app

# Zastąp tylko kontener app — db zostaje nienaruszony
docker compose up -d --no-deps app
```
`--no-deps` — aktualizuje tylko wskazany serwis bez zatrzymywania zależności. Kontener `db` nie jest ruszany, dane bezpieczne.

```bash
curl localhost:5000
```
Weryfikuje że dane są po aktualizacji — oczekiwany wynik: `{"notes": [[1, "ta notatka przeżyje restart"]], "total": 1}`

---

## Sprzątanie

```bash
# Usuń kontenery i sieci (dane zostają)
docker compose down

# Usuń kontenery, sieci i named volumes
docker compose down -v

# Usuń wszystkie nieużywane zasoby Dockera (obrazy, sieci, kontenery, volumeny)
docker system prune -a --volumes
```