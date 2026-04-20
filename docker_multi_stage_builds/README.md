# Docker multi-stage build — komendy z odcinka

## Pliki projektu

`app.py`
```python
from flask import Flask, jsonify

app = Flask(__name__)
app.json.ensure_ascii = False

@app.route("/")
def index():
    return jsonify({"status": "ok", "message": "działa"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

`requirements.txt`
```
flask==3.0.3
```

---

## 1. Standardowy obraz — problem

`Dockerfile.heavy`
```dockerfile
FROM python:3.12
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

Zbuduj standardowy obraz:
```bash
docker build -t myapp:heavy .
```

Sprawdź rozmiar — ponad 1GB dla 30 linii kodu:
```bash
docker images myapp:heavy
```

Sprawdź skąd pochodzi ten gigabajt — cały siedzi w `/usr`, kompilatory i nagłówki których Flask nie potrzebuje:
```bash
docker run --rm myapp:heavy du -sh /* 2>/dev/null
```

---

## 2. Multi-stage build — rozwiązanie

`Dockerfile`

Stage 1: builder — instaluje zależności, nigdy nie trafi do finalnego obrazu:
```dockerfile
FROM python:3.12 AS builder
WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install -r requirements.txt
```

Stage 2: runtime — tylko to co potrzebne do uruchomienia aplikacji:
```dockerfile
FROM python:3.12-slim
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /app
COPY . .
CMD ["python", "app.py"]
```

Zbuduj obraz i porównaj rozmiary — ~1.1GB vs ~200MB, ta sama aplikacja:
```bash
docker build -t myapp:multistage .
docker images myapp
```

Sprawdź że pakiety działają i uruchom aplikację:
```bash
docker run --rm myapp:multistage python -c "import flask; print('flask OK')"
docker run -d -p 5000:5000 myapp:multistage
curl localhost:5000
```

---

## 3. .dockerignore — hasła w obrazie

Symulacja typowego projektu z plikiem `.env`:
```bash
echo "SECRET_KEY=superhaslo123" > .env
echo "DB_PASSWORD=produkcja456" >> .env
```

Zbuduj obraz bez `.dockerignore` i udowodnij że hasła są w środku — każdy z dostępem do registry może to zrobić:
```bash
docker build -t myapp:leak .
docker run --rm myapp:leak find /app -name ".*" 2>/dev/null
docker run --rm myapp:leak cat /app/.env
```

Utwórz `.dockerignore` obok Dockerfile:
```
.env
.env.*
.git
.gitignore
*.md
tests/
.pytest_cache
.dockerignore
```

Zbuduj czysty obraz i sprawdź że `.env` zniknął:
```bash
docker build -t myapp:clean .
docker run --rm myapp:clean find /app -name ".*" 2>/dev/null
```

`leak` i `clean` ważą tyle samo — `.dockerignore` to kwestia bezpieczeństwa, nie rozmiaru:
```bash
docker images myapp
```