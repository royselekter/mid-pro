#! /bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

cd ~ubuntu

git clone https://github.com/royselekter/consul_repo.git

sudo chown -R ubuntu:ubuntu ~ubuntu

sudo chmod 777 ./consul_repo/cosule_server.sh

./consul_repo/cosule_server.sh


# install prometheus

sudo useradd --no-create-home --shell /bin/false prometheus
sudo useradd --no-create-home --shell /bin/false node_exporter

sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

curl -LO https://github.com/prometheus/prometheus/releases/download/v2.0.0/prometheus-2.0.0.linux-amd64.tar.gz

tar xvf prometheus-2.0.0.linux-amd64.tar.gz

sudo cp prometheus-2.0.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.0.0.linux-amd64/promtool /usr/local/bin/

sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

sudo cp -r prometheus-2.0.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.0.0.linux-amd64/console_libraries /etc/prometheus

sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

rm -rf prometheus-2.0.0.linux-amd64.tar.gz prometheus-2.0.0.linux-amd64

cat << EOCCF >/etc/prometheus/prometheus.yml
global:
  scrape_interval: 2s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 2s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter'
    scrape_interval: 2s
    static_configs:
      - targets: ['192.168.10.51:9100','192.168.10.52:9100']
EOCCF

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

sudo -u prometheus /usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries &

sudo echo "installed prometheus" >> test

# check end


cat << EOCCS >/etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOCCS

sudo systemctl daemon-reload

sudo systemctl start prometheus

sudo systemctl enable prometheus


# install grafana

#sudo apt-get update && sudo apt-get -y upgrade

curl https://packages.grafana.com/gpg.key | sudo apt-key add -

sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

sudo apt-get update -y

sudo apt-get -y install grafana

sudo systemctl start grafana-server
sudo systemctl enable grafana-server

sudo systemctl enable grafana-server


