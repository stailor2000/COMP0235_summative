#!/bin/bash

# Set the S3 bucket and directory
BUCKET_NAME="comp0235-ucabst7"
S3_DIRECTORY="processing_results"
# Specify the local directory to store the files
LOCAL_DIRECTORY="~/summative_work/test_files"

# Create the local directory if it doesn't exist
mkdir -p "$LOCAL_DIRECTORY"

# Copy all CSV files from the specified S3 directory to the local directory
aws s3 cp "s3://$BUCKET_NAME/$S3_DIRECTORY" "$LOCAL_DIRECTORY" --recursive --exclude "*" --include "*.csv"

# Change to the local directory
cd "$LOCAL_DIRECTORY"

# Print the contents of the CSV files
for file in *.csv; do
    if [ -f "$file" ]; then
        echo "Contents of $file:"
        cat "$file"
        echo "--------------------------------"
    fi
done

