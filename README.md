# formation architecure Docker/K8S

## progression de la semaine

![](./global-schema.png)

## installation du système

1. jour 1-3

* `vagrant up jenkins.lan`: commenter les lignes 116-120 parce qu'on a pas de cluster
pour le moment

2. jour 3-5

* `vagrant halt jenkins.lan`
* `vagrant up`: les 4 machines
* décommenter les lignes 116-120 pour installer le cluster k8s
* `vagrant provision --provision-with install-kubespray jenkins.lan`

## troubleshooting

### installation du cluster qui ne termine pas

1. `vagrant halt`: pour les 4 machines
2. ```bash
   vagrant destroy -f cpane.lan
   vagrant destroy -f worker1.lan
   vagrant destroy -f worker2.lan
   ```
3. checker:
   + vos adresses ips
   + checker la variable etcHosts pour que çà corresponde avec vos ips

4. relancer
   + `vagrant up`: 3 création et 1 lancement

5. rechecker
```bash
vagrant ssh cpane.lan
# sur la VM
cat /etc/hosts
docker ps
```

6. reprovisionner

* corrections liées à la clé privée **ctrl_key_path**
* `vagrant provision --provision-with get_pkey jenkins.lan`
* `vagrant provision --provision-with install-kubespray jenkins.lan`

### simuler la connexion ansible

* sur la VM jenkins.lan
* checker l'installation de ansible + cnx SSH + l'inventaire
```bash
cd ~
source venv/bin/activate
ansible \
        --private-key ~/.ssh/id_rsa \
        -i kubespray/inventory/mycluster/inventory.ini \
        -u vagrant \
        -m ping \
        cpane.lan
```

### upgrade la version de kubectl

* dans la VM **jenkins.lan**

```bash
sudo apt-get autoremove kubectl
KUBE_CTL_VERSION="v1.31"
curl -fsSL "https://pkgs.k8s.io/core:/stable:/$KUBE_CTL_VERSION/deb/Release.key" | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBE_CTL_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list 2>&1 > /dev/null
sudo apt-get update -qq 2>&1 > /dev/null
sudo apt-get install -yqq kubectl 2>&1 > /dev/null

# checker
kubectl version
kubectl get nodes
```

### expérimenter avec Minikube

cas windows: (ici)[https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download#Service]

* création du dossier `c:\minikube`
```powershell
New-Item -Path 'c:\' -Name 'minikube' -ItemType Directory -Force
Invoke-WebRequest -OutFile 'c:\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing
```

* ajouter le dossier `c:\minikube` dans le PATH (Interface Graphique)

* lancer minikube comme VM virtualbox `minikube start --driver=virtualbox --no-vtx-check`

* suppression du cluster :  `minikube delete`

* toujours préfixer les commandes k8s avec minijube 
`minikube kubectl -- <reste de la commande normale>`

### utilisation de l'extenxion YAML pour kubectl

1. installer l'extension YAML de RedHat
2. cas VSCODE: ajouter une config dans vos settings user => Ctrl+Shift+P

```json
"yaml.schemas": {
  "Kubernetes": "*.yml"
}
```
3. redémarrer VSCODE