# Polecenia użyte w filmie – ACL w Linuxie

## Instalacja i weryfikacja

Sprawdzenie czy pakiet `acl` jest zainstalowany:
```bash
dpkg -l acl
```

Instalacja pakietu (jeśli brak):
```bash
apt install acl
```

---

## Przygotowanie

Tworzenie użytkowników z katalogiem domowym i powłoką bash:
```bash
useradd -m -s /bin/bash anna
useradd -m -s /bin/bash bartek
useradd -m -s /bin/bash celina
```

Tworzenie katalogu i pliku testowego:
```bash
mkdir /projekt
echo "tajny plik projektu" > /projekt/plik.txt
```

---

## getfacl – odczyt uprawnień

Odczyt uprawnień ACL pliku:
```bash
getfacl /projekt/plik.txt
```

---

## setfacl – nadawanie uprawnień użytkownikom

Nadanie uprawnień odczytu i zapisu:
```bash
setfacl -m u:anna:rw /projekt/plik.txt
```

Nadanie uprawnień tylko do odczytu:
```bash
setfacl -m u:bartek:r /projekt/plik.txt
```

Odebranie wszystkich uprawnień:
```bash
setfacl -m u:celina:--- /projekt/plik.txt
```

Sprawdzenie znaku `+` (oznacza że plik ma ACL):
```bash
ls -l /projekt/plik.txt
```

---

## setfacl – nadawanie uprawnień grupom

Tworzenie grupy i dodawanie użytkowników:
```bash
groupadd devteam
usermod -aG devteam anna
usermod -aG devteam bartek
```

Nadanie uprawnień grupie:
```bash
setfacl -m g:devteam:rwx /projekt
```

---

## Default ACL – dziedziczenie uprawnień

Sprawdzenie że nowy plik nie dziedziczy ACL:
```bash
touch /projekt/nowy.txt
getfacl /projekt/nowy.txt
```

Ustawienie default ACL na katalogu:
```bash
setfacl -d -m u:anna:rw /projekt
setfacl -d -m u:bartek:r /projekt
setfacl -d -m g:devteam:rwx /projekt
```

Weryfikacja dziedziczenia na nowym pliku:
```bash
touch /projekt/auto.txt
getfacl /projekt/auto.txt
```

---

## Maska

Ręczna zmiana maski:
```bash
setfacl -m mask::rwx /projekt/plik.txt
```

---

## Usuwanie ACL

Usunięcie wpisu ACL konkretnego użytkownika (`-x`):
```bash
setfacl -x u:anna /projekt/plik.txt
```

Usunięcie wszystkich ACL z pliku (`-b`):
```bash
setfacl -b /projekt/plik.txt
```

Usunięcie default ACL z katalogu (`-k`):
```bash
setfacl -k /projekt
```