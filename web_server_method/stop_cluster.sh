#!/bin/bash



# stop workers nodes
echo "Stopping worker nodes..."

# File containing worker node internal IP addresses
IP_FILE="/home/ec2-user/summative_work/setup_monitoring_logging/worker_machines.txt"

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




# stop coordinator node
echo "Stopping coordinator node..."

sudo yum install procps


# find the PID of coordinator.py and check if it was found
pid=$(pgrep -f coordinator.py)
if [ -z "$pid" ]; then
    echo "coordinator.py is not running."
else
    # attempt to kill the process
    kill $pid

    # wait for a bit and check if the process is still running
    sleep 5
    if ps -p $pid > /dev/null; then
       echo "Shutdown failed, forcing shutdown..."
       kill -9 $pid
    fi

    echo "coordinator.py has been stopped."
fi


