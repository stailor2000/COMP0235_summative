#!/bin/bash

COORDINATOR_IP="13.43.158.180"

docker run -d ray_test_example \
  ray start --address="${COORDINATOR_IP}:6379" --block

# mount volumes here
