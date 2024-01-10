#!/bin/bash

# file containing list of worker nodes
WORKER_FILE="./setup_monitoring_logging/worker_machines.txt"

# URL of pdb70 file to download
FILE_URL="https://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/pdb70_from_mmcif_latest.tar.gz"
DESTINATION="/mnt/data/pdb70_from_mmcif_latest.tar.gz"

# loop through each line in the worker file to download pdb70 in background
while IFS= read -r worker
do
    echo "Starting download and setup on $worker"
    ssh -i ~/.ssh/id_cluster ec2-user@"$worker" "
        sudo curl -o $DESTINATION '$FILE_URL' && \
        sudo mkdir -p /mnt/data/pdb70 && \
        sudo tar -xzvf $DESTINATION -C /mnt/data/pdb70
    " &
done < "$WORKER_FILE"

# wait for all background processes to finish
wait
echo "Downloads and setups completed on all worker nodes."
