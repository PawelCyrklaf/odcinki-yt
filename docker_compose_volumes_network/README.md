# Docker ep.2 — komendy z opisem

---

## Setup aplikacji demo

```bash
mkdir docker-demo && cd docker-demo
```
Tworzy katalog roboczy dla demo.

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
```
Dodaje notatkę do bazy przez API.

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

```bash
docker compose up -d
```
Po dodaniu `pgdata:/var/lib/postgresql/data` do `compose.yaml` — uruchamia stack z named volume.

```bash
docker volume ls
```
Weryfikuje że `docker-demo_pgdata` istnieje. Czytelna nazwa zamiast losowego hasha.

```bash
docker volume inspect docker-demo_pgdata
```
Pokazuje gdzie na hoście Docker przechowuje dane volumenu (`/var/lib/docker/volumes/docker-demo_pgdata/_data`).

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

```bash
docker compose up -d
```
Po dodaniu `./app.py:/app/app.py` do serwisu app — montuje lokalny plik kodu do kontenera.

```bash
docker compose restart app
curl localhost:5000
```
Po zmianie w lokalnym `app.py` — restartuje tylko serwis app. Zmiana widoczna bez `docker build`.

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

### Zmienne środowiskowe przez .env

```bash
echo ".env" >> .gitignore
```
Dodaje `.env` do gitignore — hasła nie trafiają do repozytorium.

```bash
docker compose config
```
Pokazuje finalny `compose.yaml` z podstawionymi zmiennymi z `.env`. Używaj przed uruchomieniem na produkcji żeby zweryfikować że wszystko się poprawnie podstawiło.

### depends_on z healthcheck

```bash
docker compose down
docker compose up -d
```
Po dodaniu healthcheck do `db` i `depends_on: condition: service_healthy` do `app` — uruchamia stack. App wystartuje dopiero gdy postgres odpowie na `pg_isready`.

Oczekiwany wynik:
```
✔ Container docker-demo-db-1   Healthy
✔ Container docker-demo-app-1  Started
```

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