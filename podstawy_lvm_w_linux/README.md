# LVM - Lista wszystkich poleceń z odcinka

## Przygotowanie środowiska

```bash
# Sprawdzenie dostępnych dysków
lsblk

# Sprawdzenie czy dyski są czyste
sudo fdisk -l /dev/xvdd /dev/xvde

# Sprawdzenie czy LVM jest zainstalowany
which lvm
lvm version

# Instalacja LVM (jeśli potrzebne)
sudo apt install lvm2        # Ubuntu/Debian
sudo yum install lvm2        # CentOS/RHEL
```

## Tworzenie Physical Volume (PV)

```bash
# Utworzenie PV
sudo pvcreate /dev/xvdd

# Wyświetlenie listy PV (krótka)
sudo pvs

# Wyświetlenie szczegółów PV
sudo pvdisplay /dev/xvdd

# Usunięcie PV
sudo pvremove /dev/xvdd
```

## Tworzenie Volume Group (VG)

```bash
# Utworzenie VG
sudo vgcreate vg_demo /dev/xvdd

# Wyświetlenie listy VG (krótka)
sudo vgs

# Wyświetlenie szczegółów VG
sudo vgdisplay vg_demo

# Rozszerzenie VG o nowy dysk
sudo vgextend vg_demo /dev/xvde

# Wyświetlenie wykorzystania PV
sudo pvs -o+pv_used

# Usunięcie VG
sudo vgremove vg_demo
```

## Tworzenie Logical Volume (LV)

```bash
# Utworzenie LV o rozmiarze 10GB
sudo lvcreate -L 10G -n lv_data vg_demo

# Utworzenie LV używając całego wolnego miejsca
sudo lvcreate -l 100%FREE -n lv_data vg_demo

# Wyświetlenie listy LV (krótka)
sudo lvs

# Wyświetlenie szczegółów LV
sudo lvdisplay /dev/vg_demo/lv_data

# Wyświetlenie LV z urządzeniami fizycznymi
sudo lvs -a -o +devices
```

## Formatowanie i montowanie

```bash
# Utworzenie systemu plików ext4
sudo mkfs.ext4 /dev/vg_demo/lv_data

# Utworzenie punktu montowania
sudo mkdir /mnt/demo_data

# Montowanie
sudo mount /dev/vg_demo/lv_data /mnt/demo_data

# Sprawdzenie zamontowanych systemów plików
df -h | grep demo_data
mount | grep demo_data

# Wyświetlenie hierarchii
lsblk

# Odmontowanie
sudo umount /mnt/demo_data
```

## Dodawanie danych testowych

```bash
# Utworzenie plików testowych
sudo dd if=/dev/zero of=/mnt/demo_data/testfile1 bs=1M count=3000
sudo dd if=/dev/zero of=/mnt/demo_data/testfile2 bs=1M count=3000
sudo dd if=/dev/zero of=/mnt/demo_data/testfile3 bs=1M count=5000

# Sprawdzenie zajętości dysku
df -h /mnt/demo_data

# Lista plików
ls -lh /mnt/demo_data/
```

## Rozszerzanie Logical Volume

```bash
# Sprawdzenie wolnego miejsca w VG
sudo vgs

# Rozszerzenie LV o 5GB
sudo lvextend -L +5G /dev/vg_demo/lv_data

# Ustawienie finalnego rozmiaru 15GB
sudo lvextend -L 15G /dev/vg_demo/lv_data

# Użycie całego wolnego miejsca w VG
sudo lvextend -l +100%FREE /dev/vg_demo/lv_data

# Sprawdzenie rozmiaru LV
sudo lvs

# Sprawdzenie rozmiaru systemu plików (jeszcze nie rozszerzony)
df -h /mnt/demo_data

# Rozszerzenie systemu plików ext4/ext3
sudo resize2fs /dev/vg_demo/lv_data

# Rozszerzenie systemu plików XFS
sudo xfs_growfs /mnt/demo_data

# Sprawdzenie po rozszerzeniu
df -h /mnt/demo_data
```

## Snapshoty

```bash
# Utworzenie snapshota
sudo lvcreate -L 2G -s -n lv_data_snapshot /dev/vg_demo/lv_data

# Wyświetlenie snapshotów
sudo lvs

# Usunięcie pliku z głównego wolumenu
sudo rm /mnt/demo_data/testfile3
ls -lh /mnt/demo_data/

# Montowanie snapshota
sudo mkdir /mnt/snapshot
sudo mount /dev/vg_demo/lv_data_snapshot /mnt/snapshot -o ro,nouuid

# Sprawdzenie zawartości snapshota
ls -lh /mnt/snapshot/

# Porównanie rozmiarów
df -h | grep -E 'demo_data|snapshot'

# Przywracanie ze snapshota - metoda 1: merge
sudo umount /mnt/demo_data
sudo umount /mnt/snapshot
sudo lvconvert --merge /dev/vg_demo/lv_data_snapshot
sudo mount /dev/vg_demo/lv_data /mnt/demo_data
ls /mnt/demo_data/

# Przywracanie ze snapshota - metoda 2: kopiowanie
sudo cp /mnt/snapshot/testfile3 /mnt/demo_data/
ls -lh /mnt/demo_data/

# Odmontowanie i usunięcie snapshota
sudo umount /mnt/snapshot
sudo lvremove /dev/vg_demo/lv_data_snapshot

# Sprawdzenie wykorzystania snapshota
sudo lvs -o lv_name,origin,data_percent
```

