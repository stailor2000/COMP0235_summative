#!/bin/bash

docker run -d --name ray_test_example \
  -p 6379:6379 -p 6380:6380 -p 6381:6381 -p 8076:8076 -p 6066:6066 -p 8265:8265 -p 8786:8786 \
  ray_test_example \
  ray start --head --port=6379 --dashboard-host=0.0.0.0 --block \
  --num-cpus=0 # Block any jobs running on the coordinator
