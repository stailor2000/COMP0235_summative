import sys
import multiprocessing
import requests
import json
import subprocess
import tempfile
import os


# add host_ node's external ip address
host_ip = sys.argv[1]
COORDINATOR_URL = f"http://{host_ip}:8000"


def data_analysis(protein_id, timeout_seconds=1800):
    print(f"Processing protein ID: {protein_id}")
    # create a temporary file
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_file:
        temp_file_path = temp_file.name

        # get the FASTA entry from S3 and write to the temporary file
        command = f"aws s3 cp s3://comp0235-ucabst7/human_proteome - | " \
                  f"awk -v RS='>' -v id='{protein_id}' '$1 == id {{print \">\" $0}}' > {temp_file_path}"
        subprocess.run(command, shell=True)

    # run pipeline_script.py with the path to the temporary file
    subprocess.run(['python', 'pipeline_script.py', temp_file_path], timeout=timeout_seconds)
    subprocess.run(['cat', 'hhr_parse.out'])

    # make protein_id safer to use as a variable name
    safe_protein_id = protein_id.replace('|', '_')  # Replace '|' with '_'

    # redirect contents of hhr_parse.out to a CSV file
    redirect_command = f"cat hhr_parse.out > {safe_protein_id}_result.csv"
    subprocess.run(redirect_command, shell=True)

    # upload the CSV file to S3
    upload_command = f"aws s3 cp {safe_protein_id}_result.csv s3://comp0235-ucabst7/processing_results/"
    subprocess.run(upload_command, shell=True)

    os.remove(f"{safe_protein_id}_result.csv")      # delete temp csv file
    os.remove(temp_file_path)  # delete the temporary file




def process_single_element(worker_index: int) -> bool:
    response = requests.get(COORDINATOR_URL + '/next_task')
    task_data = response.json()
    if 'task' in task_data:
        protein_id = task_data['task']
        if protein_id is None:
            return False
    else:
        print("No task data received")

    # Set the 'Content-Type' header to 'application/json'
    headers = {'Content-Type': 'application/json'}

    try:
        data_analysis(protein_id)
        requests.post(COORDINATOR_URL + '/mark_done', data=task_data, headers=headers)
    except Exception:
        requests.post(COORDINATOR_URL + '/mark_failed', data=task_data, headers=headers)

    return True





def worker_fn(worker_index: int):
    while True:
        condition = process_single_element(worker_index)
        if not condition:
            break


if __name__ == "__main__":
    # Create a pool of worker processes (number of processes can be specified)
    # num_processes = multiprocessing.cpu_count()  # Use the number of CPU cores available
    num_processes = min(multiprocessing.cpu_count(), 3)
    pool = multiprocessing.Pool(processes=num_processes)

    # Use the pool to execute the worker function with each input value
    pool.map(worker_fn, range(num_processes))

    # Close the pool and wait for all processes to finish
    pool.close()
    pool.join()
