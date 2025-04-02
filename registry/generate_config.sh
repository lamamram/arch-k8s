#!/bin/bash

if [[ $1 -eq "docker_auth" ]]; then

    DOCKER_AUTH_CERTS=/vagrant/docker_auth_certificates
    DOCKER_AUTH_CONF_DIR=/vagrant/docker_auth_config
    DOCKER_AUTH_CONF_URL=https://raw.githubusercontent.com/cesanta/docker_auth/refs/heads/main/examples/simple.yml

    if [[ ! -d "$DOCKER_AUTH_CERTS" ]]; then
    echo -e "Generate TLS certs for docker auth ...\n"
    mkdir $DOCKER_AUTH_CERTS
    openssl req \
        -newkey rsa:4096 \
        -nodes \
        -keyout $DOCKER_AUTH_CERTS/server.key \
        -x509 \
        -days 3650 \
        -out $DOCKER_AUTH_CERTS/server.pem \
        -subj "/CN=registry.auth"
        # -subj "/C=EU/ST=France/L=Nantes/O=registry/CN=registry.auth"
    fi

    # Fetch sample configuration
    if [[ ! -d "$DOCKER_AUTH_CONF_DIR" ]]; then
        echo -e "Install & Configure for docker auth ...\n"
        mkdir $DOCKER_AUTH_CONFIG_DIR
        curl -sfo "$DOCKER_AUTH_CONFIG_DIR/simple.yml" $DOCKER_AUTH_CONF_URL
        sed -i 's|/path/to/|/ssl/|g' "$DOCKER_AUTH_CONFIG/simple.yml"
    fi
fi

if [[ $1 -eq "install_certs" ]]; then

    CACERTS_DIR=/usr/local/share/ca-certificates
    DOCKER_CERTS_DIR=/etc/docker/certs.d
    REGISTRY_HOST=docker.lan
    REGISTRY_PORT=443

    # install tls cert
    if [[ ! -f "$CACERTS_DIR/registry.crt" ]]; then
    echo -e "install TLS certs in store in debian... \n"
    sudo cp certs/registry.crt $CACERTS_DIR
    sudo update-ca-certificates
    fi

    if [[ ! -d "$DOCKER_CERTS_DIR/$REGISTRY_HOST:$REGISTRY_PORT" ]]; then
    echo -e "Install CA TLS cert for docker daemon ...\n"
    sudo mkdir -p "$DOCKER_CERTS_DIR/$REGISTRY_HOST:$REGISTRY_PORT"
    sudo cp certs/registry.crt "$DOCKER_CERTS_DIR/$REGISTRY_HOST:$REGISTRY_PORT/ca.crt"
    fi
fi

if [[ $1 -eq "insecure_daemon" ]]; then
    # daemon config
    if [[ ! -f "/etd/docker/daemon.json" ]]; then
        echo -e "configure Docker Daemon... \n"
        cat <<EOF | sudo tee /etc/docker/daemon.json
{
"insecure-registries": ["127.0.0.1:443","docker.lan:443"]
}
EOF
        sudo systemctl restart docker
    fi
fi

if [[ $1 -eq "credsStore" ]]; then

    # install latest version
    sudo curl -o /usr/bin/docker-credential-pass -LO $(curl -s https://api.github.com/repos/docker/docker-credential-helpers/releases/latest | grep browser_download_url | grep docker-credential-pass | grep linux-amd64 | cut -d '"' -f 4)
    sudo chmod a+x /usr/bin/docker-credential-pass

    # prerequisites gnupg2 pass
    apt-get -qq update
    apt-get -yq install gnupg2 pass

    # configure docker client
    mkdir -p /home/vagrant/.docker
    cat <<EOF > ~/.docker/config.json
{
    "credsStore": "pass"
}
EOF
    # create gpg2 key to initiate the pass passwordstore
    gpg2 --quick-gen-key --batch --passphrase 'R00tt00R' credstore@docker.lan
    ID=$(gpg2 --list-keys | grep -oE "[A-F0-9]+$")
    pass init $ID

    # check
    docker-credential-pass list # {}
    
    # check passphrase if exists through prompt ! otherwise KO !!!
    echo "export GPG_TTY=$(tty)" >> ~/.bashrc
    source ~/.bashrc
    # add gnupg agent
    cat <<EOF > ~/.gnupg/gpg-agent.conf
enable-ssh-support
default-cache-ttl 300
max-cache-ttl 1200
EOF
    gpgconf --kill gpg-agent
    # eval $(gpg-agent –daemon)
fi