# grep, awk, sed - komendy z odcinka

Uruchom setup przed ćwiczeniami:

```bash
bash setup.sh && cd ~/warsztat
```

---

## grep

Znajdź wszystkie błędy w logach:

```bash
grep "ERROR" app.log
```

Filtruj po wzorcu — błędy 5xx z logów nginx (`-E` włącza rozszerzone wyrażenia regularne):

```bash
grep -E '" 50[0-9] ' access.log
```

---

## awk

Wyciągnij IP i endpoint tylko dla błędów 500 (kolumna 9 = kod HTTP, kolumna 1 = IP, kolumna 7 = endpoint):

```bash
awk '$9 == "500" {print $1, $7}' access.log
```

Policz błędy per IP i posortuj:

```bash
awk '$9 == "500" {count[$1]++} END {for (ip in count) print count[ip], ip}' access.log | sort -rn
```

---

## sed

Podejrzyj zmianę przed zapisem (bez `-i` sed tylko wyświetla):

```bash
sed 's/192.168.1.10/10.10.0.10/g' config.conf
```

Zamień w pliku i utwórz backup (`.bak`):

```bash
sed -i.bak 's/192.168.1.10/10.10.0.10/g' config.conf
```

Sprawdź co się zmieniło:

```bash
diff config.conf config.conf.bak
```

Zamień we wszystkich plikach `.conf` naraz:

```bash
sed -i.bak 's/192.168.1.10/10.10.0.10/g' *.conf
```

---

## Pipeline

Znajdź winowajcę w jednej linii — ranking IP po liczbie błędów 500:

```bash
grep '" 500 ' access.log | awk '{print $1}' | sort | uniq -c | sort -rn
```

Sprawdź o której godzinie skupiały się błędy:

```bash
grep '" 500 ' access.log | awk '{split($4, t, ":"); print t[2]":"t[3]}' | sort | uniq -c
```