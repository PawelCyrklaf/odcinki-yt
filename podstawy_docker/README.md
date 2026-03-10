# Docker — komendy z odcinka

## Instalacja

```bash
# Sprawdź czy Docker jest zainstalowany
docker --version

# Zainstaluj Docker
curl -fsSL https://get.docker.com | sh

# Sprawdź czy daemon działa
sudo systemctl status docker

# Dodaj użytkownika do grupy docker (nie używać sudo przy każdej komendzie)
sudo usermod -aG docker $USER

# Aktywuj grupę bez wylogowywania
newgrp docker
```

## Obrazy i kontenery

```bash
# Pobierz obraz z Docker Hub
docker pull ubuntu:24.04

# Wylistuj pobrane obrazy
docker images

# Uruchom kontener interaktywnie
docker run -it ubuntu:24.04 bash

# Uruchom kontener w tle z nazwą
docker run -d --name moj-nginx nginx

# Wylistuj działające kontenery
docker ps

# Wylistuj wszystkie kontenery (łącznie z zatrzymanymi)
docker ps -a

# Sprawdź logi kontenera
docker logs moj-nginx

# Śledź logi na żywo
docker logs -f moj-nginx

# Wejdź do działającego kontenera
docker exec -it moj-nginx bash

# Zatrzymaj i usuń kontener w jednym kroku
docker rm -f moj-nginx
```

## Dockerfile

```bash
# Zbuduj obraz z Dockerfile w bieżącym katalogu
docker build -t moja-app:1.0 .

# Uruchom kontener z mapowaniem portu (port-hosta:port-kontenera)
docker run -d --name moja-app -p 8080:8080 moja-app:1.0

# Sprawdź działanie aplikacji
curl localhost:8080
```

## Volumes

```bash
# Uruchom kontener z nazwanym volumenem
docker run -d --name postgres-db \
  -e POSTGRES_PASSWORD=haslo \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

# Wylistuj volumeny
docker volume ls

# Sprawdź szczegóły volumenu (m.in. gdzie na hoście są dane)
docker volume inspect pgdata
```

## Networking

```bash
# Wylistuj dostępne sieci
docker network ls

# Stwórz własną sieć
docker network create moja-siec

# Uruchom kontener w konkretnej sieci
docker run -d --name baza \
  --network moja-siec \
  -e POSTGRES_PASSWORD=haslo \
  postgres:16

# Sprawdź kontenery w sieci
docker network inspect moja-siec --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'

# Usuń sieć
docker network rm moja-siec
```

## docker-compose

```bash
# Uruchom całą aplikację z compose.yaml
docker compose up -d

# Zatrzymaj aplikację (volumeny zostają)
docker compose down

# Zatrzymaj aplikację i usuń volumeny
docker compose down -v
```

## Sprzątanie

```bash
# Usuń wszystkie zatrzymane kontenery, nieużywane obrazy i sieci
docker system prune -a

# Usuń też volumeny
docker system prune -a --volumes
```