#! /bin/bash


apt-add-repository ppa:ansible/ansible -y
apt-get update -y
apt-get install ansible -y

service ssh restart

cd /home/ubuntu & sleep 45

git clone https://github.com/royselekter/ansible_repo.git

sleep 10

cd ansible_repo


ansible-playbook -i inventory.yml install-docker.yml --key-file "~/.ssh/id_rsa"
ansible-playbook -i inventory.yml k8s-common.yml --key-file "~/.ssh/id_rsa"
ansible-playbook -i inventory.yml k8s-master.yml --key-file "~/.ssh/id_rsa"
ansible-playbook -i inventory.yml k8s-minion.yml --key-file "~/.ssh/id_rsa"
