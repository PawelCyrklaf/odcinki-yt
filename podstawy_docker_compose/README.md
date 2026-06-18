# Docker Compose - komendy z odcinka

---

## Setup projektu

```bash
mkdir docker-demo && cd docker-demo
```

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
    conn = get_conn()
    conn.close()
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

---

## 1. Pierwszy compose.yaml - jeden serwis

```yaml
services:
  app:
    build: .
    ports:
      - "5000:5000"
```

```bash
docker compose up -d
```
Uruchamia stack w tle. Compose automatycznie tworzy sieć - nie musisz robić `docker network create`.

```bash
docker compose down
```
Usuwa kontenery i sieć.

---

## 2. Drugi serwis - baza danych

```yaml
services:
  app:
    build: .
    ports:
      - "5000:5000"
    depends_on:
      - db
    environment:
      DB_HOST: db
      DB_NAME: notes
      DB_USER: postgres
      DB_PASSWORD: tajnehaslo123

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: notes
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: tajnehaslo123
```

```bash
docker compose up -d
```
Uruchamia oba kontenery we właściwej kolejności. `DB_HOST: db` - `db` to nazwa serwisu i jednocześnie hostname w sieci compose.

```bash
docker compose exec db psql -U postgres -c "\l"
```
Wchodzi do bazy i listuje bazy danych. Nie musisz szukać ID przez `docker ps` - wystarczy nazwa serwisu.

---

## 3. Healthcheck - czekaj aż baza jest gotowa

`depends_on` uruchamia `db` przed `app`, ale nie czeka aż PostgreSQL skończy inicjalizację:

```bash
docker compose down
docker compose up -d
docker compose ps
```

```bash
docker compose logs app
```
Pokazuje błąd połączenia: `psycopg2.OperationalError: connection refused` - kontener `app` restaruje bo baza jeszcze nie gotowa.

```yaml
services:
  app:
    build: .
    ports:
      - "5000:5000"
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_HOST: db
      DB_NAME: notes
      DB_USER: postgres
      DB_PASSWORD: tajnehaslo123

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: notes
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: tajnehaslo123
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5
```

```bash
docker compose up -d --wait
```
`--wait` - compose czeka aż wszystkie healthchecki przejdą zanim wróci do terminala. Przydatne w CI/CD.

```bash
docker compose ps
```
Oczekiwany wynik: `docker-demo-db-1 running (healthy)`, `docker-demo-app-1 running`.

---

## 4. .env - sekrety poza plikiem

### .env

```
DB_PASSWORD=tajnehaslo123
```

### .gitignore

```
.env
```

```yaml
services:
  app:
    build: .
    ports:
      - "5000:5000"
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_HOST: db
      DB_NAME: notes
      DB_USER: postgres
      DB_PASSWORD: ${DB_PASSWORD}
    restart: unless-stopped

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: notes
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5
```

```bash
docker compose config
```
Weryfikuje że zmienne z `.env` podstawiają się poprawnie - bez uruchamiania kontenerów.

```bash
docker compose up -d --wait
```

---

## 5. Komendy których będziesz używać codziennie

Dodaj endpoint do `app.py`:

```python
@app.route("/health")
def health():
    return jsonify({"status": "ok"})
```

```bash
docker compose up -d --build app
```
Przebudowuje tylko `app` - `db` chodzi dalej bez restartu.

```bash
curl localhost:5000/health
```
Oczekiwany wynik: `{"status": "ok"}`

```bash
docker compose logs -f
```
Logi na żywo ze wszystkich serwisów. `Ctrl+C` odpina terminal, kontenery chodzą dalej.

```bash
docker compose stop
docker compose start
```
Restart bez utraty danych - nie usuwa kontenerów ani wolumenów, szybsze niż `down`/`up`.

```bash
docker compose run --rm app python -c "from app import get_conn; print(get_conn())"
```
Jednorazowa komenda w kontenerze - migracje, debug, seed danych. `--rm` usuwa kontener po zakończeniu.

```bash
docker compose down
```
Usuwa kontenery i sieć.
