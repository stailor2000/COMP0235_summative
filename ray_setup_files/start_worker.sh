#!/bin/bash

COORDINATOR_IP="$1"
WORKER_IP="$2"

docker run -it -p 10000-10050:10000-10050 stailor2000/data_eng_courswork:latest \
ray start --block --disable-usage-stats \
--node-manager-port 10000 \
--object-manager-port 10001 \
--dashboard-agent-grpc-port 10003 \
--dashboard-agent-listen-port 10004 \
--metrics-export-port 10005 \
--min-worker-port 10010 \
--max-worker-port 10040 \
--ray-client-server-port 10046 \
--address="${COORDINATOR_IP}:10006" \
--node-ip-address "${WORKER_IP}"
