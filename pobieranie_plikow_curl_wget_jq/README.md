# curl, wget i jq - komendy z odcinka

## curl

Podstawowy GET request - curl wypisuje body odpowiedzi na stdout:

```bash
curl https://ipinfo.io/json
```

Flaga `-s` wycisza progress bar - w skryptach obowiązkowa, inaczej logi są zaśmiecone:

```bash
curl -s https://ipinfo.io/json
```

Sprawdź czy endpoint żyje bez pobierania body. `-o /dev/null` wyrzuca body, `-w "%{http_code}"` zostawia tylko status kod:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://ipinfo.io/json
```

HEAD request - same nagłówki odpowiedzi, zero body. Przydatne do sprawdzenia limitów API:

```bash
curl -s -I https://api.github.com/repos/derailed/k9s/releases/latest
```

---

## jq

Wyciągnij jedno pole z JSON. Bez `-r` wartość ma cudzysłowy - z `-r` je usuwa. Przy przypisaniu do zmiennej zawsze używaj `-r`:

```bash
curl -s https://ipinfo.io/json | jq -r '.ip'
```

Wyciągnij kilka pól jednocześnie - reszta odpowiedzi znika:

```bash
curl -s https://ipinfo.io/json | jq '{ip, hostname, city}'
```

Pobierz tag najnowszej wersji z GitHub API:

```bash
curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
  | jq -r '.tag_name'
```

Wyciągnij URL do pobrania z listy assets. `endswith` zamiast `contains` - żeby nie złapać plików z podobną nazwą:

```bash
curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
  | jq -r '.assets[] | select(.name | endswith("Linux_amd64.tar.gz")) | .browser_download_url'
```

---

## wget

Pobierz plik i zapisz pod stałą nazwą. `-q` wycisza output, `-O` ustawia nazwę niezależnie od wersji w URL:

```bash
wget -q -O k9s.tar.gz "$URL"
```

`-c` wznawia przerwany download od miejsca gdzie skończył:

```bash
wget -c -q -O k9s.tar.gz "$URL"
```

---

## Pipeline - skrypt który zawsze pobiera latest

```bash
URL=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
  | jq -r '.assets[] | select(.name | endswith("Linux_amd64.tar.gz")) | .browser_download_url')

wget -q -O k9s.tar.gz "$URL"
```