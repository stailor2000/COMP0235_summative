#!/bin/bash


ucl_username_s3_bucket="$1"
host_ip_internal="$2"

cd ~/summative_work

# executes the ansible playbooks

# executes ssh key setup playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/ssh_key_setup.yml --private-key=~/.ssh/id_cluster

# executes cluster_setup playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/cluster_setup.yml --private-key=~/.ssh/id_cluster

# executes docker installation playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/docker_installation.yml --private-key=~/.ssh/id_cluster

# executes change_docker_directory.yml playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/change_docker_directory.yml --private-key=~/.ssh/id_cluster

# executes mounting disk on worker nodes playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/mount_client_disk.yml --private-key=~/.ssh/id_cluster

# executed downloaidng pdb70 to mounted disk on worker nodes playbook
ansible-playbook -i inventory.ini ./cluster_initialisation/download_pdb70.yml --private-key=~/.ssh/id_cluster



# downloaded human proteome file to s3 bucket
aws s3 cp ./coursework_docs/uniprotkb_proteome_UP000005640_2023_10_05.fasta s3://comp0235-${ucl_username_s3_bucket}/human_proteome



# start ray cluster
./ray_setup_files/start_cluster.sh $host_ip_internal
