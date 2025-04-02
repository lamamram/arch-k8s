# registry docker

## build

* gestion de TLS
* gestion d'une authentfication

* `docker login URL du registre https ou :5000 avec --username --password`

## utilisations des images

1. il faut renommer une image en tant que référence pour pousser sur le registre
   l'image doit être préfixée par le **nom_de_domaine:port** et
   on peut crée des noms d'espace `<nom_de_domaine:port>/name/space/<basename>:<tag>`   
   `docker tag <image> <new_reference>`

2. pousser une fois qu'on sera autentifié
   `docker push <new_reference>`

   * ou build et push on un coup `docker build -t <nom_de_domaine:port>/name/space/<basename>:<tag> --push .`

3. utiliser l'image depuis `docker pull`

## utilisation du TLS

* warning pour un certif auto signé == certificat de développement crée par nous même
  => il n'y a pas de certificat `ca.crt` autorité de certification 
1. modifier ou créer le fichier `/etc/docker/daemon.json`

```
{
   "insecure-registries": ["docker.lan:443"]
}
# sudo systemctl daemon-reload
# sudo systemctl restart docker
```

ajouter le certificat côté client (autorité de certification locale)
```
cd /vagrant/registry
sudo mkdir -p /etc/docker/certs.d/docker.lan:443
sudo cp  certs/registry.crt /etc/docker/certs.d/docker.lan:443/ca.crt
```

refabriquer un htpasswd utiliser un container httpd => 
`htpasswd -Bbn testuser password > htpasswd`

### api registry

```bash
# see images
curl -kX GET \
     -u "testuser:password" \
     https://docker.lan:443/v2/_catalog

# see tags of an image
curl -kX GET \
     -u "testuser:password" \
     https://docker.lan:443/v2/<image-name>/tags/list

# see digests conten of a tag
curl -kX GET \
     -u "testuser:password" \
     https://docker.lan:443/v2/<image-name>/manifests/<tag-name>

# display digests directly + header accept v2 => response headers (--I) (-s silent) (-k : disable tls)
curl -skIX GET \
     -u "testuser:password" \
     -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
     https://docker.lan:443/v2/<image-name>/manifests/<tag-name> | awk '/^Docker-Content-Digest/ {print $2}'

OU

curl -skIX GET \
     -u "testuser:password" \
     -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
     https://docker.lan:443/v2/<image-name>/manifests/<tag-name> | awk '/^docker-content-digest/ {print $2}'


# IDEM pour multi-platform build
curl -skIX GET \
     -u "testuser:password" \
     -H "Accept: application/vnd.oci.image.manifest.v1+json" \
     -H "Accept: application/vnd.oci.image.index.v1+json" \
     https://docker.lan:443/v2/<image-name>/manifests/<tag-name> | awk '/^docker-content-digest/ {print $2}'

# soft delete tag
curl -kX DELETE \
     -u "testuser:password" \
     https://docker.lan:443/v2/<image-name>/manifests/<v2_digest>

# hard delete
docker compose exec registry bin/registry garbage-collect /etc/docker/registry/config.yml 
```