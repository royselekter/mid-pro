#! /bin/bash

set -ex

export DEBIAN_FRONTEND=noninteractive

cd ~ubuntu

apt update -y

sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
sudo chown ubuntu /etc/ssh/ssh_config
sudo echo "UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config

sudo service ssh restart

echo "${key_base64}" | base64 -d > ~ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu ~ubuntu/.ssh/id_rsa
chmod 400 ~ubuntu/.ssh/id_rsa


sudo mkdir -p /var/lib/jenkins/.ssh/
sudo cp ~ubuntu/.ssh/id_rsa /var/lib/jenkins/.ssh/
chown jenkins /var/lib/jenkins/.ssh/id_rsa


git clone https://github.com/royselekter/jenki_repo.git

sudo chown -R ubuntu:ubuntu ~ubuntu

sleep 20

sudo java -jar ./jenkins-cli.jar -s http://localhost:8080/ -auth jenkins:R@y217153 create-job test_me_app < ./jenki_repo/Jenki_temp.xml

touch /tmp/userdata-init-done