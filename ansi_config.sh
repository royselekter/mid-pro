#! /bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive

cd ~ubuntu

apt update -y
sudo apt install software-properties-common coreutils -y
apt-add-repository ppa:ansible/ansible -y
apt update -y
apt install ansible -y

sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
sudo chown ubuntu /etc/ssh/ssh_config
sudo echo "UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config

sudo service ssh restart

echo "${key_base64}" | base64 -d > ~ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu ~ubuntu/.ssh/id_rsa
chmod 400 ~ubuntu/.ssh/id_rsa

git clone https://github.com/royselekter/ansible_repo.git

sudo chmod 777 /home/ubuntu/ansible_repo/run_pb.sh

sudo chown -R ubuntu:ubuntu ~ubuntu

touch /tmp/userdata-init-done