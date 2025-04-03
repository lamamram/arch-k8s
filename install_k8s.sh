IP_CPANE=$(cat /etc/hosts | grep cpane | awk '{print $1}')

prepare_kubespray(){
    
    if [[ ! -d "$HOME/kubespray" ]]; then
        echo
        echo "## 1. Git clone kubepsray"
        git clone https://github.com/kubernetes-sigs/kubespray.git
        # chown -R "$USER:$USER" "$HOME/kubespray"
    fi

    if [[ ! -d "$HOME/venv" ]]; then
        echo
        echo "## 2. Install requirements"
        ## installation python d'ansible
        ## ajout d'un environnement virtuel:
        #   - dossier qui centralise les binaires (python3, pip3) et les dépendances
        #   - création du dossier venv
        #   - activation du venv: redirection du terminal sur les binaires (détournement du PATH)
        python3 -m venv venv
        source ./venv/bin/activate
        # installation des paquets python nécéssaires à ansible dans le venv
        pip3 install --quiet -r kubespray/requirements.txt
        ## technique alternative : pipx => install dans un environnement à la volée
    fi

    INVENTORY_FILE="$HOME/kubespray/inventory/mycluster/inventory.ini"
    if [[ ! -f $INVENTORY_FILE ]]; then
        echo
        echo "## 3. ANSIBLE | copy sample inventory"
        cp -rfp "$HOME/kubespray/inventory/sample" "$HOME/kubespray/inventory/mycluster"

        grep "k8s.cpane.lan" $INVENTORY_FILE > /dev/null
        if [[ "$?" -ne 0 ]]; then
            echo
            echo "## 4. ANSIBLE | change inventory"
            cat /etc/hosts | grep cpane | awk '{print $2" ansible_host="$1" ip="$1" etcd_member_name=etcd"NR}' > $INVENTORY_FILE
            cat /etc/hosts | grep worker | awk '{print $2" ansible_host="$1" ip="$1}' >> $INVENTORY_FILE

            echo "[kube_control_plane]" >> $INVENTORY_FILE
            cat /etc/hosts | grep cpane | awk '{print $2}'>> $INVENTORY_FILE

            echo "[etcd]" >> $INVENTORY_FILE
            cat /etc/hosts | grep cpane | awk '{print $2}'>> $INVENTORY_FILE

            echo "[kube_node]" >> $INVENTORY_FILE
            cat /etc/hosts | grep worker | awk '{print $2}'>> $INVENTORY_FILE

            echo "[calico_rr]" >> $INVENTORY_FILE
            echo "[k8s_cluster:children]" >> $INVENTORY_FILE
            echo "kube_control_plane" >> $INVENTORY_FILE
            echo "kube_node" >> $INVENTORY_FILE
            echo "calico_rr" >> $INVENTORY_FILE

            echo
            echo "## 5.x ANSIBLE | active external LB"
            sed -i s/"## apiserver_loadbalancer_domain_name: \"elb.some.domain\""/"apiserver_loadbalancer_domain_name: \"autoks.lan\""/g kubespray/inventory/mycluster/group_vars/all/all.yml
            sed -i s/"# loadbalancer_apiserver:"/"loadbalancer_apiserver:"/g kubespray/inventory/mycluster/group_vars/all/all.yml
            sed -i s/"#   port: 1234"/"  port: 6443"/g kubespray/inventory/mycluster/group_vars/all/all.yml
        fi
    fi
}

create_ssh_for_kubespray(){

    if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
        echo 
        echo "## 6. SSH | ssh private key and push public key"
        sudo -u $USER bash -c "ssh-keygen -b 2048 -t rsa -f .ssh/id_rsa -q -N ''"
        mv "$HOME/$1" "$HOME/.ssh"
        chmod 600 "$HOME/.ssh/$1"
        for srv in $(cat /etc/hosts | grep -E "cpane|worker" | awk '{print $2}');do
            cat "$HOME/.ssh/id_rsa.pub" | ssh -i "$HOME/.ssh/$1" -o StrictHostKeyChecking=no "$USER@$srv" -T "tee -a >> $HOME/.ssh/authorized_keys"
        done
    fi
}

