#!/bin/bash

# Machine internal IPs
IP_FILE="worker_machines.txt"

# SSH key file
SSH_KEY="/home/ec2-user/.ssh/id_cluster"

# Loop through the worker nodes and copy/execute the file on each node
while IFS= read -r worker_ip; do

    # Use SSH key-based authentication to remotely execute the file on the worker node
    ssh -n -T -i "$SSH_KEY" "ec2-user@$worker_ip" "nproc && curl http://169.254.169.254/latest/meta-data/instance-type"

done < "$IP_FILE"

