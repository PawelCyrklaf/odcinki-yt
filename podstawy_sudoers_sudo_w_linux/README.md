# Sudoers - Spis poleceń

## Edycja sudoers

```bash
# ZAWSZE używaj visudo (nie nano/vim!)
visudo
```

---

## Podstawowa składnia sudoers

```bash
# Format
user host=(runas_user:runas_group) NOPASSWD: commands

# Przykład
pawel ALL=(ALL:ALL) NOPASSWD: /bin/systemctl restart nginx
```

---

## Przykład 1: Junior DevOps - tylko restart serwisów

```bash
# Edytuj sudoers
visudo
```

**Dodaj:**
```bash
# Junior DevOps - tylko restart serwisów
junior ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx, /bin/systemctl restart mysql, /bin/systemctl status *
```

**Test:**
```bash
# Zaloguj się jako junior
su - junior

# To zadziała
sudo systemctl restart nginx
sudo systemctl status nginx

# To NIE zadziała
sudo systemctl stop nginx
sudo systemctl edit nginx
```

---

## Przykład 2: Monitoring user - tylko czytanie logów

```bash
# Edytuj sudoers
visudo
```

**Dodaj:**
```bash
# Monitoring - read-only access to logs
monitoring ALL=(ALL) NOPASSWD: /bin/cat /var/log/*, /usr/bin/tail * /var/log/*, /bin/journalctl *, /bin/grep * /var/log/*
```

**Test:**
```bash
# Zaloguj się jako monitoring
su - monitoring

# To zadziała
sudo cat /var/log/syslog
sudo tail -f /var/log/nginx/access.log

# To NIE zadziała
sudo rm /var/log/syslog
```

---

## Grupy sudo

### Dodawanie użytkownika do grupy sudo

```bash
# Dodaj użytkownika do grupy sudo (pełne uprawnienia)
usermod -aG sudo username

# Sprawdź członków grupy
getent group sudo

# Sprawdź konfigurację grupy sudo
cat /etc/sudoers | grep sudo
```

### Tworzenie własnej grupy z ograniczonymi uprawnieniami

```bash
# Utwórz grupę
groupadd devops

# Dodaj użytkowników do grupy
usermod -aG devops pawel
usermod -aG devops anna
usermod -aG devops marek

# Edytuj sudoers
visudo
```

**Dodaj:**
```bash
# DevOps group - service management only
%devops ALL=(ALL) NOPASSWD: /bin/systemctl restart *, /bin/systemctl status *, /bin/systemctl reload *
```

**Test:**
```bash
# Zaloguj się jako użytkownik z grupy devops
su - pawel

# To zadziała
sudo systemctl restart nginx
sudo systemctl status mysql

# To NIE zadziała
sudo systemctl stop nginx
sudo apt update
```

---

## Aliasy

### User_Alias - grupowanie użytkowników

```bash
# Edytuj sudoers
visudo
```

**Dodaj na początku pliku:**
```bash
# User aliases
User_Alias SYSADMINS = pawel, anna, marek
User_Alias DEVELOPERS = tomek, ola, piotr
User_Alias JUNIORS = bartek, zosia

# Użycie aliasów
SYSADMINS ALL=(ALL:ALL) ALL
DEVELOPERS ALL=(ALL) NOPASSWD: /bin/systemctl restart *, /usr/bin/git, /usr/bin/npm
JUNIORS ALL=(ALL) NOPASSWD: /bin/systemctl status *
```

### Cmnd_Alias - grupowanie komend

```bash
# Edytuj sudoers
visudo
```

**Dodaj:**
```bash
# Command alias
Cmnd_Alias SERVICES = /bin/systemctl restart *, /bin/systemctl reload *, /bin/systemctl status *

# Użycie dla grupy devops
%devops ALL=(ALL) NOPASSWD: SERVICES
```

### Kombinacja aliasów

```bash
# Aliases
User_Alias WEBDEVS = pawel, anna
User_Alias DBADMINS = marek, kasia
Cmnd_Alias WEB_SERVICES = /bin/systemctl * nginx, /bin/systemctl * apache2
Cmnd_Alias DB_SERVICES = /bin/systemctl * mysql, /bin/systemctl * postgresql

# Permissions
WEBDEVS ALL=(ALL) NOPASSWD: WEB_SERVICES
DBADMINS ALL=(ALL) NOPASSWD: DB_SERVICES
```

---

## Backup sudoers

```bash
# Zrób backup przed edycją
cp /etc/sudoers /etc/sudoers.backup.$(date +%Y%m%d)

# Przywróć z backupu w razie problemów
cp /etc/sudoers.backup.20241230 /etc/sudoers
```

---

## Audyt i monitorowanie

```bash
# Zobacz wszystkie użycia sudo
grep sudo /var/log/auth.log

# Wszystkie komendy konkretnego użytkownika
grep "sudo:.*pawel" /var/log/auth.log
```

---

## Testowanie uprawnień

```bash
# Sprawdź co user może zrobić przez sudo
sudo -l

# Sprawdź grupy użytkownika
groups pawel

# Test jako inny user (jako root)
sudo -u pawel sudo -l
```

---

## Sudo vs su

```bash
# su - wymaga hasła ROOT, brak audytu
su -

# sudo - wymaga TWOJEGO hasła, pełny audit
sudo systemctl restart nginx
```

---

## Troubleshooting

```bash
# Sprawdź składnię sudoers (bez zapisywania)
visudo -c

# Jeśli zepsułeś sudoers i nie możesz użyć sudo:
# 1. Zaloguj się przez drugą sesję (jeśli masz)
# 2. Użyj konsoli VPS (AWS, DigitalOcean)
# 3. Przywróć backup

# Usuń użytkownika z grupy sudo
gpasswd -d username sudo
```