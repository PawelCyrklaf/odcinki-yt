# Kubernetes Deployment - skalowanie, rolling update i rollback

Wszystkie komendy i pliki YAML z odcinka.

---

## Plik deployment.yaml (wersja finalna z RollingUpdate)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
```

---

## Komendy

### Tworzenie i podgląd

```bash
# Zastosuj konfigurację z pliku (działa przy tworzeniu i aktualizacji)
kubectl apply -f deployment.yaml

# Sprawdź pody
kubectl get pods

# Obserwuj pody w czasie rzeczywistym (Ctrl+C żeby zatrzymać)
kubectl get pods -w

# Sprawdź ReplicaSety
kubectl get replicasets

# Sprawdź wszystkie obiekty naraz
kubectl get all
```

### Skalowanie

```bash
# Przeskaluj do 5 podów
kubectl scale deployment nginx-deployment --replicas=5

# Zastosuj zmianę replicas z pliku (plik jest źródłem prawdy)
kubectl apply -f deployment.yaml
```

### Rolling update

```bash
# Zastosuj nową wersję obrazu i od razu obserwuj
kubectl apply -f deployment.yaml && kubectl get pods -w

# Zmień obraz bez edytowania pliku
kubectl set image deployment/nginx-deployment nginx=nginx:1.25

# Sprawdź status rolloutu (blokuje terminal do zakończenia)
kubectl rollout status deployment nginx-deployment
```

### Rollback

```bash
# Sprawdź historię rolloutów
kubectl rollout history deployment nginx-deployment

# Sprawdź szczegóły konkretnej rewizji
kubectl rollout history deployment nginx-deployment --revision=3

# Dodaj opis do rewizji (dobra praktyka na produkcji)
kubectl annotate deployment nginx-deployment kubernetes.io/change-cause="nginx 1.25 - update produkcyjny"

# Cofnij do poprzedniej rewizji
kubectl rollout undo deployment nginx-deployment

# Cofnij do konkretnej rewizji
kubectl rollout undo deployment nginx-deployment --to-revision=2
```

### Diagnostyka

```bash
# Sprawdź aktualny obraz w Deploymencie
kubectl describe deployment nginx-deployment | grep Image
```

### Sprzątanie

```bash
# Usuń wszystko co było w pliku (Deployment, ReplicaSety, pody)
kubectl delete -f deployment.yaml

# Zatrzymaj klaster
minikube stop
```