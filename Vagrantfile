## Toute commande doit-ere exécution dans le répertoire contenant le Dockerfile
# vagrant up
# vagrant halt
# vagrant destroy
# vagrant global-config
#----------------------
# vagrant ssh [NAME|ID]
Vagrant.configure(2) do |config|

  ## VARIABLES

  # int = "nom de l'interface réseau connectée au routeur (ip a || ipconfig /all)"
  # ip = "adresse ip disponible sur le sous réseau local (ping pour tester)"
  # cidr = "24 (si masque réseau en 255.255.255.0)"
  int = "Intel(R) Ethernet Connection (7) I219-LM #2"
  range = "192.168.1.5"
  cidr = "24"
  
  ctrl_subject = "jenkins"
  ctrl_image = "ml-registry/#{ctrl_subject}"
  ctrl_version = "1.2"
  ctrl_hostname = "#{ctrl_subject}.lan"
  # clé de base de vagrant pour transférer la clé privée d'ansible !!!
  ctrl_key_path = "~/.vagrant.d/boxes/ml-registry-VAGRANTSLASH-debian12-plus/1.3/amd64/virtualbox"
  ctrl_key_name = "vagrant_private_key"
  cluster_image = "ml-registry/debian12-plus"

  # paquets et configuration pour les 4 machines
  common = <<-SHELL
  apt update -qq 2>&1 >/dev/null
  apt install -y -qq net-tools telnet git python3-pip python3-venv 2>&1 >/dev/null
  echo "autocmd filetype yaml setlocal ai ts=2 sw=2 et" > /home/vagrant/.vimrc
  sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
  systemctl restart sshd
  SHELL

  # prérequis RAM > 1.6 GO, CPU >= 1
  NODES = [
    { :hostname => "cpane.lan", :ip => "#{range}1", :mem => 2048, :cpus => 2 },
    { :hostname => "worker1.lan", :ip => "#{range}2", :mem => 1800, :cpus => 1 },
    { :hostname => "worker2.lan", :ip => "#{range}3", :mem => 1800, :cpus => 1 },
  ]

  # collecte des dns locaux dans les 4 machines
  etcHosts = ""
  NODES.each do |node|
    etcHosts += "echo '" + node[:ip] + "   " + node[:hostname] + " autoks.lan' >> /etc/hosts" + "\n"
  end
  etcHosts += "echo '" + "#{range}0" + " " + "#{ctrl_hostname}" + "' >> /etc/hosts" + "\n"

  ## MAIN

  # installation des machines du cluster
  NODES.each do |node|
    config.vm.define node[:hostname] do |machine|

      machine.vm.provider "virtualbox" do |v|
        v.customize [ "modifyvm", :id, "--cpus", node[:cpus] ]
        v.customize [ "modifyvm", :id, "--memory", node[:mem] ]
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        # v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        v.customize ["modifyvm", :id, "--name", node[:hostname] ]
      end
      machine.vm.hostname = node[:hostname]
      machine.vm.box = "#{cluster_image}"
      # machine.vm.network "private_network", ip: node[:ip]
      machine.vm.network "public_network", bridge: "#{int}",
        ip: node[:ip],
        netmask: "#{cidr}"
        machine.ssh.insert_key = false

      # for all
      machine.vm.provision "shell", inline: etcHosts
      machine.vm.provision "shell", inline: common
      # pour que k8s puisse utiliser containerd
      machine.vm.provision "shell",
        path: "install_docker.sh",
        args: ["#{ctrl_hostname}"],
        reboot: true
    end
  end

  # CONTROLLER
  [
    ["#{ctrl_hostname}", "#{range}0", "2048", "2"],
  ].each do |hostname,ip,mem,cpus|
    
    config.vm.define "#{hostname}" do |machine|

      machine.vm.provider "virtualbox" do |v|
        v.name = "#{hostname}"
        v.memory = "#{mem}"
        v.cpus = "#{cpus}"
        v.customize ["modifyvm", :id, "--ioapic", "on"]
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      end
      machine.vm.hostname = "#{hostname}"
      machine.vm.box = "#{ctrl_image}"
      # machine.vm.network "public_network", bridge: "#{int}"
      machine.vm.network "public_network", bridge: "#{int}",
        ip: "#{ip}",
        netmask: "#{cidr}"
      machine.ssh.insert_key = false
      ## provisioners: 
      # fichiers & dossiers
      [
        ["#{ctrl_key_path}/#{ctrl_key_name}", "~/#{ctrl_key_name}"]
      ].each do |src,dst|
        machine.vm.provision "get_pkey", 
          type: "file",
          source: "#{src}", destination: "#{dst}"
      end
      # vagrant provision jenkins.lan
      # vagrant provision --provision-with install-kubespray jenkins.lan 
      machine.vm.provision "shell", inline: etcHosts
      machine.vm.provision "shell", inline: common
      machine.vm.provision "install-kubespray",
        type: "shell", 
        path: "install_k8s.sh", 
        privileged: false,
        args: ["#{ctrl_key_name}"]
    end
  end
end
