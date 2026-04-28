# WireGuard — komendy z odcinka

## 1. Serwer — instalacja

```bash
apt update && apt install -y wireguard
```

---

## 2. Serwer — generowanie kluczy

Generuj klucz prywatny i publiczny w jednej komendzie — klucz prywatny trafia do pliku i jednocześnie przez `wg pubkey` generuje publiczny:
```bash
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
chmod 600 /etc/wireguard/server_private.key
```

Wyświetl klucz publiczny — będzie potrzebny po stronie klienta:
```bash
cat /etc/wireguard/server_public.key
```

---

## 3. Serwer — konfiguracja (wg0.conf)

```bash
nano /etc/wireguard/wg0.conf
```

```ini
[Interface]
PrivateKey = <WKLEJ_ZAWARTOSC_server_private.key>
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT
```

Włącz przekazywanie pakietów IPv4 — bez tego klienci VPN nie dogadają się ze sobą przez serwer:
```bash
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

Otwórz port WireGuard w firewallu:
```bash
ufw allow 51820/udp
ufw reload
```

---

## 4. Serwer — uruchomienie

Uruchom interfejs i włącz autostart przy restarcie systemu:
```bash
wg-quick up wg0
systemctl enable wg-quick@wg0
```

Sprawdź czy serwer nasłuchuje — powinieneś zobaczyć klucz publiczny i `listening port: 51820`:
```bash
wg show
```

---

## 5. Klient — instalacja i generowanie kluczy

```bash
apt install -y wireguard
```

```bash
wg genkey | tee client_private.key | wg pubkey > client_public.key
cat client_public.key
```

---

## 6. Serwer — dodanie klienta

Wróć na serwer i dopisz sekcję `[Peer]` na końcu `/etc/wireguard/wg0.conf`:

```bash
nano /etc/wireguard/wg0.conf
```

```ini
[Peer]
# Klient — laptop
PublicKey = <KLUCZ_PUBLICZNY_KLIENTA>
AllowedIPs = 10.0.0.2/32
```

Przeładuj konfigurację:
```bash
wg-quick down wg0 && wg-quick up wg0
```

---

## 7. Klient — konfiguracja i połączenie

```bash
nano /etc/wireguard/wg0.conf
```

```ini
[Interface]
PrivateKey = <ZAWARTOSC_client_private.key>
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <KLUCZ_PUBLICZNY_SERWERA>
Endpoint = <IP_SERWERA>:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
```

Połącz:
```bash
wg-quick up wg0
```

---

## 8. Weryfikacja

Ping po prywatnym adresie VPN — potwierdza że tunel działa:
```bash
ping 10.0.0.1
```

SSH przez VPN z zamkniętym portem 22 na publicznym IP:
```bash
ssh user@10.0.0.1
```

Sprawdź aktywne połączenie na serwerze — `latest handshake` i `transfer` potwierdzają że dane przepływają:
```bash
wg show
```

Rozłączenie:
```bash
wg-quick down wg0
```

---

## 9. Troubleshooting

**Brak `latest handshake` w `wg show`** — połączenie nie doszło do skutku. Sprawdź firewall na obu poziomach: UFW na serwerze i panel dostawcy (Hetzner, DigitalOcean, AWS):
```bash
ufw status
```

**Błąd przy `wg-quick up wg0`** — najprawdopodobniej wklejony klucz publiczny zamiast prywatnego w polu `PrivateKey`. Klucze wyglądają identycznie — upewnij się że bierzesz zawartość `server_private.key`, nie `server_public.key`.