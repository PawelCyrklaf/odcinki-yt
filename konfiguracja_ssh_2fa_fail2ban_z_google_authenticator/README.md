# SSH 2FA + Fail2ban - Spis poleceń

## Przygotowanie

```bash
# Otwórz drugą sesję SSH i zostaw jako backup
su -
```

---

## Instalacja Google Authenticator

```bash
# Aktualizacja systemu
apt update && apt upgrade -y

# Instalacja Google Authenticator PAM module
apt install -y libpam-google-authenticator
```

---

## Konfiguracja Google Authenticator dla użytkownika

```bash
# Przełącz się na swojego użytkownika
su - twoj_user

# Uruchom konfigurację
google-authenticator
```

**Odpowiedzi na pytania:**
- Time-based tokens? → `y`
- Update file? → `y`
- Disallow multiple uses? → `y`
- Time-skew compensation? → `n`
- Rate-limiting? → `y`

```bash
# Sprawdź plik konfiguracyjny
ls -la ~/.google_authenticator

# Wyjdź z powrotem do root
exit
```

---

## Konfiguracja PAM

```bash
# Edytuj konfigurację PAM dla SSH
nano /etc/pam.d/sshd
```

**Zakomentuj linię:**
```
# @include common-auth
```

**Dodaj na końcu pliku:**
```
# Google Authenticator
auth required pam_google_authenticator.so nullok
```

---

## Konfiguracja SSH

```bash
# Edytuj konfigurację SSH
nano /etc/ssh/sshd_config
```

**Dodaj/zmień następujące linie:**
```
# Dla Ubuntu 22.04+
KbdInteractiveAuthentication yes

# Dla Ubuntu 20.04 i starsze
ChallengeResponseAuthentication yes

# Upewnij się że PAM jest włączony
UsePAM yes

# Wymagaj klucza SSH I kodu 2FA (dodaj na końcu)
AuthenticationMethods publickey,keyboard-interactive
```

```bash
# Test składni
sshd -t

# Restart SSH
systemctl restart ssh
```

---

## Testowanie 2FA

```bash
# W NOWEJ sesji terminala
ssh -i twoj_klucz.pem twoj_user@adres_serwera
```

Wpisz 6-cyfrowy kod z aplikacji Google Authenticator.

---

## Test backup codes

```bash
# Nowe połączenie SSH
ssh -i twoj_klucz.pem twoj_user@adres_serwera

# Użyj emergency scratch code zamiast kodu z aplikacji
```

---

## Recovery - zgubiony telefon

```bash
# Zaloguj się przez emergency code lub konsolę VPS

# Usuń starą konfigurację
rm ~/.google_authenticator

# Skonfiguruj 2FA na nowym telefonie
google-authenticator
```

---

## BONUS: Fail2ban

### Instalacja

```bash
# Instalacja fail2ban
apt install -y fail2ban

# Uruchom i włącz autostart
systemctl enable fail2ban
systemctl start fail2ban
```

### Konfiguracja

```bash
# Skopiuj domyślną konfigurację
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edytuj
nano /etc/fail2ban/jail.local
```

**W sekcji `[sshd]` ustaw:**
```ini
[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 3600
findtime = 600
```

### Filtr dla 2FA

```bash
# Stwórz dedykowany filtr
nano /etc/fail2ban/filter.d/sshd-2fa.conf
```

**Wklej:**
```ini
[Definition]
failregex = .*Failed keyboard-interactive.*rhost=<HOST>
            .*pam_google_authenticator.*authentication failure.*rhost=<HOST>
```

```bash
# Edytuj jail.local
nano /etc/fail2ban/jail.local
```

**Dodaj na końcu:**
```ini
[sshd-2fa]
enabled = true
port = ssh
filter = sshd-2fa
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
findtime = 600
```

### Restart i monitoring

```bash
# Restart fail2ban
systemctl restart fail2ban

# Sprawdź status
fail2ban-client status

# Status konkretnego jail
fail2ban-client status sshd
fail2ban-client status sshd-2fa

# Zobacz zbanowane IP
fail2ban-client status sshd | grep "Banned IP"

# Zobacz logi fail2ban
tail -f /var/log/fail2ban.log
```

### Odbanowanie

```bash
# Odbanuj konkretne IP
fail2ban-client set sshd unbanip 192.168.1.100

# Odbanuj wszystkie IP
fail2ban-client unban --all
```

---

## Troubleshooting

```bash
# Sprawdź logi SSH
tail -100 /var/log/auth.log

# Sprawdź synchronizację czasu
date

# Popraw uprawnienia pliku .google_authenticator
chmod 400 ~/.google_authenticator

# Test składni SSH
sshd -t

# Restart SSH
systemctl restart ssh
```

---

## Monitoring i audyt

```bash
# Zobacz wszystkie próby logowania SSH
grep "sshd" /var/log/auth.log

# Zobacz nieudane próby 2FA
grep "google_authenticator" /var/log/auth.log

# Zobacz zbanowane IP przez fail2ban
fail2ban-client status sshd
```