# TP sur Minikube / Kind

## Exploration

1. checker l'install depuis le controller **jenkins.lan**
   * `k get nodes`
   * `k cluster-info`
   * `k get pod -A`, à travers tous les namespaces
   * `k get ns`, ns => namespace

2. créer un premier pod
   * `k run <name> --image <image:tag> -- <cmd>`
   * `k run busy --image busybox -- sleep infinity`
   * checker: `k get pod <name> -o wide|yaml|jsonpath '{{ .xxxx.xxx[] }}'`
   * checker: `k describe pod <name>`
   * checker la ressource (doc): `k explain pod`
   * checker dans le pod: `k exec -it busy -- /bin/sh`
   * supprimer le pod: `k delete pod busy`

3. voir le conteneur dans le noeud
   * trouver le noeud sur lequel le pod est installé `k get pods busy -o wide`
   * connexion ssh sur le noeud: `vagrant ssh | ssh`
   * `crictl ps`

## IaC POD

1. Manifeste

   * dry-run(s)
     + **client**: command not run && apiserver not validated
     + **server**: command not run && apiserver validated (error possible)
     + **none**: command run && apiserver validated but output

   * générer un **manifeste (YAML)** `k run busy --image busybox --dry-run=client -o yaml > /vagrant/k8s/busy.yml`
   * retravailler/renommer le manifeste 
   * et ensuite appliquer depuis le manifeste `k apply -f /vagrant/k8s/busy.yml`

2. plusieurs conteneurs
   * reprendre le fichier `busy.yml` et le copier en `busy-dual.yml`
   * `k apply -f /vagrant/k8s/busy-dual.yml`
      + constater les `2/2` sur le `k get pods busy-dual` => 2 conteneurs dans le pod

   * avec plusieurs conteneur dans un pod, distinguer un conteneur
   * `k logs busy-dual -c web`
   ```bash
   k exec -it busy-dual -c busy -- /bin/sh
   # wget -O - http://localhost:80
   # les 2 conteneurs partagent le namespace "net" en particulier les ports
   ```
   

3. volumes de type emptyDir
   
   ```bash
   k exec -it busy-dual -c busy -- /bin/sh
   # echo "content" > /mnt/fic
   ...
   k exec -it busy-dual -c web -- /bin/sh
   # cat /mnt/fic
   ```

## Deploiement: Deployment simple

1. génération

```bash
k create deployment app-nginx \
  --image nginx \
  --dry-run=client -o yaml > /vagrant/k8s/dpl-nginx.yml 
# voir le déploiement et les pods
k get deployments.apps,pods
```


2. élaguer pour avoir l'état du fichier 

### mise à jour du déploiement

1. mettre en échelle manuelle : 

* `k scale deployment app-nginx --replicas 3`
  => pas immutable ET pas de révision (historique des travaux)

* `k edit deployments.apps app-nginx`
  => modif directe de la config de la ressource dans etcd
  => procédure d'urgence
  => sans filet !!
  => pas de révision

* MIEUX : `k apply -f ...` : écraser l'état (IMMUTABLE)

2. mise à jour de l'image : 

* `k set image deployment/app-nginx nginx:1.27.4-perl`
  + => trace de changement mais pas d'explication: `k rollout history deployment app-nginx`

* MIEUX: IAC `k apply -f ...` + ajout `metada.annotations.kubernetes.io/change-cause`
  + `k rollout history deployment app-nginx` => voit la description du changement
  + `k rollout undo deployment/app-nginx --to-revision 1`
  + documenter le rollback a posteriori: `k annotate  deployments.apps app-nginx kubernetes.io/change-cause="rollback to 1.27.4-perl" --overwrite`
  
3. mécanique de la **rolling update**

![ici](./schema.png)

### mise en réseau

* exposition au sens k8s != exposition au sens docker
* exposition au sens k8s == **publication** au sens docker

* ajouter un **service** à un déploiement

```bash
k expose deployment app-nginx \
--port 80 \
--target-port 80 \
--dry-run=client -o yaml > /vagrant/k8s/svc-nginx.yml

# voir le deploiement, les pods et le service
k get deployments.apps,pods,svc
```

#### par défaut: on a un **ClusterIP**: 
  + une IP dispo dans le cluster
  + un port
  + un dns qui est le `metadata.name` du service accessible dans le namespace
  + un Fully Qualified Domain Name: accessible dans la totalité du cluster => il faudra ajouter des **NetPolicies**
  + ce service ne permet pas d'entrer le flux externe => communication inter-pod

