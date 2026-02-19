# Nginx Cache i Gzip - Polecenia i skrypty

## Gzip

```bash
# Edytuj główny config Nginx
nano /etc/nginx/nginx.conf
```

```nginx
# Dodaj w sekcji http {
# Domyślnie Nginx kompresuje tylko text/html - tu dodajemy pozostałe typy
http {
  gzip on;
  gzip_vary on;        # Dodaje header Vary: Accept-Encoding (ważne dla proxy)
  gzip_proxied any;    # Kompresuj też gdy między klientem a Nginx jest proxy
  gzip_comp_level 6;   # Poziom kompresji: 1=szybko/słabo, 9=wolno/mocno, 6=sweet spot
  gzip_types text/plain text/css text/xml text/javascript
    application/json application/javascript application/xml+rss
    application/atom+xml image/svg+xml;
}
```

```bash
# Sprawdź czy config jest poprawny
nginx -t

# Przeładuj Nginx bez restartu (zero downtime)
systemctl reload nginx
```

```bash
# Sprawdź czy gzip jest już włączony (Ubuntu ma gzip on domyślnie)
nginx -T | grep gzip
```

```bash
# Porównaj rozmiar odpowiedzi bez i z gzip
echo "=== BEZ gzip ===" && \
curl -s -o /dev/null -w "Rozmiar: %{size_download} bajtów\n" http://localhost/big.html && \
echo "=== Z gzip ===" && \
curl -s -H "Accept-Encoding: gzip" -o /dev/null -w "Rozmiar: %{size_download} bajtów\n" http://localhost/big.html
```

```bash
# Sprawdź headery odpowiedzi - szukaj Content-Encoding: gzip
curl -I http://localhost/big.html
curl -H "Accept-Encoding: gzip" -I http://localhost/big.html
```

---

## Proxy Cache

```bash
# Utwórz katalog z plikiem HTML dla backendu testowego
mkdir -p ~/backend-cache
cd ~/backend-cache
nano index.html
```

```bash
# Uruchom prosty serwer HTTP jako backend - od razu w tle przez screen
# -dm = detached mode (nie wchodzi do sesji), -S = nazwa sesji
screen -dmS backend bash -c 'cd ~/backend-cache && python3 -m http.server 8000'
```

```bash
# Sprawdź czy backend odpowiada
curl localhost:8000
```

```bash
# Edytuj główny config - tu definiujemy gdzie trzymać cache
nano /etc/nginx/nginx.conf
```

```nginx
# Dodaj w sekcji http {, przed server {
http {
  proxy_cache_path /var/cache/nginx/proxy  # gdzie trzymać pliki cache na dysku
    levels=1:2                              # struktura podkatalogów (optymalizacja I/O)
    keys_zone=my_cache:10m                  # nazwa cache + 10MB RAM na indeks kluczy
    max_size=1g                             # maksymalny rozmiar cache na dysku
    inactive=60m;                           # usuń wpis jeśli nie używany przez 60 minut
}
```

```bash
# Utwórz katalog cache - Nginx nie zrobi tego sam!
mkdir -p /var/cache/nginx/proxy

# Ustaw właściciela - Nginx działa jako www-data
chown www-data:www-data /var/cache/nginx/proxy
```

```bash
# Edytuj konfigurację vhosta
nano /etc/nginx/sites-available/default
```

```nginx
server {
  listen 80;
  server_name _;

  location / {
    proxy_pass http://localhost:8000;   # przekaż request do backendu

    proxy_cache my_cache;               # użyj cache zdefiniowanego w http {}
    proxy_cache_valid 200 10m;          # cachuj odpowiedzi 200 OK przez 10 minut

    add_header X-Cache-Status $upstream_cache_status;  # HIT/MISS/BYPASS w headerach

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

```bash
nginx -t
systemctl reload nginx
```

---

## Czyszczenie cache

```bash
# Wyczyść cały cache (np. po deployu nowej wersji aplikacji)
rm -rf /var/cache/nginx/proxy/*
systemctl reload nginx
```

```nginx
# Dodaj w location {} żeby requesty z Cache-Control: no-cache omijały cache
proxy_cache_bypass $http_cache_control;
```

---

## Generator pliku testowego

```bash
# Użycie - domyślnie generuje 350KB
python3 generate-index.py

# Własny rozmiar i ścieżka
python3 generate-index.py --size 400 --output /var/www/html/index.html
```

```python
#!/usr/bin/env python3
import random
import argparse

lorem = ('Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor '
         'incididunt ut labore et dolore magna aliqua Ut enim ad minim veniam quis nostrud '
         'exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat Duis aute '
         'irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
         'pariatur Excepteur sint occaecat cupidatat non proident sunt in culpa qui officia '
         'deserunt mollit anim id est laborum').split()

def para():
    words = [random.choice(lorem) for _ in range(random.randint(40, 80))]
    return ' '.join(words).capitalize() + '.'

parser = argparse.ArgumentParser(description='Generator pliku HTML do testów Nginx cache')
parser.add_argument('--size', type=int, default=350, help='Docelowy rozmiar w KB (domyślnie: 350)')
parser.add_argument('--output', type=str, default='index.html', help='Nazwa pliku wyjściowego')
args = parser.parse_args()

sections_count = int(args.size * 1024 / 1600)

sections = []
for i in range(sections_count):
    heading = f'<h2>Section {i+1}: {random.choice(lorem).capitalize()} {random.choice(lorem)}</h2>'
    paragraphs = ''.join(f'<p>{para()}</p>' for _ in range(4))
    sections.append(f'<div class="section">{heading}{paragraphs}</div>')

html = f'''<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Demo strona - Nginx Cache Test</title>
  <style>
    body {{ font-family: Arial, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; color: #333; }}
    h1 {{ color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }}
    h2 {{ color: #34495e; margin-top: 30px; }}
    p {{ line-height: 1.7; margin-bottom: 12px; }}
    .section {{ background: #f9f9f9; border-left: 4px solid #3498db; padding: 15px 20px; margin-bottom: 20px; border-radius: 4px; }}
    .intro {{ background: #eaf4fb; padding: 20px; border-radius: 6px; margin-bottom: 30px; }}
  </style>
</head>
<body>
  <h1>Demo strona - Nginx Cache Test</h1>
  <div class="intro">
    <p>Ta strona służy do demonstracji działania Nginx Proxy Cache.</p>
  </div>
  {''.join(sections)}
</body>
</html>'''

with open(args.output, 'w') as f:
    f.write(html)

size = len(html.encode('utf-8'))
print(f'Wygenerowano: {args.output} ({size / 1024:.1f} KB)')
```