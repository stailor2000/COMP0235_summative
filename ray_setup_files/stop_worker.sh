#!/bin/bash

# File containing worker node internal IP addresses
IP_FILE="worker_machines.txt"

# SSH key file
SSH_KEY="/home/ec2-user/.ssh/id_cluster"

# Loop through the worker nodes and execute the commands
while IFS= read -r worker_ip; do
    # Use SSH key-based authentication to remotely execute the commands on the worker node
    ssh -i "$SSH_KEY" "ec2-user@$worker_ip" << EOF
        docker stop \$(docker ps -q)  # Stop all running containers
        docker kill \$(docker ps -q)  # Force kill all containers
        docker rmi -f \$(docker images -q)  # Remove all images
        docker system prune -af  # Docker system prune
EOF
done < "$IP_FILE"

