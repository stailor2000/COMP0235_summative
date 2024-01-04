#!/bin/bash

COORDINATOR_IP="$1"

# Generate a unique container name based on the worker IP
CONTAINER_NAME="parallel_cw_worker"

while true; do
    # Check if the container is already running
    if ! docker ps -q -f name=${CONTAINER_NAME}; then
        echo "Starting container ${CONTAINER_NAME}..."

        docker run --rm -d -p 80:80 -p 9100:9100 -p 8000:8000 -v /mnt/data/pdb70/:/dataset --name "$CONTAINER_NAME" stailor2000/data_eng_courswork:latest $COORDINATOR_IP
    
    else
        echo "Container ${CONTAINER_NAME} is alive."
    fi

    sleep 60
done
