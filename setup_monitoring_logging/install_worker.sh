#!/bin/bash

# Define the location of the individual scripts
WORKER_NODES_IP_FILE="worker_machines.txt"

# SSH key file
SSH_KEY="/home/ec2-user/.ssh/id_cluster"

# install_node_exporter.sh to be copied and executed on worker nodes
FILE_TO_COPY_AND_EXECUTE="./install_node_exporter.sh"


# installing node exporter on worker nodes
while IFS= read -r worker_ip; do
    echo "Installing Node Exporter on worker node: $worker_ip"
    
    # copy install_node_exporter.sh to the worker node
    scp -i "$SSH_KEY" "$FILE_TO_COPY_AND_EXECUTE" "ec2-user@$worker_ip:$FILE_TO_COPY_AND_EXECUTE"

    # execute install_node_exporter.sh
    ssh -n -T -i "$SSH_KEY" "ec2-user@$worker_ip" "bash $FILE_TO_COPY_AND_EXECUTE"

done < "$WORKER_NODES_IP_FILE"

echo "Installation process completed."

