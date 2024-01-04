#!/bin/bash

# Path to the stop_workers script
path_to_stop_workers="./stop_worker.sh"

# Path to the stop_coordinator script
path_to_stop_coordinator="./stop_coordinator.sh"


# stop workers and then stop coordinator
echo "Stopping worker nodes..."
"$path_to_stop_workers"

echo "Stopping coordinator node..."
"$path_to_stop_coordinator"
