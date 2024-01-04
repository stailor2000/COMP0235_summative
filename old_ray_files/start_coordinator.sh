#!/bin/bash

COORDINATOR_IP="$1"

docker run -it -d -p 10000-10050:10000-10050 -p 9090:9090 -p 3000:3000 -p 8080:8080 -v /dev/shm:/dev/shm --name "parallel_cw_head" stailor2000/data_eng_courswork:latest \
/bin/bash -c "export RAY_TMPDIR=/dev/shm/ray_tmp && \
source /root/miniconda3/bin/activate myenv && \
ray start --block --disable-usage-stats --num-cpus=0 \
--node-manager-port 10000 \
--object-manager-port 10001 \
--dashboard-agent-grpc-port 10003 \
--dashboard-agent-listen-port 10004 \
--metrics-export-port 10005 \
--port 10006 \
--dashboard-port 8080 \
--ray-client-server-port 10008 \
--min-worker-port 10010 \
--max-worker-port 10040 \
--ray-client-server-port 10046 \
--head --dashboard-host 0.0.0.0 \
--node-ip-address '${COORDINATOR_IP}' \
--object-store-memory=1000000000 \
--include-dashboard=True"
