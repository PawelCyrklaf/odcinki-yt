# logrotate - komendy z odcinka

---

## Setup

```bash
bash setup.sh
```

**setup.sh**

```bash
#!/bin/bash
sudo mkdir -p /var/log/myapp

for i in {1..200}; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') INFO: request handled id=$i" | sudo tee -a /var/log/myapp/app.log > /dev/null
done

echo "Gotowe. Rozmiar:"
ls -lh /var/log/myapp/app.log
```

---

## Jak to działa

Sprawdź jak cron odpala logrotate:

```bash
cat /etc/cron.daily/logrotate
```

Globalne domyślne dla wszystkich logów:

```bash
cat /etc/logrotate.conf
```

Co już jest w logrotate.d:

```bash
ls /etc/logrotate.d/
```

Przykład gotowego configa:

```bash
cat /etc/logrotate.d/apt
```

---

## 1. Własny config - podstawowy

Tworzymy plik `myapp`:

```
/var/log/myapp/app.log {
    rotate 3
    daily
    compress
    missingok
    notifempty
    create 640 root root
}
```

```bash
sudo cp myapp /etc/logrotate.d/
```

Wymuś rotację i pokaż co robi:

```bash
sudo logrotate -fv /etc/logrotate.d/myapp
```

Sprawdź wynik:

```bash
ls -lh /var/log/myapp/
```

---

## 2. dateext — data w nazwie pliku

```
/var/log/myapp/app.log {
    rotate 3
    daily
    compress
    missingok
    notifempty
    create 640 root root
    dateext                # ← doszło
}
```

```bash
sudo cp myapp /etc/logrotate.d/myapp
sudo rm -f /var/log/myapp/*.gz
echo "INFO: new entry" | sudo tee -a /var/log/myapp/app.log
sudo logrotate -f /etc/logrotate.d/myapp
ls -lh /var/log/myapp/
```

---

## 3. size - rotacja po rozmiarze

```
/var/log/myapp/app.log {
    rotate 3
    size 100M              # ← zmienione
    compress
    missingok
    notifempty
    create 640 root root
    dateext
}
```

---

## 4. postrotate - komenda po rotacji

```
/var/log/myapp/app.log {
    rotate 3
    daily
    compress
    missingok
    notifempty
    create 640 root root
    dateext
    postrotate                    # ← doszło
        systemctl reload nginx    # ← doszło
    endscript                     # ← doszło
}
```

Sprawdź że cron nie rotuje dwa razy w ciągu dnia:

```bash
echo "INFO: new entry" | sudo tee -a /var/log/myapp/app.log
sudo logrotate -v /etc/logrotate.d/myapp
```

Status ostatniej rotacji:

```bash
cat /var/lib/logrotate/status
```
