# Nginx Virtual Hosts - Wszystkie Polecenia

## Sprawdzenie DNS

```bash
dig site1.cloud-devops.eu +short
dig site2.cloud-devops.eu +short
# Oba powinny pokazać IP Twojego serwera
```

## Utworzenie struktury katalogów

```bash
# Utwórz katalogi dla każdej strony
sudo mkdir -p /var/www/site1
sudo mkdir -p /var/www/site2

# Daj sobie dostęp
sudo chown -R $USER:$USER /var/www/site1
sudo chown -R $USER:$USER /var/www/site2
```

## Site 1 - Konfiguracja

### 1. Utwórz stronę HTML

```bash
nano /var/www/site1/index.html
```

### 2. Utwórz konfigurację Nginx

```bash
sudo nano /etc/nginx/sites-available/site1
```

Wklej:

```nginx
server {
    listen 80;
    listen [::]:80;
  
    server_name site1.cloud-devops.eu;
  
    root /var/www/site1;
    index index.html;
  
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 3. Aktywuj konfigurację

```bash
# Utwórz symlink
sudo ln -s /etc/nginx/sites-available/site1 /etc/nginx/sites-enabled/

# Sprawdź czy symlink istnieje
ls -la /etc/nginx/sites-enabled/

# Test składni
sudo nginx -t

# Przeładuj Nginx
sudo systemctl reload nginx
```

## Site 2 - Konfiguracja

### 1. Utwórz stronę HTML

```bash
nano /var/www/site2/index.html
```

### 2. Utwórz konfigurację Nginx

```bash
sudo nano /etc/nginx/sites-available/site2
```

Wklej:

```nginx
server {
    listen 80;
    listen [::]:80;
  
    server_name site2.cloud-devops.eu;
  
    root /var/www/site2;
    index index.html;
  
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 3. Aktywuj konfigurację

```bash
# Utwórz symlink
sudo ln -s /etc/nginx/sites-available/site2 /etc/nginx/sites-enabled/

# Test składni
sudo nginx -t

# Przeładuj Nginx
sudo systemctl reload nginx
```

## Osobne logi dla każdej strony (opcjonalnie)

### Site 1 - dodaj logi

```bash
sudo nano /etc/nginx/sites-available/site1
```

Dodaj po `server_name`:

```nginx
server {
    listen 80;
    server_name site1.cloud-devops.eu;
  
    # Osobne logi dla site1
    access_log /var/log/nginx/site1_access.log;
    error_log /var/log/nginx/site1_error.log;
  
    root /var/www/site1;
    index index.html;
  
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Site 2 - dodaj logi

```bash
sudo nano /etc/nginx/sites-available/site2
```

```nginx
server {
    listen 80;
    server_name site2.cloud-devops.eu;
  
    # Osobne logi dla site2
    access_log /var/log/nginx/site2_access.log;
    error_log /var/log/nginx/site2_error.log;
  
    root /var/www/site2;
    index index.html;
  
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Przeładuj konfigurację

```bash
# Test i reload
sudo nginx -t
sudo systemctl reload nginx
```

## Przeglądanie logów

```bash
# Zobacz logi site1
sudo tail -f /var/log/nginx/site1_access.log

# Zobacz logi site2
sudo tail -f /var/log/nginx/site2_access.log

# Logi błędów site1
sudo tail -f /var/log/nginx/site1_error.log

# Logi błędów site2
sudo tail -f /var/log/nginx/site2_error.log
```

## Przydatne polecenia

```bash
# Sprawdź status Nginx
sudo systemctl status nginx

# Restart Nginx
sudo systemctl restart nginx

# Stop Nginx
sudo systemctl stop nginx

# Start Nginx
sudo systemctl start nginx

# Sprawdź wszystkie aktywne strony
ls -la /etc/nginx/sites-enabled/

# Sprawdź wszystkie dostępne strony
ls -la /etc/nginx/sites-available/

# Usuń symlink (dezaktywuj stronę)
sudo rm /etc/nginx/sites-enabled/site1

# Sprawdź konfigurację główną Nginx
sudo nginx -T
```

## Testowanie w przeglądarce

```
http://site1.cloud-devops.eu
http://site2.cloud-devops.eu
```

## Troubleshooting

### Sprawdź logi błędów Nginx

```bash
sudo tail -f /var/log/nginx/error.log
```

### Sprawdź czy port 80 jest otwarty

```bash
sudo netstat -tlnp | grep :80
```

### Sprawdź czy Nginx działa

```bash
sudo systemctl status nginx
```

### Sprawdź składnię konfiguracji

```bash
sudo nginx -t
```

### Zobacz wszystkie procesy Nginx

```bash
ps aux | grep nginx
```
