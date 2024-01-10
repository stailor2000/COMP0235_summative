#!/bin/bash

# Check if at least 3 arguments are provided
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <ucl_username_s3_bucket> <host_ip_external> <inputs_file> [--reset]"
    exit 1
fi

ucl_username_s3_bucket="$1"
host_ip_external="$2"
inputs_file="$3"
RESET_FLAG="$4"  # Optional third argument for reset flag

cd ~/summative_work
pip install Flask prometheus_client litequeue sqlitedict


# create cluster ssh key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_cluster -N ""


# executes the ansible playbooks

# executes ssh key setup playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/ssh_key_setup.yml --private-key=~/lecturer_key

# executes cluster_setup playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/cluster_setup.yml --private-key=~/.ssh/id_cluster

# executes docker installation playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/docker_installation.yml --private-key=~/.ssh/id_cluster

# executes mounting disk on worker nodes playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/mount_client_disk.yml --private-key=~/.ssh/id_cluster

# executed downloaidng pdb70 to mounted disk on worker nodes playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/download_pdb70.yml --private-key=~/.ssh/id_cluster

# executes change_docker_directory.yml playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/change_docker_directory.yml --private-key=~/.ssh/id_cluster

#open port for flask web server and prometheus etc on the coordinator node
sudo firewall-cmd --zone=public --add-port=8000/tcp --permanent # open port for flask
sudo firewall-cmd --zone=public --add-port=9090/tcp --permanent # open port for prometheus
sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent # open port for grafana
sudo firewall-cmd --zone=public --add-port=9100/tcp --permanent # open port for node-exporter
sudo firewall-cmd --reload

# downloaded human proteome file to s3 bucket
aws s3 cp ./coursework_docs/uniprotkb_proteome_UP000005640_2023_10_05.fasta s3://comp0235-${ucl_username_s3_bucket}/human_proteome


# execute prometheus,grafana and node exporter on host and worker nodes
cd setup_monitoring_logging
./install_all.sh
cd ..


# start cluster

# create  the cluster command
CLUSTER_CMD="./start_cluster.sh $inputs_file $host_ip_external"

# check if reset flag is provided
if [ "$RESET_FLAG" == "--reset" ]; then
  CLUSTER_CMD+=" --reset"
fi

cd web_server_method
echo "Starting cluster with command: $CLUSTER_CMD"
$CLUSTER_CMD
cd ..
echo "Cluster has been started and deployed"
