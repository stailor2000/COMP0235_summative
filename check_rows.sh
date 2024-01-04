#!/bin/bash

# Specify the S3 bucket and directory
BUCKET_NAME="comp0235-ucabst7"
DIRECTORY="processing_results/"

# Counter for files with a row count not equal to 2
count=0

# List and iterate over CSV files in the specified directory
aws s3 ls s3://$BUCKET_NAME/$DIRECTORY --recursive | grep '\.csv$' | while read -r line; do
    # Extract file name
    FILE_NAME=$(echo $line | awk '{print $4}')

    # Stream the file content and count the number of rows
    num_rows=$(aws s3 cp s3://$BUCKET_NAME/$FILE_NAME - | wc -l)

    # Check if row count is not equal to 2
    if [ $num_rows -ne 2 ]; then
        count=$((count+1))
        echo "File $FILE_NAME does not have 2 rows."
    fi
done

echo "Total files with row count not equal to 2: $count"

