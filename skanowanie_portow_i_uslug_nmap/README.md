# Polecenia uzyte w filmie - nmap

## Instalacja

Sprawdzenie czy nmap jest zainstalowany:
```bash
nmap --version
```

Instalacja nmap:
```bash
apt install nmap
```

---

## Ustawienie zmiennej

Ustawienie zmiennej z IP maszyny docelowej:
```bash
TARGET=172.31.3.33
```

---

## Podstawowe skanowanie hostow

Sprawdzenie czy host jest dostepny w sieci (ping scan):
```bash
nmap -sn $TARGET
```

Skanowanie calej podsieci:
```bash
nmap -sn 172.31.3.0/24
```

---

## Skanowanie portow i uslug

Podstawowe skanowanie portow (1000 najpopularniejszych):
```bash
nmap $TARGET
```

Skanowanie wszystkich 65535 portow:
```bash
nmap -p- $TARGET
```

Skanowanie konkretnego portu:
```bash
nmap -p 22 $TARGET
```

Skanowanie zakresu portow:
```bash
nmap -p 1-1000 $TARGET
```

Wykrywanie wersji uslug:
```bash
nmap -sV $TARGET
```

---

## Wykrywanie systemu operacyjnego

Wykrywanie systemu operacyjnego:
```bash
nmap -O $TARGET
```

Aggressive scan - OS, wersje uslug, skrypty NSE, traceroute:
```bash
nmap -A $TARGET
```

---

## Skanowanie skryptami NSE

Uruchomienie domyslnych skryptow:
```bash
nmap -sC $TARGET
```

Szybki audyt serwera - wersje uslug i domyslne skrypty:
```bash
nmap -sV -sC $TARGET
```

Sprawdzenie naglowkow HTTP:
```bash
nmap --script http-headers $TARGET
```

Sprawdzenie algorytmow szyfrowania SSH:
```bash
nmap --script ssh2-enum-algos $TARGET
```

Skanowanie podatnosci:
```bash
nmap --script vuln $TARGET
```

---

## Opcje dodatkowe

Cichy skan - wolniejszy, trudniejszy do wykrycia:
```bash
nmap -T2 $TARGET
```

Zapis wynikow do pliku tekstowego:
```bash
nmap -sV $TARGET -oN wyniki.txt
```

Zapis wynikow do pliku XML:
```bash
nmap -sV $TARGET -oX wyniki.xml
```

Zapis wynikow do formatu grepable:
```bash
nmap -sV $TARGET -oG wyniki.grep
```