## Automatyczne montowanie - /etc/fstab

```bash
# Sprawdzenie UUID wolumenu
sudo blkid /dev/vg_demo/lv_data

# Edycja /etc/fstab
sudo nano /etc/fstab

# Przykładowe wpisy do /etc/fstab:
# Ścieżka urządzenia:
/dev/vg_demo/lv_data  /mnt/demo_data  ext4  defaults  0  2

# UUID (rekomendowane):
UUID=twój-uuid-tutaj  /mnt/demo_data  ext4  defaults  0  2

# Z dodatkowymi opcjami:
/dev/vg_demo/lv_data  /mnt/demo_data  ext4  defaults,noatime  0  2

# Testowanie konfiguracji fstab (WAŻNE przed restartem!)
sudo umount /mnt/demo_data
sudo mount -a
df -h /mnt/demo_data
mount | grep demo_data
```

## Monitoring i zarządzanie

```bash
# Sprawdzenie statusu systemu LVM przy starcie
systemctl status lvm2-monitor

# Wyświetlenie backupów konfiguracji LVM
ls -la /etc/lvm/backup/
cat /etc/lvm/backup/vg_demo

# Backup konfiguracji VG
sudo vgcfgbackup

# Sprawdzenie spójności VG
sudo vgck vg_demo

# Wyświetlenie wszystkich LV z urządzeniami
sudo lvs -a -o +devices

# Sprawdzenie miejsca w VG
sudo vgs -o vg_name,vg_size,vg_free,vg_free_percent

# Sprawdzenie snapshotów
sudo lvs -o lv_name,origin,data_percent
```

## Usuwanie LVM (czyszczenie)

```bash
# Kolejność usuwania (od góry do dołu hierarchii):

# 1. Odmontuj filesystem
sudo umount /mnt/demo_data
sudo umount /mnt/snapshot  # jeśli był zamontowany

# 2. Usuń Logical Volumes
sudo lvremove /dev/vg_demo/lv_data_snapshot  # jeśli istnieje
sudo lvremove /dev/vg_demo/lv_data

# 3. Usuń Volume Group
sudo vgremove vg_demo

# 4. Usuń Physical Volumes
sudo pvremove /dev/xvdd
sudo pvremove /dev/xvde

# 5. Usuń wpis z /etc/fstab (jeśli dodałeś)
sudo nano /etc/fstab

# 6. Sprawdzenie że wszystko czyste
sudo pvs    # Powinno być puste
sudo vgs    # Powinno być puste
sudo lvs    # Powinno być puste
lsblk       # Dyski bez LVM
```

## Ściągawka komend

### Physical Volumes

```bash
pvcreate    # Utworzenie PV
pvs         # Lista PV (krótka)
pvdisplay   # Szczegóły PV
pvremove    # Usunięcie PV
```

### Volume Groups

```bash
vgcreate    # Utworzenie VG
vgextend    # Dodanie PV do VG
vgreduce    # Usunięcie PV z VG
vgs         # Lista VG (krótka)
vgdisplay   # Szczegóły VG
vgremove    # Usunięcie VG
vgck        # Sprawdzenie spójności VG
```

### Logical Volumes

```bash
lvcreate    # Utworzenie LV
lvextend    # Rozszerzenie LV
lvreduce    # Zmniejszenie LV (ostrożnie!)
lvs         # Lista LV (krótka)
lvdisplay   # Szczegóły LV
lvremove    # Usunięcie LV
lvconvert   # Konwersja/merge snapshotów
```

### Systemy plików

```bash
resize2fs   # Rozszerzenie ext4/ext3
xfs_growfs  # Rozszerzenie XFS
```

## Dodatkowe informacje

### Parametry lvcreate

```bash
-L 10G              # Literal size - dokładny rozmiar
-l 100%FREE         # Procent wolnego miejsca w VG
-l 80%VG            # Procent całkowitego VG
-s                  # Snapshot
-n nazwa            # Nazwa LV
```

### Parametry lvextend

```bash
-L +5G              # Dodaj 5GB
-L 15G              # Ustaw finalny rozmiar na 15GB
-l +100%FREE        # Użyj całego wolnego miejsca
```

### Opcje montowania w /etc/fstab

```bash
defaults            # Standardowe opcje
noatime             # Nie aktualizuj czasu dostępu (szybsze)
nodiratime          # Nie aktualizuj czasu dostępu dla katalogów
ro                  # Read-only
nofail              # System wystartuje nawet jeśli montowanie się nie uda
```

---

**Link do odcinka:** [LVM Tutorial - TOFU](link)

**Playlist Linux:** https://www.youtube.com/playlist?list=PLudQEwO9egC6ngKVezYmz_5ZldYCvqn24
