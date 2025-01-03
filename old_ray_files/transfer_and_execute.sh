#!/bin/bash

# Host IP
host_ip="$1"

# Machine internal IPs
IP_FILE="worker_machines.txt"

# File to be copied and executed on worker nodes
FILE_TO_COPY_AND_EXECUTE="./start_worker.sh"

# SSH key file
SSH_KEY="/home/ec2-user/.ssh/id_cluster"

# Check if the host IP is provided as an argument
if [ -z "$host_ip" ]; then
  echo "Usage: $0 <host_ip>"
  exit 1
fi

# Loop through the worker nodes and copy/execute the file on each node
while IFS= read -r worker_ip; do
    # Use SCP to securely copy the file to the worker node
    scp -i "$SSH_KEY" "$FILE_TO_COPY_AND_EXECUTE" "ec2-user@$worker_ip:$FILE_TO_COPY_AND_EXECUTE"

    # Use SSH key-based authentication to remotely execute the file on the worker node
    ssh -n -T -i "$SSH_KEY" "ec2-user@$worker_ip" "bash $FILE_TO_COPY_AND_EXECUTE $host_ip $worker_ip &"

    # Check the exit status of the SSH command and handle errors if needed
    if [ $? -ne 0 ]; then
      echo "Error: SSH command failed for $worker_ip"
      # You can choose to exit or continue with other nodes
    fi
done < "$IP_FILE"