run_kubespray(){

    echo
    echo "## 7. ANSIBLE | Run kubepsray"
    ## EXPLICATIONS
    # 1/ sudo su - vagrant: permet de s'assurer que la commande ansible va être lancée par l'utilisateur vagrant du contrôleur
    # 2/ bash -c: quand on arrive dans le compte vagrant on invoque un bash, pour être sûr d'être dans un bash
    # 3/ source .../activate: nouveau bash donc il faut réactiver le venv sinon le bash ne voit pas les paquets ansible !!!
    # 4/ cd kubespray: pour activer la configuration ansible.cfg
    #    - algorithme de découverte de ansible.cfg: ./ansible.cfg,~/.config/ansible.cfg
    #    - algorithme de découverte des rôles sans ansible.cfg: ./playbooks/roles : FALSE !!!
    #    - avec ansible.cfg: les rôles sont à la racine de kubespray
    # 5/ ansible-playbook [] cluster.yml : lancement du playbook central
    #    - i ... : on demande explicitement l'inventaire à cause du ansible.cfg (.ini ignored)
    #    - b: BECOME: je demande un augmentation de privilège: pour les tâches qui nécessitent le SUDO
    #      + cas simple car on a un compte vagrant avec sudo sans mdp => sinon -e "ansible_become_pass=$ANSIBLE_SUDO_PASS"
    #    - -u vagrant: compte vagrant sur les cibles (cluster) 
    sudo su - $USER bash -c "source ./venv/bin/activate;cd kubespray;ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/mycluster/inventory.ini -b -u $USER cluster.yml"
}

install_kubectl(){

    if [[ -z $(which kubectl) ]]; then
        KUBE_CTL_VERSION="v1.31"
        echo
        echo "## 8. KUBECTL | Install"
        sudo apt-get update -qq 
        sudo apt-get install -yqq apt-transport-https curl gnupg2
        curl -fsSL "https://pkgs.k8s.io/core:/stable:/$KUBE_CTL_VERSION/deb/Release.key" | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBE_CTL_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list 2>&1 > /dev/null
        sudo apt-get update -qq 2>&1 > /dev/null
        sudo apt-get install -yqq kubectl 2>&1 > /dev/null
        
        ## installation du context k8s: ensemble des informations pour connecter le cluster
        mkdir -p "$HOME/.kube"
        # chown -R "$USER:$USER" "$HOME/.kube"
        
        echo
        echo "## 9. KUBECTL | copy context with cert"
        ssh -o StrictHostKeyChecking=no -i "$HOME/.ssh/id_rsa" "$USER@${IP_CPANE}" "sudo cat /etc/kubernetes/admin.conf" > "$HOME/.kube/config"
        chmod 600 "$HOME/.kube/config"
    fi
}

install_helm(){

    if [[ -z $(which helm) ]]; then
        HELM_VERSION="v3.14.0"
        wget "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz"
        tar xf "helm-$HELM_VERSION-linux-amd64.tar.gz"
        sudo mv linux-amd64/helm /usr/local/bin
        rm -fr "helm-$HELM_VERSION-linux-amd64.tar.gz" linux-amd64
    fi
}

install_autocomplete(){

    grep "alias k=kubectl" "$HOME/.bashrc" > /dev/null
    if [[ "$?" -ne 0 ]]; then

        echo "" >> "$HOME/.bashrc"

        cat <<EOF >> "$HOME/.bashrc"
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
source <(helm completion bash)

export LS_OPTIONS='--color=auto'
EOF
        source "$HOME/.bashrc"
    fi
}

prepare_kubespray
create_ssh_for_kubespray $1
run_kubespray
install_kubectl
install_helm
install_autocomplete

