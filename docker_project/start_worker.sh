#!/bin/bash

COORDINATOR_IP="13.43.158.180"

docker run -d ray-help \
  ray start --address="${COORDINATOR_IP}:6379" --block

# mount volumes here
