#!/bin/bash
        
# coordinator internal ip address
COORDINATOR_IP="$1"
        
# path to the start_coordinator script
path_to_start_coordinator="./start_coordinator.sh"

# path to the start_workers script
path_to_start_workers="./transfer_and_execute.sh"

# path to the setup_monitoring script
path_to_setup_monitoring="./setup_monitoring.sh"

# start coordinator
echo "Starting coordinator node..."
"$path_to_start_coordinator" "$COORDINATOR_IP"

# attach workers
echo "Attaching worker nodes..."
"$path_to_start_workers" "$COORDINATOR_IP"

# copy the monitoring setup script into the Docker container
echo "Setting up monitoring tools in the coordinator Docker container..."
docker cp "$path_to_setup_monitoring" parallel_cw_head:/usr/src/app/setup_monitoring.sh
docker cp "./replace_grafana.sh" parallel_cw_head:/usr/src/app/replace_grafana.sh
docker cp "./replace_prometheus.sh" parallel_cw_head:/usr/src/app/replace_prometheus.sh

# entering docker container on host
echo "Entering docker container..."
docker exec -it parallel_cw_head bash
