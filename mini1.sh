#! /bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

cd ~ubuntu

git clone https://github.com/royselekter/consul_repo.git

sudo chown -R ubuntu:ubuntu ~ubuntu

sudo chmod 777 ./consul_repo/consul_client.sh
sudo chmod 777 ./consul_repo/consul_client_http.sh

./consul_repo/consul_client.sh

./consul_repo/consul_client_http.sh

#install node_exporter

curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.15.1/node_exporter-0.15.1.linux-amd64.tar.gz

tar xvf node_exporter-0.15.1.linux-amd64.tar.gz

cd node_exporter-0.15.1.linux-amd64/

nohup ./node_exporter &


