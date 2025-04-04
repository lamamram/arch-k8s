#!/bin/bash

sudo mv /etc/containerd/config.toml /etc/containerd/config-old.toml 
sudo cp /home/vagrant/k8s/config.toml /etc/containerd/
sudo systemctl restart containerd