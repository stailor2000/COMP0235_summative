#!/bin/bash

COORDINATOR_IP="$1"


# Generate a unique container name based on the worker IP
CONTAINER_NAME="parallel_cw_worker"
echo "Starting container ${CONTAINER_NAME}..."
docker run -d -p 80:80 -p 8000:8000 -v /mnt/data/pdb70/:/dataset -v /mnt/data/logs/:/logs  --name "$CONTAINER_NAME" stailor2000/data_eng_courswork:latest $COORDINATOR_IP



