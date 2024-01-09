#!/bin/bash

# get ucl s3 bucket name
ucl_username_s3_bucket="$1"

# local directory
local_directory="/home/ec2-user/summative_work/final_files/result_files"

# create local directory
mkdir -p $local_directory

# copy files from S3 to local directory
aws s3 cp s3://comp0235-${ucl_username_s3_bucket}/processing_results/ $local_directory --recursive
clear

# collate all csv files
unfiltered_output_file="/home/ec2-user/summative_work/final_files/unfiltered_collated_results.csv"
first_file=true

for file in $local_directory/*.csv; do
    if $first_file; then
        cat "$file" > "$unfiltered_output_file"
        first_file=false
    else
        tail -n +2 "$file" >> "$unfiltered_output_file"
    fi
done

# remove directory with all 6000 files copies
rm -rf $local_directory

# create folder for csvs that need to be transferred to local machine
mkdir -p /home/ec2-user/summative_work/final_files/transfer_local

# create hits_output.csv and profile_output.csv
python create_researcher_files.py
mv profile_output.csv transfer_local/profile_output.csv
mv hits_output.csv transfer_local/hits_output.csv
