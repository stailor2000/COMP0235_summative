import ray
import subprocess
import sys
import tempfile
import os

# connect to ray cluster
ray.init(address='auto')

@ray.remote(num_cpus=1.33 , max_retries=3)
def data_analysis(protein_id):
    print(f"Processing protein ID: {protein_id}")

    # create a temporary file
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_file:
        temp_file_path = temp_file.name

        # get the FASTA entry from S3 and write to the temporary file
        command = f"aws s3 cp s3://comp0235-ucabst7/human_proteome - | " \
                  f"awk -v RS='>' -v id='{protein_id}' '$1 == id {{print \">\" $0}}' > {temp_file_path}"
        subprocess.run(command, shell=True)

    # run pipeline_script.py with the path to the temporary file
    subprocess.run(['python', 'pipeline_script.py', temp_file_path])
    subprocess.run(['cat', 'hhr_parse.out'])

    # make protein_id safer to use as a variable name
    safe_protein_id = protein_id.replace('|', '_')  # Replace '|' with '_'

    # redirect contents of hhr_parse.out to a CSV file
    redirect_command = f"cat hhr_parse.out > {safe_protein_id}_result.csv"
    subprocess.run(redirect_command, shell=True)

    # upload the CSV file to S3
    upload_command = f"aws s3 cp {safe_protein_id}_result.csv s3://comp0235-ucabst7/processing_results/"
    subprocess.run(upload_command, shell=True)

    os.remove(temp_file_path)  # delete the temporary file



if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python script.py <experiment_ids_file>")
        sys.exit(1)

    file_path = sys.argv[1]   # path to text file with inputs
    input_list = []  # initialize an empty list for inputs

    # read each line from file and add it to the list
    with open(file_path, 'r') as file:
        input_list.extend(line.strip() for line in file)

    # submit tasks to ray and collect the results
    futures = [data_analysis.remote(protein_id) for protein_id in input_list]

    # loop until all futures are processed
    while len(futures) > 0:
        # wait for any one of the tasks to complete
        done, futures = ray.wait(futures, num_returns=1)
