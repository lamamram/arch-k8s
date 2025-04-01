#!/bin/bash

#### SUPPRESSIONS #######
# test de l'existence des conteneurs si c'est vrai je supprime les conteneurs
# -q: affiche uniquement les identifiants
[[ -z $(docker ps -aq --filter name="stack-php-") ]] || docker rm -f $(docker ps -aq -f "name=stack-php-")


#### RESEAU #####



#### CONTENEURS #######
# communication entre les conteneurs
# 1/ configurer le vhost (serverName et fastcgi_pass)
# 2/ injecter le vhost dans le conteneur nginx
# 3/ injecter le fichier index.php dans le conteneur php-fpm

docker run \
       --name stack-php-fpm \
       -d --restart unless-stopped \
       -v ./index.php:/srv/index.php \
       bitnami/php-fpm:8.4-debian-12

docker run \
       --name stack-php-nginx \
       -d --restart unless-stopped \
       -p 8081:80 \
       -v ./vhost.conf:/etc/nginx/conf.d/vhost.conf \
       nginx:1.27.4-perl
