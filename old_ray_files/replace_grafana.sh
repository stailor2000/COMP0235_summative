
#!/bin/bash

# Path to the grafana.ini file
FILE="/dev/shm/ray_tmp/ray/session_latest/metrics/grafana/grafana.ini"

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

# Perform the replacement
sed -i 's|/tmp/ray/session_latest/metrics/grafana/provisioning|/dev/shm/ray_tmp/ray/session_latest/metrics/grafana/provisioning|g' "$FILE"

echo "Replacement done."
