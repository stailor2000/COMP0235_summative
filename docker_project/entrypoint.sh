#!/bin/bash

# activate conda environment
source activate myenv

# function - process a single protein ID
process_protein_id() {
    local protein_id="$1"

    # get fasta entry for protein ID from S3 bucket
    fasta_entry=$(aws s3 cp s3://comp0235-ucabst7/human_proteome - | awk -v RS=">" -v id="$protein_id" '$1 == id {print ">" $0}')

    # run pipeline_script.py with fasta file entry for the protein ID
    echo "$fasta_entry" > temp.fasta
    python -u pipeline_script.py temp.fasta

    # convert hhr_parse.out to CSV with selected columns (query_id, best_hit,score_std,score_gmean)  using awk
    awk 'BEGIN {FS=","; OFS=","} {print $1, $2, $6, $7}' hhr_parse.out > "${protein_id}_result.csv"

    # upload CSV file to S3 with a unique name
    aws s3 cp "${protein_id}_result.csv" s3://comp0235-ucabst7/processing_results/
}

# read the batch file containing protein IDs
batch_file="$1"

# process each protein ID in the batch file
while IFS= read -r protein_id; do
    process_protein_id "$protein_id" &
done < "$batch_file"

# wait for all background jobs to finish
wait

