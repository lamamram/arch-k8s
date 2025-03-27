# build du pipeline docker

## agent "any" => exécution sur jenkins en local

## job build d'image avec l'agent docker

* pour utiliser l'agent docker: 
  - le conteneur jenkins doit connaître docker (cli + daemon)
  - le conteneur doit utiliser le même UID:GID du docker de la VM
  ```yaml
     # compose.yml : version NAÏVE PEU SECURISEE
     ...
     user: jenkins:996
     volumes:
       ...
       - /usr/bin/docker:/usr/bin/docker
       - /var/run/docker.sock:/var/run/docker.sock
  ```

  * configuration d'un conteneur dynamique / éphémère

  ```groovy
    agent {
    docker {
        //image '<img>:<tag>'
        image 'docker:27.3.1'
        // options du docker run
        args ' -u root -v /var/run/docker.sock:/var/run/docker.sock --add-host jenkins.lan:172.17.0.1'
        // -u root: il n'y a pas de UID 1000 dans ce conteneur
        // -v ... : pour connecter le daemon docker de la VM (UNSAFE)
        // --add-host: pour connaître l'ip du host du registre
    }
  ```

  * procédure de test

  ```groovy
    steps {
        // build
        // lancement du conteneur détaché
        // attendre la fin du HealtCheck
        // filtrer le docker ps sur ce conteneur
        // regarder si c'est healthy
        // pb avec le "|"
        sh '''
        ...
        '''
    }
  ```

  * traitement en fin de procédure

  ```groovy
    // post s'excute après les steps
    post {
        // success: condition d'exécution
        success {
            // withCredentials: utilisation d'un Credential Jenkins (cf GUI ou jenkins-cli) -> de type secret text
            withCredentials([
                string(credentialsId: '<credential-id>', variable: 'ENV_VAR')
            ]) {
                sh '''
                  ... $ENV_VAR ...
                '''
            }
        }
    }
  ```


## job deployment kuberetes

### préparation de l'agent docker kubectl

1. image : bitnami/kubectl:1.30
   * jenkins accroche automatiquement les volumes du conteneur jenkins
     + en particulier sa home `/var/jenkins_home`
     + on partage la config du cluster dans la debiian `~/.kube/config` dans `/var/jenkins_home/config`
   * `-u root`  : exécution en root car pas d'utilisateur 1000
   * `--add-host autoelb.lan=192.168.1.30` : accès au cluster (pas de service dns)
   * `--entrypoint=""`: désactiver l'instruction ENTRYPOINT de l'image de base qui fait interférence avec jenkins
   * BONUS: configurer l'ip 192.168.1.30 
     + dans un variable d'environnement du conteneur jenknis, via le docker compose
     + créer un script groovy qui charge cette variable dans le pipeline
     + excuter le script dans la section `node { } ou agent { }
`
2. conditions d'exécution du job 

  * exécuter ce job avec un tag git
    + jenkins > projet > configure > ajouter un **Branch Specifier**: `*/tags/*`
  
  * ajout des condition dans le pipeline
    + condition exécutées avant l'ajout de l'agent docker
    + condition exécutées avant le mode manuel
  ```groovy
  when {
    breforeAgent true
    beforeInput true
    expression { ??? }
  }
  input {
      message "deploy this tag ?"
      submitter "admin"
  }
  ```

### Améliorations

* ajouter un **job trivy** => scan de vulnérabilité en analysant les images buildées depuis le registre
  + exporter le rapport de vulnérabilité dans un plugin jenkins
  + dans une section `post {  }`

* faire fonctionner l'exécution d'un stage conditionné par le build d'un tag et non une branche

* itérer le build d'images pour toutes les images de votre app
  + piste: utiliser un pipeline scripté != déclaratif
  + et ajouter le multithreading
  ```groovy
  stage {
    script {
      allModules.each() {
         echo it
      }
    }
  }
  ...
  stage {
    parallel {
      stage { }
      stage { }
    }
  }
  ```

* injecter des variables d'environnemnts du hôte dans le pipeline

* utilisation de Helm pour installer Prometheus / grafana dans le cluster
   + Helm le gestionnaire de paquet de k8s
   + monitorer vos pods