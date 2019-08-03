#! /bin/bash



service ssh restart

sleep 100

cd /home/ubuntu

git clone https://github.com/royselekter/k8s_repo.git

