# LUKS — lista poleceń

## Sprawdzenie dysków

```bash
lsblk
```
Lista wszystkich dysków i partycji w systemie.

```bash
sudo blkid /dev/nvme1n1
```
Pobiera UUID dysku — potrzebny do `/etc/crypttab`.

---

## Szyfrowanie

```bash
sudo cryptsetup luksFormat /dev/nvme1n1
```
Szyfruje cały dysk/partycję (AES-256). Niszczy istniejące dane — wymaga potwierdzenia `YES`.

```bash
sudo cryptsetup luksDump /dev/nvme1n1
```
Wyświetla nagłówek LUKS: algorytm, UUID, sloty kluczy.

---

## Otwieranie i zamykanie

```bash
sudo cryptsetup luksOpen /dev/nvme1n1 sekretny_dysk
```
Otwiera zaszyfrowany dysk i tworzy urządzenie wirtualne `/dev/mapper/sekretny_dysk`.

```bash
sudo cryptsetup luksClose sekretny_dysk
```
Zamyka zaszyfrowany dysk i usuwa go z `/dev/mapper/`.

---

## Formatowanie i montowanie

```bash
sudo mkfs.ext4 /dev/mapper/sekretny_dysk
```
Tworzy system plików na otwartym urządzeniu. Wykonywać tylko raz po pierwszym `luksOpen`.

```bash
sudo mkdir /mnt/sekretny
sudo mount /dev/mapper/sekretny_dysk /mnt/sekretny
```
Tworzy punkt montowania i montuje dysk.

```bash
sudo umount /mnt/sekretny
```
Odmontowuje dysk przed zamknięciem LUKS.

---

## Backup i odtworzenie nagłówka

```bash
sudo cryptsetup luksHeaderBackup /dev/nvme1n1 --header-backup-file ~/luks_header_nvme1n1.img
```
Zapisuje nagłówek LUKS do pliku. Bez tego backupu uszkodzenie nagłówka = trwała utrata danych.

```bash
sudo cryptsetup luksHeaderRestore /dev/nvme1n1 --header-backup-file ~/luks_header_nvme1n1.img
```
Odtwarza nagłówek z kopii zapasowej.

---

## Plik klucza (automount bez hasła)

```bash
sudo dd if=/dev/urandom of=/etc/luks.key bs=4096 count=1
sudo chmod 400 /etc/luks.key
sudo cryptsetup luksAddKey /dev/nvme1n1 /etc/luks.key
```
Generuje losowy plik klucza, zabezpiecza go uprawnieniami i dodaje do LUKS jako dodatkowy klucz.

---

## Automount po restarcie

**`/etc/crypttab`** — otwiera zaszyfrowany dysk przy starcie systemu:
```
sekretny_dysk  UUID=<uuid>  none  luks
```
`none` = interaktywne pytanie o hasło. Zastąp ścieżką do pliku klucza dla automount bez hasła.

**`/etc/fstab`** — montuje otwarte urządzenie:
```
/dev/mapper/sekretny_dysk  /mnt/sekretny  ext4  defaults  0  2
```

---

## Podgląd surowych danych

```bash
sudo xxd /dev/nvme1n1 | head -5
```
Wyświetla pierwsze bajty dysku w hex — widoczny nagłówek LUKS.

```bash
sudo xxd -s 16777216 -l 32 /dev/nvme1n1
```
Wyświetla 32 bajty z offsetu 16 MB — zaszyfrowane dane wyglądają jak losowe bajty.