* test: `k exec busy -- wget -O - http://app-nginx`


* test (FQDN from outside namespace): `k exec busy-dflt -- wget -O - http://app-nginx.default.svc.cluster.local`
  => A PRIORI communication inter namespace

#### le NodePort: 

* rediriger le port du clusterIP sur un port sur tous les noeuds worker, sur toutes les interfaces (privées / publiques) par défaut

* on ajoute: `spec.type: NodePort`

#### on ajoute un LB: load balancer

* changer le type de service : `spec.type: LoadBalancer`

* utilisation du manifest du LB MetalLB

[ici](https://github.com/metallb/metallb)

* installation: `kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml`

* checks:

```bash
## vérif des pods (1 par noeud)
kubectl get pod -n metallb-system
## vérif de la ressource ipadresspoll (pour les ips externes uniques de nos déploiements)
k get customresourcedefinition.apiextensions.k8s.io/ipaddresspools.metallb.io -n metallb-system
## pas de  pool par défaut
kubectl get ipaddresspools -n metallb-system
```

* configuration de la pool d'ip en mode couche 2 (L2): trouver un plage d'ips du sous réseau local (192.168.x.y ou 10.x.y.z)

  + `k apply -f /vagrant/k8s/ipaddresspool-metallb.yml`

* `k apply -f /vagrant/k8s/svc-nginx.yml`
  + `k get deployments.apps,pods,svc` => on voit l'adresse du bridge externe du load Balancer => le nginx est exposé au sens k8s

### synthèse

* pour déployer une application (n-tiers) conteneurisée avec k8s
  + un **Deployment** pour la couche **utilisateur** (serveur web) + un service de type **LoadBalancer**
  + on peut aussi ajouter la couche **logique** (serveur de l'app - code) dans le déploiement précédent en particulier au sein du pod configuré dans le déploiement
  + un **Statefull** qui va gérer la réplication d'une bdd (statefull) donc avec 2 configurations différentes (manager/worker) + service de type **ClusterIP** pour la connexion entre nginx/php en interne dans le cluster




## gestion centralisée d'une application dans k8S

* utilisation d'un manifeste **kustomization.yml**
  + centralisant les ressources de l'application
  + lancement `k apply -k .` dans l'emplacement du manifeste
  + test: `k kustomize`
  + désinstaller: `k delete -k .`


## installer prometheus / grafana sur le cluster

* helm installé (cf install_k8s.sh)
* **HELM** est un gestionnaire de paquet pour les *collections de ressources k8s* , A.K.A **Charts**

### gérer les dépôt et le cache (commme apt-get)

```bash
# ajout d'un dépôt tiers 
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm update repo
```

### créer des valeurs custom pour notre cluster

* `helm show values prometheus-community/kube-prometheus-stack`
* pg-custom-values.yml

```yaml
prometheus:
  service:
    type: NodePort
grafana:
  service:
    type: NodePort
```

* installer avec ces valeurs

```bash
# créer un namespace pour le monitoring
k create ns monitoring

# placer le namespace monitoring comme ns par défaut
# permet d'éviter le -n monitoring sur toutes les commandes !
k config set-context --current --namespace=monitoring

# install dry-run pour avoir la structure d'un chart
# utilisant massivement des templates !!!
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -f /vagrant/k8s/pg-custom-values.yml -n=monitoring --dry-run=client -o yaml > /vagrant/k8s/pg-chart.yml

# Installation avec upgrade dans le ns monitoring déjà configuré et sans dry-run pour le faire vraiment !!!
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack  -f /vagrant/k8s/pg-custom-values.yml 

```

### accéder via le nodePort (n'importe quel noeud sur les ports)

* `k get svc`: TYPE => NodePort , PORTS => xxxxx / yyyyy
* `k get nodes -o wide`: EXTERNAL-IP => x.y.z.t
* accéder à `x.y.z.t:xxxxxx` pour prometheus et `x.y.z.t:yyyyy` pour Grafana

### authentfication sur Grafana

```bash
## username
k get secret kube-prometheus-stack-grafana -o jsonpath="{.data.admin-user}" | base64 --decode ; echo
# => admin

k get secret kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
# => prom-operator
```
* observer les Dashboards dans grafana pour voir les ressources de base du cluster !!!





