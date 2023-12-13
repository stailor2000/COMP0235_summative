#!/bin/bash

# Activate the Conda environment
source activate myenv

# Assign protein ID provided as arguement
protein_id="$1"

# Fetch the fasta entry for prtein ID from S3
fasta_entry=$(aws s3 cp s3://comp0235-ucabst7/human_proteome - | awk -v RS=">" -v id="$protein_id" '$1 == id {print ">" $0}')

# run pipeline_script.py with obtanied fasta file entry from the protein ID
echo "$fasta_entry" > temp.fasta
python -u pipeline_script.py temp.fasta

# Convert hhr_parse.out to CSV with selected columns using awk
awk 'BEGIN {FS=","; OFS=","} {print $1, $2, $6, $7}' hhr_parse.out > "${protein_id}_result.csv"

# Upload the CSV file to S3 with a unique name
aws s3 cp "${protein_id}_result.csv" s3://comp0235-ucabst7/processing_results/
