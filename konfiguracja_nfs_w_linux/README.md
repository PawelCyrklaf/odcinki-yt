# NFS Linux - komendy z odcinka

Dwa serwery Linux w tej samej sieci. W przykładzie:
- **SERVER**: `172.31.37.53`
- **CLIENT**: `172.31.40.166`

Podmień IP na swoje - reszta działa tak samo.

Jeśli robisz to na EC2/VPS z publicznym IP - nie otwieraj portu 2049 na `0.0.0.0/0`, ogranicz do IP klienta.

---

## SERWER

Instalacja:

```bash
sudo apt install nfs-kernel-server
```

Utwórz katalog do współdzielenia:

```bash
sudo mkdir -p /srv/nfs
sudo chown nobody:nogroup /srv/nfs
```

Dodaj wpis do `/etc/exports`:

```bash
sudo nano /etc/exports
```

```
/srv/nfs    172.31.40.166(rw,sync,no_subtree_check,root_squash)
```

Zastosuj i uruchom serwis:

```bash
sudo systemctl enable --now nfs-kernel-server
sudo exportfs -a
sudo exportfs -v
```

Po każdej zmianie `/etc/exports` - bez restartu serwisu:

```bash
sudo exportfs -a
```

---

## KLIENT

Instalacja:

```bash
sudo apt install nfs-common
```

Sprawdź co serwer udostępnia:

```bash
showmount -e 172.31.37.53
```

Zamontuj share:

```bash
sudo mkdir -p /mnt/nfs
sudo mount 172.31.37.53:/srv/nfs /mnt/nfs
df -h /mnt/nfs
```

---

## Test - obie strony

Na kliencie utwórz plik:

```bash
echo "hello from client" | sudo tee /mnt/nfs/test.txt
```

Na serwerze zweryfikuj:

```bash
cat /srv/nfs/test.txt
```

Na serwerze utwórz plik:

```bash
echo "hello from server" | sudo tee /srv/nfs/from_server.txt
```

Na kliencie zweryfikuj:

```bash
ls /mnt/nfs/
```

---

## Trwały mount - /etc/fstab

Dodaj wpis do `/etc/fstab` na kliencie:

```bash
sudo nano /etc/fstab
```

```
172.31.37.53:/srv/nfs    /mnt/nfs    nfs    defaults,_netdev    0    0
```

Systemd cache'uje starą wersję fstab - reload przed testem:

```bash
sudo systemctl daemon-reload
```

Przetestuj bez restartu:

```bash
sudo umount /mnt/nfs
sudo mount -a
df -h /mnt/nfs
```
