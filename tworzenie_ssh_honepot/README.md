# SSH Honeypot - Spis poleceń

## Krok 1: Zabezpiecz prawdziwy SSH
```bash
# Edytuj konfigurację SSH
nano /etc/ssh/sshd_config
```

Zmień: `Port 2000`
```bash
# Zrestartuj SSH
systemctl restart sshd

# Sprawdź czy SSH działa na nowym porcie
ss -tlnp | grep sshd

# Test z nowej sesji
ssh -p 2000 twoj_user@adres_serwera
```

---

## Krok 2: Instalacja zależności
```bash
# Aktualizacja systemu
apt update && apt upgrade -y

# Instalacja wymaganych pakietów
apt install -y git python3-virtualenv libssl-dev libffi-dev \
    build-essential python3-dev python3-pip libsnappy-dev
```

---

## Krok 3: Stwórz dedykowanego użytkownika
```bash
# Stwórz użytkownika bez hasła
adduser --disabled-password cowrie

# Przełącz się na użytkownika cowrie
su - cowrie
```

---

## Krok 4: Pobierz i zainstaluj Cowrie
```bash
# Sklonuj repozytorium
git clone https://github.com/cowrie/cowrie.git
cd cowrie

# Stwórz wirtualne środowisko Python
python3 -m venv cowrie-env

# Aktywuj środowisko
source cowrie-env/bin/activate

# Zaktualizuj pip
pip install --upgrade pip

# Zainstaluj zależności Cowrie
pip install -r requirements.txt

# Zainstaluj Cowrie w trybie editable
pip install -e .
```

---

## Krok 5: Konfiguracja Cowrie
```bash
# Skopiuj przykładową konfigurację
cp etc/cowrie.cfg.dist etc/cowrie.cfg

# Edytuj konfigurację
nano etc/cowrie.cfg
```

Kluczowe ustawienia w `etc/cowrie.cfg`:

**Sekcja [ssh]:**
```ini
[ssh]
enabled = true
listen_endpoints = tcp:2222:interface=0.0.0.0
version = SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.1
```

**Sekcja [telnet]:**
```ini
[telnet]
enabled = false
```

**Sekcja [honeypot]:**
```ini
[honeypot]
hostname = production-server
auth_class = UserDB
```

**Sekcja [shell]:**
```ini
[shell]
arch = linux-x64-lsb
kernel_version = 3.2.0-4-amd64
kernel_build_string = #1 SMP Debian 3.2.68-1+deb7u1
hardware_platform = x86_64
operating_system = GNU/Linux
```

---

## Krok 6: Uruchom Cowrie
```bash
# Upewnij się, że jesteś w katalogu cowrie i masz aktywne środowisko
cd ~/cowrie
source cowrie-env/bin/activate

# Uruchom Cowrie
cowrie start

# Sprawdź status
cowrie status

# Sprawdź czy nasłuchuje na porcie 2222
ss -tlnp | grep 2222

# Zobacz logi na żywo
tail -f ~/cowrie/var/log/cowrie/cowrie.log
```

---

## Krok 7: Przekierowanie ruchu
```bash
# Wyjdź z użytkownika cowrie
exit

# Przekieruj port 22 na 2222
iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222

# Sprawdź reguły
iptables -t nat -L -n -v

# Zainstaluj narzędzie do zapisywania reguł
apt install -y iptables-persistent

# Zapisz reguły
netfilter-persistent save

# Sprawdź czy reguły przetrwają restart
iptables-save | grep 2222
```

---

## Krok 8: Testowanie
```bash
# Test honeypota (port 22) - z innego komputera
ssh root@adres_twojego_serwera
# Hasło: cokolwiek (password, admin, 123456)

# Test prawdziwego SSH (port 2000) - z innego komputera
ssh -p 2000 twoj_user@adres_twojego_serwera
# Twoje prawdziwe hasło lub klucz SSH
```

---

## Krok 9: Analiza logów
```bash
# Przełącz się z powrotem na użytkownika cowrie
su - cowrie

# Zobacz logi na żywo
tail -f ~/cowrie/var/log/cowrie/cowrie.log

# JSON z wszystkimi detalami
tail -f ~/cowrie/var/log/cowrie/cowrie.json

# Dla ładniejszego wyświetlania (opcjonalnie)
apt install jq
tail -f ~/cowrie/var/log/cowrie/cowrie.json | jq

# Pobrane pliki (malware!)
ls -lah ~/cowrie/var/lib/cowrie/downloads/

# Wszystkie komendy
grep "CMD:" ~/cowrie/var/log/cowrie/cowrie.log

# Najpopularniejsze komendy
grep "CMD:" ~/cowrie/var/log/cowrie/cowrie.log | awk '{print $NF}' | sort | uniq -c | sort -rn | head -20

# Nieudane próby logowania
grep "login attempt" ~/cowrie/var/log/cowrie/cowrie.log | grep "failed"

# Udane próby logowania
grep "login attempt" ~/cowrie/var/log/cowrie/cowrie.log | grep "succeeded"

# Najpopularniejsze kombinacje login/hasło
grep "login attempt" ~/cowrie/var/log/cowrie/cowrie.log | awk -F'[][]' '{print $2}' | sort | uniq -c | sort -rn | head -20
```

---

## Krok 10: Autostart po restarcie serwera
```bash
# Jako root
nano /etc/systemd/system/cowrie.service
```

Zawartość pliku `cowrie.service`:
```ini
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target
Wants=network.target

[Service]
Type=forking
User=cowrie
Group=cowrie
WorkingDirectory=/home/cowrie/cowrie
Environment="PATH=/home/cowrie/cowrie-env/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/home/cowrie/cowrie-env/bin/cowrie start
ExecStop=/home/cowrie/cowrie-env/bin/cowrie stop
PIDFile=/home/cowrie/cowrie/var/run/cowrie.pid

[Install]
WantedBy=multi-user.target
```
```bash
# Przeładuj systemd
systemctl daemon-reload

# Włącz autostart
systemctl enable cowrie

# Test
systemctl start cowrie
systemctl status cowrie
```

---

## Zaawansowane: Edycja userdb.txt
```bash
# Ogranicz listę akceptowanych loginów
nano ~/cowrie/etc/userdb.txt
```

Przykładowa zawartość:
```
root:x:0:root
root:x:0:123456
admin:x:1000:admin
ubuntu:x:1000:ubuntu
```

Format: `username:uid:gid:hasło`
```bash
# Restart Cowrie po zmianie
systemctl restart cowrie
```

---

## Przydatne komendy
```bash
# Status Cowrie
systemctl status cowrie

# Restart Cowrie
systemctl restart cowrie

# Stop Cowrie
systemctl stop cowrie

# Zobacz logi systemd
journalctl -u cowrie -f

# Sprawdź porty
ss -tlnp | grep -E "22|2000|2222"

# Sprawdź iptables
iptables -t nat -L -n -v
```
