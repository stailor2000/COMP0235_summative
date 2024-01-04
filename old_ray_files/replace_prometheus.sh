#!/bin/bash

# File to modify
FILE="/dev/shm/ray_tmp/ray/session_latest/metrics/prometheus/prometheus.yml"

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

# Perform the replacement
sed -i 's|/tmp/ray/prom_metrics_service_discovery.json|/dev/shm/ray_tmp/ray/prom_metrics_service_discovery.json|g' "$FILE"

echo "Replacement done."
