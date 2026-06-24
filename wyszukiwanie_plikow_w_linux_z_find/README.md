# Linux find - komendy z odcinka

## Setup środowiska

```bash
#!/bin/bash
mkdir -p projekt/{logs,config,app/src,backup}

# Aktualne logi
echo "INFO: server started" > projekt/logs/app.log
echo "ERROR: connection timeout" > projekt/logs/error.log

# Stare logi
echo "INFO: old entry" > projekt/logs/app_old.log
touch -d "45 days ago" projekt/logs/app_old.log

echo "DEBUG: verbose output" > projekt/logs/debug_old.log
touch -d "60 days ago" projekt/logs/debug_old.log

# Config
echo "server_port=8080" > projekt/config/app.conf
echo "DB_PASSWORD=secret123" > projekt/config/.env
chmod 777 projekt/config/.env

# App
touch projekt/app/main.py
touch projekt/app/src/utils.py
touch projekt/app/src/helpers.py

# Duży plik
dd if=/dev/zero of=projekt/backup/dump.sql bs=1M count=100 2>/dev/null
touch -d "10 days ago" projekt/backup/dump.sql
echo "backup complete" > projekt/backup/backup.log

echo "Gotowe."
```

## Podstawy

```bash
# Listuje wszystko rekurencyjnie w katalogu
find <ścieżka>

# Szukaj plików po nazwie (wildcard *)
find <ścieżka> -name "*.log"

# Tylko pliki (nie katalogi)
find <ścieżka> -name "*.log" -type f

# Tylko katalogi
find <ścieżka> -type d
```

## Szukanie po czasie modyfikacji

```bash
# Pliki starsze niż 30 dni
find <ścieżka> -mtime +30

# Pliki nowsze niż 7 dni
find <ścieżka> -mtime -7

# Stare logi konkretnego typu
find <ścieżka> -name "*.log" -mtime +30
```

## Szukanie po rozmiarze

```bash
# Pliki większe niż 50 MB
find <ścieżka> -size +50M

# Pliki większe niż 1 GB
find <ścieżka> -size +1G

# Pliki mniejsze niż 1 KB (puste pliki)
find <ścieżka> -size -1k

# Duże pliki starsze niż 7 dni
find <ścieżka> -size +50M -mtime +7
```

## Szukanie po uprawnieniach

```bash
# Pliki z uprawnieniami 777
find <ścieżka> -perm 777
```

## Wykonanie akcji na wynikach (-exec)

```bash
# Wyświetl szczegóły znalezionych plików
find <ścieżka> -mtime +30 -exec ls -lh {} \;

# Usuń znalezione pliki
find <ścieżka> -name "*.log" -mtime +30 -exec rm {} \;
```
