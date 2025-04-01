## nous allons utiliser une image debian12
## image de distrution FROM scratch
## BEST PRACTICE: utiliser une image + petite pour réduire la taille de l'image
## une image existe pour exécuter du code NON pour développer
FROM debian:12.10-slim

## documenter l'image / filtrer les images et les conteneurs / confiugrer le conteneur
LABEL author="matt"
LABEL created_at="2025-04-01"
LABEL stack="java"
LABEL stack.service="tomcat"

## BEST PRACTICE: utiliser des paquets + petits
## BEST PRACTICE: rassembler les créations/modifs/suppressions de fichiers/dossiers au sein des mêmes couches
## installer java (apt-get)
## et nettoyer le dépôt apt-get après
## ajouter un dossier /opt/tomcat
## injecter le fichier https://downloads.apache.org/tomcat/tomcat-9/v9.0.102/bin/apache-tomcat-9.0.102.tar.gz dans ce dossier
## décomprésser dans ce dossier sans dossier intermédiaire
# ADD https://downloads.apache.org/tomcat/tomcat-9/v9.0.102/bin/apache-tomcat-9.0.102.tar.gz /opt/tomcat
## BEST PRACTICE: travailler en flux (|) en non en fichier (&&)
## BEST PRACTICE: exécuter la commande du conteneur à venir avec un utilisateur non root
## ajouter un utilisateur tomcat avec le dossier /opt/tomcat comme home et le groupe propriétaire
## télécharger l'application sample https://tomcat.apache.org/tomcat-10.1-doc/appdev/sample/sample.war dans le dossier home 
## spécifier le propriétaire et groupe à tomcat pour le dossier /opt/tomcat 

RUN apt-get update -qq && apt-get install -yq curl openjdk-17-jre-headless && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir /opt/tomcat && \
    curl https://downloads.apache.org/tomcat/tomcat-9/v9.0.102/bin/apache-tomcat-9.0.102.tar.gz | \
    tar xz --strip-components=1 -C /opt/tomcat && \
    useradd -d /opt/tomcat -s /bin/bash -U tomcat && \
    curl https://tomcat.apache.org/tomcat-10.1-doc/appdev/sample/sample.war -o /opt/tomcat/webapps/sample.war && \
    chown -R tomcat:tomcat /opt/tomcat


## déterminer le dossier home du conteneur: /opt/tomcat/webapps
WORKDIR /opt/tomcat/webapps
## changer l'utilisateur à tomcat
USER tomcat
## persister le dossier home pour accéder ou sauvegarder les apps
# volumes créés au moment du run
VOLUME [ "/opt/tomcat/webapps" ]
## pour communiquer avec httpd avec le port par défaut de tomcat
# expose == déclarer le ou les ports utilisés par le processus sous-jacent
# Vrai ou Faux
EXPOSE 8080

## exécuter de manière dynamique (avec substitution) le binaire en foreground catalina.sh
## et ajouter la sous commande pour lancer dans le terminal courant run
CMD ["/opt/tomcat/bin/catalina.sh", "run"]

