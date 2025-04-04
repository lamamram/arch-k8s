#!/bin/bash

### VARS ###
uid=$(id -u)
# distro=$(echo "$(lsb_release -is)" | awk '{print tolower($0)}')
distro=$(lsb_release -is)

### FUNCS ###

do_install(){
  
  # génération du cache apt
  apt-get update -q
  
  # install des prérequis (-y confirme, -q diminue l'affichage en console)
  apt-get install -yq \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

  # téléchargement et install de la clé d'authentification des paquets
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/${distro,,}/gpg | \
       gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  # ajout du dépôt docker qui contient les paquets docker à apt
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro,,} \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

  # regénérer le cache apt pour tenir compte du nouveau dépôt
  apt-get update -q

  # install des paquets docker
  apt-get install -yq \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-compose-plugin
}

post_install(){
  hostname=$1
  normal_user=$(cat /etc/passwd | awk -F ':' '$3 == "1000" {print $1}')
  
  # ajout de l'utilisateur vagrant au groupe docker 
  # autorisé à exécuter des commandes docker sans sudo
  usermod -aG docker "$normal_user"

  cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries": ["127.0.0.1:443","$hostname:443"]
}
EOF

  cat <<EOF >> "/home/$normal_user/.bash_aliases"

alias dps='docker ps'
alias dpsa='docker ps -a'
alias drmf='docker rm -f $(docker ps -aq)'
alias dex='docker exec -it'
alias dim='docker images'
alias dipf='docker image prune -f'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs'
EOF

}

### MAIN ###

if [ "$uid" -ne 0 ]; then
  echo "lancer avec sudo !!!"
  exit 1
fi

if [ -n "$(which docker)" ]; then
  echo "docker is here !!!"
  exit 0
fi

do_install
post_install $@
