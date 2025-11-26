# SSH – Kompletny Cheatsheet

# 🧭 1. Podstawowe połączenia SSH

## 🔹 Połączenie z serwerem

```bash
ssh ubuntu@3.79.34.125
```

**Opis:** Najprostsza forma połączenia SSH - łączy się z serwerem jako użytkownik `ubuntu`.
**Kiedy używać:** Gdy serwer korzysta z domyślnego portu 22 i nie wymaga specjalnych kluczy.
**Pułapka:** Jeśli serwer blokuje hasła, musisz mieć skonfigurowane klucze.

---

## 🔹 Połączenie przez hostname

```bash
ssh ubuntu@ec2-3-79-34-125.eu-central-1.compute.amazonaws.com
```

**Opis:** Połączenie po domenie zamiast IP - wygodniejsze przy dynamicznych adresach.
**Protip:** Używaj hostname w chmurach, ponieważ IP może się zmienić.

---

## 🔹 Akceptacja fingerprintu

```bash
yes
```

**Opis:** Potwierdzenie tożsamości serwera przy pierwszym połączeniu.
**UWAGA:** Jeśli przy kolejnych połączeniach fingerprint się zmieni - to może być MITM!

---

## 🔹 Logowanie hasłem

```
ubuntu@3.79.34.125's password:
```

**Opis:** SSH poprosi o hasło - tylko wtedy, gdy serwer zezwala na logowanie hasłem.
**Protip:** W produkcji **wyłącz PasswordAuthentication**.

---

# 🧭 2. Podstawowe komendy po zalogowaniu

```bash
hostname
whoami
pwd
uname -a
df -h
```

### Co robią?

- **hostname** - wyświetla nazwę serwera, przydatne przy wielu środowiskach
- **whoami** - pokazuje aktualnego użytkownika
- **pwd** - bieżący katalog
- **uname -a** - informacje o systemie i kernelu
- **df -h** - dostępne miejsce na dyskach (czytelny format)

---

### 🔹 Wylogowanie

```bash
exit
```

lub
`Ctrl + D`

**Protip:** Polecenia w skryptach wykonuj jako:
`ssh user@host "komenda"` - wtedy samo się wyloguje.

---

# 🧭 3. Opcje połączenia SSH

## 🔹 Połączenie na innym portcie

```bash
ssh -p 2222 ubuntu@server
```

**Opis:** SSH działa na niestandardowym porcie.
**Kiedy używać:** Jeśli zmieniłeś port w `/etc/ssh/sshd_config`.
**Pułapka:** `-p` jest małe! Dla SCP jest **duże -P**.

---

## 🔹 Debugowanie (verbose)

```bash
ssh -v ubuntu@server
ssh -vv ubuntu@server
ssh -vvv ubuntu@server
```

**Opis:** Pokazuje szczegółowe informacje o próbie połączenia.
**Kiedy używać:** Gdy SSH nie działa lub odrzuca klucz.
**Protip:** `-vvv` pokazuje cały handshake kryptograficzny.

---

## 🔹 Wykonanie komendy zdalnej

```bash
ssh ubuntu@server "uptime"
ssh ubuntu@server "df -h"
```

**Opis:** Przydatne w automatyzacji i CI/CD.
**Protip:** Możesz łączyć wiele poleceń - użyj `;`.

---

# 🧭 4. SSH Keys — generowanie, kopiowanie, logowanie

## 🔹 Generowanie klucza ED25519 (zalecany)

```bash
ssh-keygen -t ed25519 -C "twój_email@example.com"
```

**Opis:** Tworzy nowoczesny, bezpieczny klucz SSH.
**Protip:** ZAWSZE dodawaj passphrase.
**Pułapka:** Bez passphrase kradzież klucza = koniec bezpieczeństwa.

---

## 🔹 Lista kluczy

```bash
ls -la ~/.ssh/
```

**Opis:** Sprawdzasz, jakie klucze istnieją na maszynie.

---

## 🔹 Podgląd klucza publicznego

```bash
cat ~/.ssh/id_ed25519.pub
```

**Opis:** Ten klucz możesz publikować i wysyłać na serwer.

---

## 🔹 Kopiowanie klucza na serwer

```bash
ssh-copy-id ubuntu@3.79.34.125
```

**Opis:** Automatycznie dopisuje klucz do `authorized_keys`.
**Pułapka:** Użyjesz hasła **ostatni raz**.

---

## 🔹 Logowanie bez hasła

```bash
ssh ubuntu@3.79.34.125
```

**Opis:** Po poprawnym ustawieniu kluczy logowanie jest automatyczne.

---

# 🧭 5. Generowanie klucza RSA (dla starszych systemów)

```bash
ssh-keygen -t rsa -b 4096 -C "twój_email@example.com"
```

**Opis:** RSA jest cięższy, większy, ale bardziej kompatybilny.
**Protip:** Używaj RSA tylko, jeśli ED25519 nie działa.

---

# 🧭 6. Wiele kluczy (work/personal)

## 🔹 Generowanie kluczy z własną nazwą

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work -C "work@example.com"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -C "personal@example.com"
```

**Opis:** Pozwala używać innych kluczy dla pracy i prywatnych projektów.

---

## 🔹 Użycie konkretnego klucza

```bash
ssh -i ~/.ssh/id_ed25519_work ubuntu@work-server
ssh -i ~/.ssh/id_ed25519_personal ubuntu@personal-server
```

---

# 🧭 7. SSH Config — aliasy, porty, klucze

## 🔹 Sprawdzenie configa

```bash
ls -la ~/.ssh/config
```

---

## 🔹 Tworzenie configa i uprawnienia

```bash
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

---

## 🔹 Edycja configa

```bash
nano ~/.ssh/config
```

---

## 🔹 Test ustawień

```bash
ssh -G myserver
```

---

## 🔹 Połączenie aliasem

```bash
ssh myserver
```

**Opis:** Szybkie połączenia bez pamiętania IP, portów i kluczy.

---

# 🧭 8. SCP — kopiowanie plików przez SSH

## 🔹 Wysyłanie plików

```bash
scp local_file.txt ubuntu@3.79.34.125:/home/ubuntu/
scp -r local_directory ubuntu@3.79.34.125:~/
scp local_file.txt myserver:~/
```

## 🔹 Pobieranie plików

```bash
scp ubuntu@3.79.34.125:~/remote_file.txt ./
scp -r myserver:~/remote_directory ./
```

## 🔹 Kopiowanie między serwerami

```bash
scp ubuntu@server1:~/file.txt ubuntu@server2:~/
```

## 🔹 Opcje SCP (ważne!)

```bash
scp -P 2222 file.txt ubuntu@3.79.34.125:~/
scp -rp local_directory ubuntu@3.79.34.125:~/
scp -l 1000 bigfile.iso myserver:~/
```

**Pułapka:** `-P` (duże!) dla SCP — `-p` to coś innego!

---

# 🧭 9. Konfiguracja serwera SSH

## 🔹 Edycja konfiguracji

```bash
sudo nano /etc/ssh/sshd_config
```

## 🔹 Restart SSH

```bash
sudo systemctl restart ssh
sudo systemctl restart sshd
```

**Protip:** Uważaj - zła konfiguracja = odcięcie od serwera.

---

# 🧭 10. Monitoring i audyt logowań

## 🔹 Zalogowani użytkownicy

```bash
who
w
```

## 🔹 Historia logowań

```bash
last
last -n 10
last ubuntu
```
