# nftables — spis poleceń z odcinka

```bash
systemctl status nftables
```
Sprawdza stan usługi nftables — czy jest aktywna i czy startuje przy restarcie.

---

```bash
systemctl enable --now nftables
```
Włącza usługę i uruchamia ją natychmiast. Bez tego reguły znikają po restarcie.

---

```bash
nft flush ruleset
```
Czyści wszystkie tablice i reguły — czyste slate przed budowaniem własnego rulesetu.

---

```bash
nft add table inet filter
```
Tworzy tablicę obsługującą IPv4 i IPv6 jednocześnie.

---

```bash
nft add chain inet filter input { type filter hook input priority 0 \; policy accept \; }
```
Tworzy chain przechwytujący ruch przychodzący. `policy accept` na starcie — gdybyś ustawił `policy drop` przy pustym chainie, SSH pada natychmiast.

---

```bash
nft add rule inet filter input ct state established,related accept
```
Wpuszcza odpowiedzi na połączenia zainicjowane przez serwer. Bez tej reguły `apt install` nie może pobrać paczek.

---

```bash
nft add rule inet filter input iif lo accept
```
Wpuszcza ruch na interfejsie loopback. Bez tego lokalne połączenia między aplikacjami padają.

---

```bash
nft add rule inet filter input tcp dport 22 accept
```
Otwiera port SSH. Musi być przed `policy drop`.

---

```bash
nft add rule inet filter input icmp type echo-request accept
nft add rule inet filter input icmpv6 type echo-request accept
```
Pozwala na ping — osobne reguły dla IPv4 i IPv6.

---

```bash
nft chain inet filter input { policy drop \; }
```
Ustawia policy drop — blokuje cały ruch niepasujący do reguł. Dodawać zawsze po wszystkich regułach.

---

```bash
nft list ruleset
```
Wyświetla aktywne reguły.

---

```bash
nft list ruleset -a
```
Wyświetla aktywne reguły z numerami handle — potrzebne przed usunięciem konkretnej reguły.

---

```bash
nft add rule inet filter input tcp dport { 80, 443 } accept
```
Otwiera porty HTTP i HTTPS jedną regułą. Nawiasy klamrowe to zestaw portów.

---

```bash
nft delete rule inet filter input handle 7
```
Usuwa regułę po numerze handle. Handle sprawdzać zawsze przed usunięciem — są dynamiczne.

---

```bash
echo "flush ruleset" > /etc/nftables.conf
nft list ruleset >> /etc/nftables.conf
```
Zapisuje aktualny ruleset do pliku konfiguracyjnego. `flush ruleset` na początku zapobiega duplikatom przy każdym załadowaniu.

---

```bash
nft -f /etc/nftables.conf
```
Ładuje konfigurację z pliku — tak jak robi to usługa przy starcie systemu.