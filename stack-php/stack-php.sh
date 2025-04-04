#!/bin/bash

#### SUPPRESSIONS #######
# test de l'existence des conteneurs si c'est vrai je supprime les conteneurs
# -q: affiche uniquement les identifiants
[[ -z $(docker ps -aq --filter name="stack-php-") ]] || docker rm -f $(docker ps -aq -f "name=stack-php-")


[[ -z $(docker network ls -q --filter name="stack-php") ]] || docker network rm stack-php
#### RESEAU #####

docker network create \
       --driver=bridge \
       --subnet=172.18.0.0/24 \
       --gateway=172.18.0.1 \
       stack-php

#### CONTENEURS #######
# communication entre les conteneurs
# 1/ configurer le vhost (serverName et fastcgi_pass)
# 2/ injecter le vhost dans le conteneur nginx
# 3/ injecter le fichier index.php dans le conteneur php-fpm
# 4/ créer le réseau stack-php et associer les conteneurs à ce réseau
# 5/ injecter les variables d'environnement dans le conteneur mariadb
# 6/ utiliser le mécanisme d' "entrypoint" pour le fichier mariadb-init.sql
# 7/ créer un volume nommé db_data pour la persistance des données

# --env MARIADB_USER=test \
# --env MARIADB_PASSWORD=roottoor \
# --env MARIADB_DATABASE=test \
# --env MARIADB_ROOT_PASSWORD=roottoor \

docker run \
       --name stack-php-mariadb \
       -d --restart unless-stopped \
       --env-file .env \
       --net stack-php \
       -v ./mariadb-init.sql:/docker-entrypoint-initdb.d/mariadb-init.sql:ro \
       -v db_data:/var/lib/mysql \
       mariadb:11-ubi

docker run \
       --name stack-php-fpm \
       -d --restart unless-stopped \
       --net stack-php \
       -v ./index.php:/srv/index.php:ro \
       bitnami/php-fpm:8.4-debian-12


docker run \
       --name stack-php-nginx \
       -d --restart unless-stopped \
       -p 8081:80 \
       --net stack-php \
       -v ./vhost.conf:/etc/nginx/conf.d/vhost.conf:ro \
       nginx:1.27.4-perl