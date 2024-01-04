#!/bin/bash

COORDINATOR_IP="$1"
WORKER_IP="$2"

# Generate a unique container name based on the worker IP
CONTAINER_NAME="parallel_cw_worker"

while true; do
    # Check if the container is already running
    if ! docker ps -q -f name=^/${CONTAINER_NAME}$; then
        echo "Starting container ${CONTAINER_NAME}..." 
 
        docker run --rm -d -p 10000-10050:10000-10050 -v /mnt/data:/mnt/data -v /mnt/data/pdb70/:/dataset --name "$CONTAINER_NAME" stailor2000/data_eng_courswork:latest \
        /bin/bash -c "export RAY_TMPDIR=/mnt/data/ray_tmp && \
        source /root/miniconda3/bin/activate myenv && \
        ray start --block --disable-usage-stats \
        --node-manager-port 10000 \
        --object-manager-port 10001 \
        --dashboard-agent-grpc-port 10003 \
        --dashboard-agent-listen-port 10004 \
        --metrics-export-port 10005 \
        --min-worker-port 10010 \
        --max-worker-port 10040 \
        --ray-client-server-port 10046 \
        --address='${COORDINATOR_IP}:10006' \
        --node-ip-address '${WORKER_IP}' \
        --object-store-memory=1000000000"
    else
        echo "Container ${CONTAINER_NAME} is alive."
    fi

    sleep 60
done
