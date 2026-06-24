# Linux find - komendy z odcinka

## Setup środowiska

```bash
bash setup.sh
```

**setup.sh** tworzy katalog `projekt/` z logami, configami i dużym plikiem do ćwiczeń.

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
