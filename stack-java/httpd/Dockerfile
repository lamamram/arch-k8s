# MULTISTAGING BUILD !!!
# on va utiliser une image auxilliaire (sidecar)
# qu'on appelle stage a priori numéroté à partir de 0
# stage qu'on va nommer avec un alias AS curl
FROM shakefu/curl-static AS curl

## travailler dans l'image stage curl .... (compilation ...)

# FROM scratch => pour les images de distro, ou app exec binaire (c / c++ / go ...)
FROM httpd:2.4

## documentation / filtre / configurations dynamiques
LABEL author="matt"
LABEL created="2025-03-18"
LABEL stack="java"
LABEL stack.version="1.0"

## écraser le httpd.conf natif de l'image de base avec ma propre conf
# COPY ./httpd.conf /usr/local/apache2/conf
# utiliser le .dockerignore dans ce cas !!!
COPY . /usr/local/apache2/conf

## ajouter le dossier /usr/local/apache2/conf/sites
RUN mkdir /usr/local/apache2/conf/sites

## ajouter le virtualhost tomcat
COPY ./java_app.conf /usr/local/apache2/conf/sites

## rapatrier le binaire curl du stage "curl" dans l'image httpd
##               src: shakefu/curl-static | dest: sur httpd
COPY --from=curl /usr/local/bin/curl /usr/local/bin/curl

## déclarer les ports écoutés par le httpd
## 80 est vrai et 443 est faux => cf Listen de httpd.conf
EXPOSE 80 443

## lancement d'une commande est NON SUBSTITUABLE par la commande potentielle du docker run
# ENTRYPOINT [ "httpd", "-D", "FOREGROUND" ]
# ENTRYPOINT [ "httpd" ]
## créer un script de type entrypoint.sh pour préconfigurer le conteneur au lancement
# ENTRYPOINT [ "/.../.../docker-entrypoint.sh" ]
## lancement d'une commande est SUBSTITUABLE par la commande potentielle du docker run
CMD [ "httpd", "-D", "FOREGROUND" ]
# CMD [ "-D", "FOREGROUND" ]

# HEALTHCHECK périodique => sans "retries"
# REM: le fichier /etc/hosts (dns locaux) n'est pas hérité depuis le host (VM)
# REM2: le fichier /etc/resolv.conf (services dns) est hérité depuis le host (VM)
HEALTHCHECK \
            --start-period=5s \
            --timeout=10s \
            --interval=20s \
            CMD curl http://127.0.0.1:80



