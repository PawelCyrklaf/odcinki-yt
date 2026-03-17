# Kubernetes od zera — komendy z odcinka

## Instalacja minikube

```bash
# pobierz binarke minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# zainstaluj globalnie
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# sprawdź wersję
minikube version
```

## Instalacja kubectl

```bash
# pobierz kubectl w wersji zgodnej z aktualnym stabilnym K8s
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# zainstaluj globalnie
sudo install kubectl /usr/local/bin/kubectl

# sprawdź wersję
kubectl version --client
```

## Uruchomienie klastra

```bash
# uruchom lokalny klaster (używa Dockera jako driver)
minikube start

# sprawdź czy klaster działa i jaki ma status
kubectl get nodes
```

## Pierwszy pod

```bash
# utwórz pod bezpośrednio z obrazu nginx
kubectl run moj-nginx --image=nginx

# obserwuj zmiany statusu w czasie rzeczywistym (Ctrl+C żeby wyjść)
kubectl get pods -w

# pokaż na którym nodzie działa pod i jaki ma IP
kubectl get pods -o wide

# wyświetl wszystkie zasoby w klastrze naraz (pody, serwisy, deploymenty)
kubectl get all

# szczegółowe info o podzie — Events sekcja pokaże błędy jeśli coś nie startuje
kubectl describe pod moj-nginx

# logi kontenera
kubectl logs moj-nginx

# wejdź do środka działającego kontenera
kubectl exec -it moj-nginx -- bash

# (wewnątrz poda) sprawdź że nginx faktycznie odpowiada
curl localhost

# wyjdź z kontenera
exit

# usuń pod — nie wróci, bo nie ma Deploymentu który by go pilnował
kubectl delete pod moj-nginx

# potwierdź że pod zniknął
kubectl get pods
```

## Deployment z auto-restartem

```bash
# utwórz Deployment z 2 replikami — K8s będzie pilnował żeby zawsze działały 2 pody
kubectl create deployment moj-nginx --image=nginx --replicas=2

# sprawdź pody — nazwy zawierają losowy sufiks generowany przez K8s
kubectl get pods

# usuń jednego poda i od razu obserwuj jak K8s wstawia nowego
kubectl delete pod <nazwa-poda> && kubectl get pods -w

# usuń Deployment — usuwa też wszystkie jego pody, K8s nie wstawia nowych
kubectl delete deployment moj-nginx
```

## Sprzątanie

```bash
# zatrzymaj klaster — zwalnia RAM i CPU, konfiguracja zostaje
minikube stop

# usuń klaster całkowicie — następny start buduje go od zera
minikube delete
```