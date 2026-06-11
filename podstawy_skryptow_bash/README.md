# Bash scripting — lista wszystkich poleceń z odcinka

## Skrypt startowy (z poprzedniego odcinka)

```bash
#!/bin/bash

URL=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
  | jq -r '.assets[] | select(.name | endswith("Linux_amd64.tar.gz")) | .browser_download_url')

wget -q -O k9s.tar.gz "$URL"
echo "Gotowe"
```

## set -euo pipefail

```bash
# Zatrzymaj skrypt gdy komenda zwróci błąd
set -e

# Zatrzymaj skrypt gdy użyjesz niezdefiniowanej zmiennej
set -u

# Zatrzymaj gdy padnie cokolwiek w potoku, nie tylko ostatnia komenda
set -o pipefail

# Wszystkie trzy razem — zawsze używaj na górze skryptu
set -euo pipefail
```

## Logging

```bash
# Wyświetl aktualny czas w formacie timestamp
date '+%Y-%m-%d %H:%M:%S'

# Funkcja logująca — wypisuje na stdout i dopisuje do pliku
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# tee -a — wypisz na stdout i dopisz do pliku (-a = append, nie nadpisuj)
echo "tekst" | tee -a /var/log/skrypt.log
```

## trap

```bash
# Wykonaj komendę gdy skrypt napotka błąd
trap 'log "ERROR: skrypt padł w linii $LINENO"' ERR

# $LINENO — numer linii w której aktualnie jest wykonywany skrypt
echo "jestem w linii $LINENO"
```

## Sprawdzanie wersji

```bash
# Pobierz najnowszy tag wersji z GitHub API
curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
  | jq -r '.tag_name'

# Sprawdź zainstalowaną wersję — ukryj błędy jeśli narzędzie nie istnieje
k9s version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "not installed"

# 2>/dev/null — przekieruj stderr do kosza (ukryj błędy)
# grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' — wyciągnij numer wersji z tekstu
# || echo "not installed" — fallback gdy poprzednia komenda padnie
```

## Pobieranie i instalacja

```bash
# Pobierz plik i zapisz pod podaną nazwą (-q = bez outputu)
wget -q -O k9s.tar.gz "$URL"

# Rozpakuj tylko binarкę k9s, nie cały archiwum
tar -xzf k9s.tar.gz k9s

# Przenieś binarкę do /usr/local/bin żeby była dostępna w PATH
mv k9s /usr/local/bin/k9s

# Usuń archiwum po rozpakowaniu
rm k9s.tar.gz
```

## Pełny skrypt

```bash
#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/k9s-update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

trap 'log "ERROR: skrypt padł w linii $LINENO"' ERR

log "Sprawdzam wersję k9s..."

LATEST=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
    | jq -r '.tag_name')
INSTALLED=$(k9s version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "not installed")

log "Zainstalowana: ${INSTALLED} | Najnowsza: ${LATEST}"

if [[ "$INSTALLED" == "$LATEST" ]]; then
    log "Już aktualne — nic do roboty."
    exit 0
fi

log "Pobieram URL..."
URL=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
    | jq -r '.assets[] | select(.name | endswith("Linux_amd64.tar.gz")) | .browser_download_url')

log "Pobieram k9s..."
wget -q -O k9s.tar.gz "$URL"
tar -xzf k9s.tar.gz k9s
mv k9s /usr/local/bin/k9s
rm k9s.tar.gz

log "Gotowe — k9s zaktualizowany do ${LATEST}"
```

## Ściągawka

```bash
set -euo pipefail              # zabezpieczenie — zawsze na górze skryptu
trap '...' ERR                 # łap błędy i raportuj
date '+%Y-%m-%d %H:%M:%S'     # timestamp do logów
tee -a plik.log                # wypisz na stdout i dopisz do pliku
2>/dev/null                    # ukryj błędy
|| fallback                    # wykonaj jeśli poprzednia komenda padła
$LINENO                        # numer aktualnej linii skryptu
```