# Nginx SSL/HTTPS + Let's Encrypt - Polecenia

## Sprawdzenie DNS

```bash
# Opcja 1 - dig
dig cloud-devops.eu +short

# Opcja 2 - nslookup
nslookup cloud-devops.eu

# Sprawdź IP swojego serwera
curl ifconfig.me
```

---

## Sprawdzenie firewall i portów

```bash
# Sprawdź status firewall
sudo ufw status

# Otwórz porty dla Nginx (80 i 443)
sudo ufw allow 'Nginx Full'

# Sprawdź czy Nginx działa
nginx -v
sudo systemctl status nginx
```

---

## Quick check przed instalacją

```bash
# 1. Masz Nginx?
nginx -v

# 2. Twoja domena działa?
curl http://cloud-devops.eu
```

---

## Instalacja Certbot

```bash
# Aktualizacja systemu
sudo apt update

# Instalacja Certbot i plugin dla Nginx
sudo apt install certbot python3-certbot-nginx -y

# Sprawdź wersję
certbot --version
```

---

## Uzyskanie certyfikatu SSL

```bash
# Wygeneruj certyfikat dla jednej lub wielu domen
sudo certbot --nginx -d cloud-devops.eu -d www.cloud-devops.eu

# Dla pojedynczej domeny
sudo certbot --nginx -d cloud-devops.eu
```

**Podczas instalacji:**
- Podaj email (dostaniesz powiadomienie o wygaśnięciu)
- Zaakceptuj Terms of Service: `A`
- Newsletter (opcjonalnie): `N`

---

## Sprawdzenie konfiguracji Nginx

```bash
# Zobacz co Certbot zmienił
sudo cat /etc/nginx/sites-available/default

# Sprawdź certyfikaty
sudo ls -la /etc/letsencrypt/live/cloud-devops.eu/

# Test składni Nginx
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

---

## Automatyczne odnawianie

```bash
# Sprawdź czy auto-renewal jest skonfigurowany
systemctl list-timers | grep certbot

# Test odnowienia (dry run - nie odnawia naprawdę)
sudo certbot renew --dry-run

# Ręczne odnowienie (jeśli potrzebne)
sudo certbot renew

# Sprawdź status certyfikatu
sudo certbot certificates
```

---

## Troubleshooting

### Problem z DNS
```bash
# Sprawdź DNS
dig twoja-domena.pl +short

# Poczekaj 15-30 minut na propagację
```

### Problem z portem 80
```bash
# Sprawdź co słucha na porcie 80
sudo netstat -tulpn | grep :80

# lub
sudo ss -tulpn | grep :80

# Sprawdź logi Nginx
sudo tail -f /var/log/nginx/error.log
```

### Problem z Certbot
```bash
# Sprawdź logi Let's Encrypt
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Lista zainstalowanych certyfikatów
sudo certbot certificates

# Usuń certyfikat (jeśli coś poszło nie tak)
sudo certbot delete --cert-name cloud-devops.eu
```

### Mixed Content Warning
```bash
# Znajdź pliki z http:// w HTML
grep -r "http://" /var/www/

# Zamień http:// na https:// w plikach
# (ostrożnie z tym poleceniem!)
find /var/www/ -type f -exec sed -i 's|http://|https://|g' {} +
```

---

## Przydatne polecenia

```bash
# Sprawdź datę wygaśnięcia certyfikatu
sudo certbot certificates

# Odśwież konfigurację Nginx bez restartu
sudo systemctl reload nginx

# Sprawdź wszystkie certyfikaty Let's Encrypt
sudo ls /etc/letsencrypt/live/

# Backup konfiguracji Nginx (przed zmianami)
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Przywróć backup
sudo cp /etc/nginx/sites-available/default.backup /etc/nginx/sites-available/default
```

---

## Testowanie z flagą --staging

```bash
# Użyj staging environment do testów (nie liczy się do rate limit)
sudo certbot --nginx -d test.cloud-devops.eu --staging

# Usuń staging certyfikat po teście
sudo certbot delete --cert-name test.cloud-devops.eu
```

---

## Rate limit Let's Encrypt

**Limity:**
- 50 certyfikatów na domenę na tydzień
- 5 duplikatów certyfikatu na tydzień

**Jak uniknąć:**
- Używaj `--staging` do testów
- Nie uruchamiaj certbot wiele razy pod rząd
- Najpierw diagnozuj problem, potem naprawiaj

---

## SSL Labs Test

**Manualnie w przeglądarce:**
1. Otwórz: https://www.ssllabs.com/ssltest/
2. Wpisz swoją domenę
3. Kliknij "Submit"
4. Poczekaj ~2 minuty na wynik

**Oczekiwany wynik:** Rating A lub A+

---

## Dodatkowe polecenia bezpieczeństwa

```bash
# Sprawdź wersję TLS
openssl s_client -connect cloud-devops.eu:443 -tls1_2

# Sprawdź certyfikat z linii poleceń
echo | openssl s_client -connect cloud-devops.eu:443 2>/dev/null | openssl x509 -noout -dates

# Test przekierowania HTTP → HTTPS
curl -I http://cloud-devops.eu
# Powinno pokazać: HTTP/1.1 301 Moved Permanently
# Location: https://cloud-devops.eu/
```

---

## Dezinstalacja / Czyszczenie

```bash
# Usuń certyfikat
sudo certbot delete --cert-name cloud-devops.eu

# Odinstaluj Certbot
sudo apt remove certbot python3-certbot-nginx -y

# Usuń wszystkie pliki Let's Encrypt
sudo rm -rf /etc/letsencrypt/
sudo rm -rf /var/log/letsencrypt/
```

---

## Przydatne ścieżki

```
/etc/nginx/sites-available/default       # Główna konfiguracja Nginx
/etc/nginx/sites-enabled/default         # Aktywna konfiguracja (symlink)
/etc/letsencrypt/live/DOMENA/            # Certyfikaty SSL
/etc/letsencrypt/renewal/                # Konfiguracja auto-renewal
/var/log/letsencrypt/letsencrypt.log     # Logi Certbot
/var/log/nginx/error.log                 # Logi błędów Nginx
/var/log/nginx/access.log                # Logi dostępu Nginx
```

---

## Szybkie przypomnienie - cały proces

```bash
# 1. Sprawdź DNS
dig twoja-domena.pl +short

# 2. Zainstaluj Certbot
sudo apt update && sudo apt install certbot python3-certbot-nginx -y

# 3. Wygeneruj certyfikat
sudo certbot --nginx -d twoja-domena.pl -d www.twoja-domena.pl

# 4. Test auto-renewal
sudo certbot renew --dry-run

# 5. Sprawdź na SSL Labs
# https://www.ssllabs.com/ssltest/

# GOTOWE! 🎉
```
