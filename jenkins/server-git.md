# installer un dépôt git côté server

## créer un utilisateur git

1. `sudo useradd -m -s /bin/bash -U git`
2. changer d'utilisateur: `sudo su - git`

## créer le dépôt NU

```bash
mkdir ~/app.git
cd ~/app.git
git init --initial-branch=main --bare
```

## créer le dossier SSH

```bash
mkdir ~/.ssh
chmod 700 ~/.ssh
```

## créer les clés côté client

* `ssh-keygen.exe -t ed25519 -f ~/.ssh/jenkins -N ""`

## placer la clé publique côté serveur

* `ssh-copy-id ...`
* OU 
   1. copier le contenu du fichier ~/.ssh/jenkins.pub (côté client)
   2. coller ce contenu dans le fichier ~/.ssh/authorized_keys (côté serveur)
   3. chmod 600 ~/.ssh/authorized_keys

## configurer l'utilisation de la clé privée côté client

1. créer ou éditer le fichier `~/.ssh/config`
2. ajouter

```text
Host jenkins.lan
 IdentityFile "C:/Users/<user>/.ssh/jenkins"
 UserKnownHostsFile /dev/null
 StrictHostKeyChecking no
```
3. tester la cnx ssh: `ssh -i ~/.ssh/jenkins git@jenkins.lan`

## configurer le dépôt distant dans le dépôt client

* `git remote add origin git@jenkins.lan:app.git`

## pousser les commits sur le dépôt distan en fonction de la branche

* `git push -u origin main`