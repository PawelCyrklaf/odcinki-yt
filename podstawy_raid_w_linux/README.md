# RAID 1 - Kompletny Przewodnik Poleceń

## Spis treści

1. [Przygotowanie środowiska](#przygotowanie-środowiska)
2. [Tworzenie RAID 1](#tworzenie-raid-1)
3. [Testowanie RAID](#testowanie-raid)
4. [Symulacja awarii dysku](#symulacja-awarii-dysku)
5. [Odbudowa RAID po awarii](#odbudowa-raid-po-awarii)
6. [Monitoring i zarządzanie](#monitoring-i-zarządzanie)
7. [Hot Spare - automatyczna odbudowa](#hot-spare)

---

## Przygotowanie środowiska

### Sprawdzenie dostępnych dysków

```bash
lsblk
```

**Opis:** Wyświetla wszystkie dyski blokowe w systemie w formie drzewa. Pokazuje dyski, ich partycje oraz punkty montowania.

---

### Sprawdzenie czy dyski są czyste

```bash
sudo fdisk -l /dev/xvdd /dev/xvde /dev/xvdf
```

**Opis:** Wyświetla szczegółowe informacje o partycjach na wskazanych dyskach. Pomaga sprawdzić czy dyski są czyste (bez partycji) przed utworzeniem RAID.

---

### Sprawdzenie czy mdadm jest zainstalowany

```bash
which mdadm
```

**Opis:** Pokazuje ścieżkę do programu mdadm, jeśli jest zainstalowany w systemie.

```bash
mdadm --version
```

**Opis:** Wyświetla wersję zainstalowanego narzędzia mdadm.

---

### Instalacja mdadm

```bash
sudo apt update
sudo apt install mdadm
```

**Opis:**

- `apt update` - aktualizuje listę dostępnych pakietów
- `apt install mdadm` - instaluje narzędzie mdadm (Multiple Device Administrator) do zarządzania Software RAID w systemie Ubuntu/Debian

**Dla CentOS/RHEL:**

```bash
sudo yum install mdadm
```

---

## Tworzenie RAID 1

### Utworzenie RAID 1 array

```bash
sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/xvdd /dev/xvde
```

**Opis parametrów:**

- `--create` - tworzy nowy RAID array
- `--verbose` - pokazuje szczegółowe informacje podczas tworzenia
- `/dev/md0` - nazwa tworzonego urządzenia RAID (md0 = pierwszy RAID, md1 = drugi, itd.)
- `--level=1` - poziom RAID (1 = mirroring)
- `--raid-devices=2` - liczba dysków w array (dla RAID 1 minimum 2)
- `/dev/xvdd /dev/xvde` - fizyczne dyski do użycia w array

**Uwaga:** System zapyta "Continue creating array?" - należy wpisać `y`

---

### Sprawdzenie statusu tworzenia RAID

```bash
cat /proc/mdstat
```

**Opis:** Wyświetla informacje o wszystkich RAID arrays w systemie, w tym:

- Stan RAID (active/inactive)
- Typ RAID (raid1, raid5, itp.)
- Dyski w array z ich numerami
- Stan dysków: `[UU]` = oba dyski UP, `[U_]` = drugi dysk down
- Postęp synchronizacji/odbudowy

**Przykładowy output:**

```
md0 : active raid1 xvde[1] xvdd[0]
      20955136 blocks super 1.2 [2/2] [UU]
      resync = 4.2%
```

---

### Szczegółowe informacje o RAID

```bash
sudo mdadm --detail /dev/md0
```

**Opis:** Wyświetla pełne, szczegółowe informacje o RAID array, w tym:

- Poziom RAID
- Stan (State): clean, degraded, recovering
- Liczba aktywnych/oczekiwanych dysków
- UUID array
- Lista dysków członkowskich z ich rolami
- Informacje o synchronizacji/odbudowie

---

### Obserwowanie postępu synchronizacji

```bash
watch -n 1 cat /proc/mdstat
```

**Opis:** Automatycznie odświeża zawartość `/proc/mdstat` co 1 sekundę, pozwalając obserwować postęp synchronizacji w czasie rzeczywistym. Wyjście: `Ctrl+C`

**Alternatywnie (bez watch):**

```bash
watch -n 2 cat /proc/mdstat
```

Odświeża co 2 sekundy (mniej obciąża system).

---

### Tworzenie systemu plików

```bash
sudo mkfs.ext4 /dev/md0
```

**Opis:** Tworzy system plików ext4 na urządzeniu RAID. RAID array jest traktowany jak zwykły dysk - można na nim utworzyć dowolny system plików.

---

### Montowanie RAID

```bash
sudo mkdir /mnt/raid1
```

**Opis:** Tworzy katalog, który będzie punktem montowania dla RAID.

```bash
sudo mount /dev/md0 /mnt/raid1
```

**Opis:** Montuje RAID array w utworzonym katalogu. Po tym poleceniu można korzystać z RAID jak z normalnego dysku.

---

### Sprawdzenie dostępnego miejsca

```bash
df -h /mnt/raid1
```

**Opis:** Wyświetla informacje o dostępnym miejscu na zamontowanym RAID w czytelnym formacie (MB, GB). Dla RAID 1 z dwoma dyskami 20GB otrzymamy ~20GB użytecznej przestrzeni (dane są mirrorowane).

---

### Sprawdzenie hierarchii dysków

```bash
lsblk
```

**Opis:** Pokazuje hierarchię: fizyczne dyski (xvdd, xvde) należą do urządzenia md0, które jest zamontowane w `/mnt/raid1`.

---

## Testowanie RAID

### Tworzenie plików testowych

```bash
sudo dd if=/dev/zero of=/mnt/raid1/testfile1.dat bs=1M count=1000
```

**Opis:** Tworzy plik 1GB wypełniony zerami.

- `if=/dev/zero` - źródło danych (same zera)
- `of=/mnt/raid1/testfile1.dat` - plik docelowy
- `bs=1M` - rozmiar bloku 1MB
- `count=1000` - liczba bloków (1000 × 1MB = 1GB)

```bash
sudo dd if=/dev/urandom of=/mnt/raid1/testfile2.dat bs=1M count=500
```

**Opis:** Tworzy plik 500MB wypełniony losowymi danymi.

- `if=/dev/urandom` - źródło losowych danych
- Pozostałe parametry jak wyżej

```bash
echo "RAID 1 Test Data" | sudo tee /mnt/raid1/test.txt
```

**Opis:** Tworzy prosty plik tekstowy z zawartością "RAID 1 Test Data". Komenda `tee` zapisuje dane do pliku i jednocześnie wyświetla je na ekranie.

---

### Sprawdzenie utworzonych plików

```bash
ls -lh /mnt/raid1/
```

**Opis:** Wyświetla szczegółową listę plików w katalogu RAID z rozmiarami w czytelnym formacie (MB, GB).

```bash
cat /mnt/raid1/test.txt
```

**Opis:** Wyświetla zawartość pliku tekstowego.

```bash
md5sum /mnt/raid1/testfile1.dat
```

**Opis:** Oblicza sumę kontrolną MD5 pliku. Przydatne do późniejszej weryfikacji integralności danych po awarii i odbudowie.

---

## Symulacja awarii dysku

### Oznaczanie dysku jako uszkodzony

```bash
sudo mdadm --manage /dev/md0 --fail /dev/xvde
```

**Opis:** Symuluje awarię dysku oznaczając go jako uszkodzony (failed). W prawdziwym scenariuszu dysk po prostu przestaje działać.

- `--manage` - tryb zarządzania RAID
- `--fail` - oznacz dysk jako uszkodzony

---

### Sprawdzenie stanu po awarii

```bash
cat /proc/mdstat
```

**Opis:** Po awarii pokaże `[U_]` zamiast `[UU]` - jeden dysk działa (U), drugi nie (_).

**Przykładowy output:**

```
md0 : active raid1 xvde[1](F) xvdd[0]
      [U_]
```

```bash
sudo mdadm --detail /dev/md0
```

**Opis:** Pokaże:

- State: `clean, degraded` - RAID działa, ale nie ma pełnej redundancji
- Active Devices: 1/2
- Dysk xvde oznaczony jako faulty

---

### Sprawdzenie bezpieczeństwa danych

```bash
ls -lh /mnt/raid1/
```

**Opis:** Sprawdza czy wszystkie pliki nadal istnieją.

```bash
cat /mnt/raid1/test.txt
```

**Opis:** Odczytuje plik tekstowy - dane są bezpieczne, RAID czyta z działającego dysku.

```bash
md5sum /mnt/raid1/testfile1.dat
```

**Opis:** Sprawdza integralność danych przez porównanie sumy kontrolnej.

---

### Zapis danych podczas degraded

```bash
echo "Written after disk failure" | sudo tee /mnt/raid1/after_failure.txt
```

**Opis:** Tworzy nowy plik podczas gdy RAID jest w trybie degraded. Pokazuje, że RAID nadal działa i można zapisywać dane.

```bash
cat /mnt/raid1/after_failure.txt
```

**Opis:** Weryfikuje że zapis się powiódł.

---

### Usuwanie uszkodzonego dysku

```bash
sudo mdadm --manage /dev/md0 --remove /dev/xvde
```

**Opis:** Usuwa uszkodzony dysk z RAID array. W rzeczywistości teraz fizycznie wyjąłbyś dysk z serwera i włożył nowy.

- `--remove` - usuń dysk z array

---

### Sprawdzenie stanu po usunięciu

```bash
cat /proc/mdstat
```

**Opis:** Pokaże że RAID działa z jednym dyskiem.

```bash
sudo mdadm --detail /dev/md0
```

**Opis:** Pokaże że pozostał tylko jeden aktywny dysk. **Uwaga:** Brak redundancji - jeśli teraz drugi dysk spadnie, dane zostaną utracone!

---

## Odbudowa RAID po awarii

### Dodawanie nowego dysku

```bash
sudo mdadm --manage /dev/md0 --add /dev/xvdf
```

**Opis:** Dodaje nowy dysk (xvdf) do RAID array jako replacement dla usuniętego dysku. RAID automatycznie rozpocznie odbudowę (kopiowanie danych z działającego dysku).

- `--add` - dodaj dysk do array

---

### Natychmiastowe sprawdzenie odbudowy

```bash
cat /proc/mdstat
```

**Opis:** Pokaże że RAID rozpoczął odbudowę (recovery) z procentem postępu.

**Przykładowy output:**

```
md0 : active raid1 xvdf[2] xvdd[0]
      recovery = 2.1%
```

---

### Szczegóły odbudowy

```bash
sudo mdadm --detail /dev/md0
```

**Opis:** Wyświetla szczegółowe informacje o procesie odbudowy:

- State: `clean, degraded, recovering`
- Rebuild Status: procent postępu i szacowany czas zakończenia
- xvdf oznaczony jako `spare rebuilding`

---

### Obserwowanie odbudowy w czasie rzeczywistym

```bash
watch -n 2 cat /proc/mdstat
```

**Opis:** Automatycznie odświeża status co 2 sekundy, pozwalając obserwować postęp odbudowy. Na dużych dyskach proces może trwać godziny.

Wyjście: `Ctrl+C`

---

### Sprawdzenie po zakończeniu odbudowy

```bash
cat /proc/mdstat
```

**Opis:** Po zakończeniu pokaże `[UU]` - oba dyski znowu działają prawidłowo.

```bash
sudo mdadm --detail /dev/md0
```

**Opis:** Pokaże:

- State: `clean` (bez degraded)
- Raid Devices: 2/2
- Active Devices: 2/2
- Pełna redundancja przywrócona

---

### Weryfikacja danych po odbudowie

```bash
ls -lh /mnt/raid1/
```

**Opis:** Sprawdza czy wszystkie pliki są na miejscu.

```bash
cat /mnt/raid1/after_failure.txt
```

**Opis:** Sprawdza czy plik utworzony podczas awarii nadal istnieje - potwierdza że nie było utraty danych.

---

## Monitoring i zarządzanie

### Zapisywanie konfiguracji RAID

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
```

**Opis:** Zapisuje konfigurację RAID do pliku konfiguracyjnego. Dzięki temu system będzie wiedział jak złożyć array po restarcie.

- `--detail --scan` - skanuje i generuje konfigurację wszystkich RAID arrays
- `tee -a` - dopisuje do pliku (nie nadpisuje)

---

### Sprawdzenie zapisanej konfiguracji

```bash
cat /etc/mdadm/mdadm.conf
```

**Opis:** Wyświetla zawartość pliku konfiguracyjnego RAID. Powinien zawierać linię z UUID identyfikującym array - dzięki temu system pozna dyski nawet jak zmienią ścieżki.

---

### Aktualizacja initramfs

```bash
sudo update-initramfs -u
```

**Opis:** Aktualizuje initial ramdisk, dodając konfigurację RAID. Niezbędne aby RAID działał podczas bootowania systemu.

**Dla CentOS/RHEL:**

```bash
sudo dracut -f
```

---

### Podstawowe komendy monitoringu

#### Szybki status wszystkich RAID

```bash
cat /proc/mdstat
```

**Opis:** Najszybsza metoda sprawdzenia co się dzieje z RAID. Pokaż wszystkie arrays, ich stan, synchronizację.

---

#### Szczegóły konkretnego array

```bash
sudo mdadm --detail /dev/md0
```

**Opis:** Pełne informacje o konkretnym RAID: stan, UUID, dyski, synchronizacja, wszystkie parametry.

---

#### Sprawdzenie konkretnego dysku

```bash
sudo mdadm --examine /dev/xvdd
```

**Opis:** Wyświetla metadane RAID zapisane bezpośrednio na dysku. Pokazuje do jakiego array dysk należy, jego UUID, pozycję w array.

---

#### Status wszystkich dysków w RAID

```bash
sudo mdadm --detail --scan
```

**Opis:** Lista wszystkich RAID arrays w systemie z podstawowymi informacjami.

---

### Sprawdzanie błędów

```bash
sudo mdadm --detail /dev/md0 | grep -i error
```

**Opis:** Filtruje output szukając błędów. Jeśli "Events: 0", wszystko jest w porządku.

---

### Testowanie spójności danych

```bash
echo check | sudo tee /sys/block/md0/md/sync_action
```

**Opis:** Uruchamia sprawdzanie spójności danych między dyskami w RAID (data scrubbing). Przydatne do okresowej weryfikacji integralności. Proces działa w tle, postęp można obserwować w `/proc/mdstat`.

---

### Automatyczny monitoring - mdmonitor daemon

#### Sprawdzenie czy daemon działa

```bash
sudo systemctl status mdmonitor
```

**Opis:** Sprawdza status demona mdmonitor, który monitoruje RAID w tle.

---

#### Uruchomienie i włączenie demona

```bash
sudo systemctl start mdmonitor
```

**Opis:** Uruchamia demona mdmonitor.

```bash
sudo systemctl enable mdmonitor
```

**Opis:** Włącza automatyczne uruchamianie demona przy starcie systemu.

---

### Konfiguracja alertów email

```bash
sudo nano /etc/mdadm/mdadm.conf
```

**Opis:** Otwiera plik konfiguracyjny do edycji.

**Dodaj linię:**

```
MAILADDR admin@example.com
```

**Opis:** Konfiguruje adres email na który będą wysyłane powiadomienia o problemach z RAID (np. awaria dysku). W produkcji to must-have!

---

## Hot Spare

### Sprawdzenie pełnego RAID

```bash
sudo mdadm --detail /dev/md0
cat /proc/mdstat
```

**Opis:** Upewnij się że RAID ma oba dyski działające (State: clean, `[UU]`). Jeśli jest degraded, poczekaj na zakończenie odbudowy przed dodaniem hot spare.

---

### Dodawanie hot spare

```bash
sudo mdadm --manage /dev/md0 --add-spare /dev/xvde
```

**Opis:** Dodaje dysk jako hot spare (zapasowy w pogotowiu). Dysk nie jest aktywnie używany, ale automatycznie przejmie rolę gdy inny dysk w RAID ulegnie awarii.

- `--add-spare` - dodaj jako spare (nie jako aktywny członek)

---

### Sprawdzenie spare

```bash
sudo mdadm --detail /dev/md0
```

**Opis:** Powinno pokazać sekcję "Spare Devices: 1" z xvde czekającym w pogotowiu.

```bash
cat /proc/mdstat
```

**Opis:** Pokaże `[UU]` dla aktywnych dysków, a xvde będzie listowany osobno jako spare.

---

### Testowanie automatycznej odbudowy

```bash
sudo mdadm --manage /dev/md0 --fail /dev/xvdf
```

**Opis:** Symuluje awarię jednego z aktywnych dysków.

---

### Natychmiastowe sprawdzenie automatycznej aktywacji

```bash
cat /proc/mdstat
```

**Opis:** Magia! RAID automatycznie aktywował spare (xvde) i rozpoczął odbudowę. Nie trzeba było nic robić ręcznie!

**Przykładowy output:**

```
md0 : active raid1 xvde[2] xvdd[0] xvdf[1](F)
      recovery = 2.1%
```

- xvdf oznaczony jako (F) - failed
- xvde już się odbudowuje
- recovery pokazuje postęp

---

### Szczegóły automatycznej odbudowy

```bash
sudo mdadm --detail /dev/md0
```

**Opis:** Pokaże:

- State: `clean, degraded, recovering`
- xvde przechodzi ze "spare" na "active sync"
- Rebuild Status z postępem

---

### Obserwowanie odbudowy spare

```bash
watch -n 2 cat /proc/mdstat
```

**Opis:** Obserwuj jak spare automatycznie odbudowuje RAID.

---

### Po zakończeniu odbudowy spare

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
```

**Opis:** Po zakończeniu:

- `[UU]` - oba dyski znowu działają
- xvde już nie jest spare - jest aktywnym członkiem RAID
- Pełna redundancja przywrócona automatycznie

---

### Czyszczenie po teście spare

```bash
sudo mdadm --manage /dev/md0 --remove /dev/xvdf
```

**Opis:** Usuwa fizycznie uszkodzony dysk. W produkcji teraz wymieniłbyś go i mógł dodać jako nowy spare.

---

## Dodatkowe przydatne komendy

### Zatrzymanie RAID

```bash
sudo umount /mnt/raid1
sudo mdadm --stop /dev/md0
```

**Opis:** Odmontowuje RAID i zatrzymuje array. Przydatne przed usunięciem dysków lub rekonfiguracją.

---

### Usunięcie RAID (UWAGA - traci dane!)

```bash
sudo mdadm --zero-superblock /dev/xvdd /dev/xvde
```

**Opis:** **UWAGA: DESTRUKCYJNE!** Usuwa metadane RAID z dysków. Dyski stają się zwykłymi dyskami bez RAID. Używaj tylko gdy chcesz całkowicie usunąć RAID.

---

### Zmiana liczby aktywnych dysków

```bash
sudo mdadm --grow /dev/md0 --raid-devices=3
```

**Opis:** Zwiększa liczbę aktywnych dysków w RAID (np. z 2 do 3). Po tej komendzie trzeba dodać nowy dysk. Przydatne przy rozbudowie RAID.

---

### Eksport szczegółów RAID do pliku

```bash
sudo mdadm --detail /dev/md0 > ~/raid_details.txt
```

**Opis:** Zapisuje pełne informacje o RAID do pliku tekstowego. Przydatne do dokumentacji lub troubleshootingu.

---

## Podsumowanie najważniejszych komend

### Monitoring (codzienne użycie)

```bash
cat /proc/mdstat                    # Szybki przegląd wszystkich RAID
sudo mdadm --detail /dev/md0        # Szczegóły konkretnego RAID
```

### Zarządzanie dyskami

```bash
sudo mdadm --manage /dev/md0 --fail /dev/xvde       # Oznacz jako uszkodzony
sudo mdadm --manage /dev/md0 --remove /dev/xvde     # Usuń dysk
sudo mdadm --manage /dev/md0 --add /dev/xvdf        # Dodaj dysk
sudo mdadm --manage /dev/md0 --add-spare /dev/xvdf  # Dodaj jako spare
```

### Konfiguracja i persystencja

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf  # Zapisz config
sudo update-initramfs -u                                         # Aktualizuj initramfs
```

---

## Ważne przypomnienia

⚠️ **RAID NIE JEST backupem** - chroni tylko przed awarią sprzętu, nie przed przypadkowym usunięciem plików, ransomware, itp.

⚠️ **RAID degraded = wymień dysk natychmiast!** - w tym stanie brak redundancji, awaria drugiego dysku = utrata danych

⚠️ **Monitoruj regularnie** - sprawdzaj `/proc/mdstat` i konfiguruj alerty email

✅ **Hot spare w produkcji** - minimalizuje czas w stanie degraded

✅ **Testuj odbudowę** - regularnie testuj procedury recovery żeby być przygotowanym na prawdziwą awarię

✅ **Dokumentuj** - zapisuj konfigurację i procedury dla swojego zespołu

---

**Autor:** Seria Linux Tutorial
**Link do serii:** https://www.youtube.com/playlist?list=PLudQEwO9egC6ngKVezYmz_5ZldYCvqn24

---

Powodzenia z RAID! 🎬
