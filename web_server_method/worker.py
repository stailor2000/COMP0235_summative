import sys
import multiprocessing
import requests
import json
import subprocess
import tempfile
import os
import prometheus_client
import logging

# add host_ node's external ip address
host_ip = sys.argv[1]
COORDINATOR_URL = f"http://{host_ip}:8000"

# prometheus metrics
active_processes_gauge = prometheus_client.Gauge('active_processes', 'Number of active processes')


# add directory for log files
log_directory = '/logs'
log_file = 'worker_logs.log'
log_path = os.path.join(log_directory, log_file)

# Check if the log directory exists, create it if not
if not os.path.exists(log_directory):
    os.makedirs(log_directory)



# configure logging
# create a root logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)  # Set the global log level

# create handlers
file_handler = logging.FileHandler('/logs/worker_logs.log')

# set levels for handlers
file_handler.setLevel(logging.INFO)

# create formatters and add to handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)

# add handlers to the logger
logger.addHandler(file_handler)



def data_analysis(protein_id, worker_index, timeout_seconds=1800):
    logger.info(f"Worker {worker_index} -> Processing protein ID: {protein_id}")
    # create a temporary file
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_file:
        temp_file_path = temp_file.name

        # get the FASTA entry from S3 and write to the temporary file
        command = f"aws s3 cp s3://comp0235-ucabst7/human_proteome - | " \
                  f"awk -v RS='>' -v id='{protein_id}' '$1 == id {{print \">\" $0}}' > {temp_file_path}"
        subprocess.run(command, shell=True)

    # run pipeline_script.py with the path to the temporary file
    subprocess.run(['python', 'pipeline_script.py', temp_file_path], timeout=timeout_seconds)
    logger.info(f"Worker {worker_index} -> Completeted pipeline_script.py for {protein_id}")
    subprocess.run(['cat', 'hhr_parse.out'])

    # make protein_id safer to use as a variable name
    safe_protein_id = protein_id.replace('|', '_')  # Replace '|' with '_'

    # redirect contents of hhr_parse.out to a CSV file
    redirect_command = f"cat hhr_parse.out > {safe_protein_id}_result.csv"
    subprocess.run(redirect_command, shell=True)

    # upload the CSV file to S3
    upload_command = f"aws s3 cp {safe_protein_id}_result.csv s3://comp0235-ucabst7/processing_results/"
    subprocess.run(upload_command, shell=True)
    logger.info(f"Worker {worker_index} -> Uploaded {protein_id} to s3://comp0235-ucabst7/processing_results/")

    os.remove(f"{safe_protein_id}_result.csv")      # delete temp csv file
    os.remove(temp_file_path)  # delete the temporary file




def process_single_element(worker_index: int) -> bool:
    response = requests.get(COORDINATOR_URL + '/next_task')
    task_data = response.json()
    if 'task' in task_data:
        protein_id = task_data['task']
        if protein_id is None:
            logger.info(f"Worker {worker_index} got a None value from /next_task")
            return False
    else:
        logger.info(f"Worker {worker_index} didn't recieve a task")
        print("No task data received")

    # Set the 'Content-Type' header to 'application/json'
    headers = {'Content-Type': 'application/json'}

    try:
        data_analysis(protein_id, worker_index)
        response = requests.post(COORDINATOR_URL + '/mark_done', json=task_data, headers=headers)
        logger.info(f"Worker {worker_index} -> Response from /mark_done: {response.status_code}, {response.text}")
    except Exception as e:
        response = requests.post(COORDINATOR_URL + '/mark_failed', json=task_data, headers=headers)
        logger.error(f"Worker {worker_index} -> Error during data analysis or POST request: {e}")
        logger.info(f"Worker {worker_index} -> Response from /mark_failed: {response.status_code}, {response.text}")

    return True





def worker_fn(worker_index: int):
    logger.info(f"Worker {worker_index} is starting")
    active_processes_gauge.inc()  # Increment the gauge
    try:
        while True:
            logger.info(f"Worker {worker_index} is reiterating")
            condition = process_single_element(worker_index)
            if not condition:
                logger.critical(f"Worker {worker_index} is killing itself as it recieved no work (a None object)")
                break
    finally:
        active_processes_gauge.dec()  # Decrement the gauge when the worker stops




if __name__ == "__main__":

    # start Prometheus and Flask
    prometheus_client.start_http_server(8001)

    logger.info("Starting worker pool")
    num_processes = multiprocessing.cpu_count() - 1
    pool = multiprocessing.Pool(processes=num_processes)
    logger.info(f"Pool created. {num_processes} were initialised. In the pool: {pool}")
    # Use the pool to execute the worker function with each input value
    pool.map(worker_fn, range(num_processes))

    # Close the pool and wait for all processes to finish
    pool.close()
    pool.join()

