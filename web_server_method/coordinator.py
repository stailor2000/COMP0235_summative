from flask import Flask, request, jsonify
import prometheus_client
from litequeue import LiteQueue
from sqlitedict import SqliteDict
import argparse
import subprocess
from threading import Lock
import logging
import os



# prometheus scraping metrics
#root_counter = prometheus_client.Counter('get_root', 'number of times get / was done')
completed_counter = prometheus_client.Counter('get_completed', 'number of tasks thats have been completed')
failed_counter = prometheus_client.Counter('get_failed_retried', 'number of tasks that have failed, but are being retried')
total_left_counter = prometheus_client.Gauge('get_total_left', 'number of tasks that are yet to be processed')
running_counter = prometheus_client.Gauge('get_running', 'number of tasks that are running at the moment')
completely_failed_counter = prometheus_client.Counter('get_failed_completely', 'number of tasks that have failed after max retries')


#initialise max retries
MAX_RETRIES = 4

# initialise locks for each shared queue
pending_tasks_lock = Lock()
succeeded_tasks_lock = Lock()
failed_tasks_lock = Lock()
retry_counter_lock = Lock()


# add directory for log file
log_directory = '/dev/shm/logs'
log_file = 'worker_logs.log'
log_path = os.path.join(log_directory, log_file)

# create the directory if it does not exist
if not os.path.exists(log_directory):
    os.makedirs(log_directory)



# configure logging
# create a root logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)  # Set the global log level

# create handlers
file_handler = logging.FileHandler('/dev/shm/logs/worker_logs.log')

# set levels for handlers
file_handler.setLevel(logging.INFO)

# create formatters and add to handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)

# add handlers to the logger
logger.addHandler(file_handler)




# create a LiteQueue and populate it txt file of inputs aka experiment_ids.txt
def populate_queue(file_path, task_queue):
    logger.info("Pending Task Queue is being populated")
    with open(file_path, 'r') as file:
        for line in file:
            pending_task_queue.put(line.strip())
            total_left_counter.inc()            # incremeent queue to get total number of tasks
    logger.info("Pending Task Queue has been populated")

def delete_databases():
    for db_pattern in ["pending_tasks.db*", "succeeded_tasks.db*", "failed_tasks.db*", "retry_counter.db*"]:
        logger.info(f"{db_pattern} has been deleted from the system")
        command = f"rm -f {db_pattern}"
        subprocess.run(command, shell=True)
        print(f"Deleted files matching {db_pattern}")
    logger.info("All databases have been deleted from the system")


# Create a Flask application
app = Flask(__name__)



@app.route("/next_task", methods=["GET"])
def next_task():
    next_task = None  # initialise next_task at the beginning
    with pending_tasks_lock:
        try:
            # .pop() gets next task out of the queue
            next_message = pending_task_queue.pop()  
            next_task = next_message.data
            logger.info(f"{next_task} has been created from pending_task queue")            

            # decrease number of tasks left by 1
            total_left_counter.dec(1)

            # increase number of running tasks by 1
            running_counter.inc()

        except AttributeError as e:
            print(f"A NoneType error occurred: {e}")
            logger.error(f"NoneType Error during /next_task: {e}")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            logger.error(f"Unexpected Error during /next_task: {e}")
            #next_task = None
        return jsonify({"task": next_task})



@app.route("/mark_done", methods=["POST"])
def mark_done():
    with succeeded_tasks_lock:
        # get the completed task id
        succeeded_task_id = request.json["task"]
        logger.info(f"{succeeded_task_id} has sucessfully been completed")    

        # put the task in the completed queue
        succeeded_task_queue.put(succeeded_task_id)
        logger.info(f"{succeeded_task_id} has been added to succeeded_task_queue")
        # increase completed counter
        completed_counter.inc()

        # decrease number of running tasks by 1
        running_counter.dec(1)  

        return ""



@app.route("/mark_failed", methods=["POST"])
def mark_failed():
    with failed_tasks_lock, retry_counter_lock:
        # get the failed task id
        failed_task_id = request.json["task"]
        logger.warning(f"{failed_task_id} has failed completed")    
        # bump the failed task counter
        failed_counter.inc()

        # update the retry count
        retry_counter[failed_task_id] = retry_counter.get(failed_task_id, 0) + 1
        retry_counter.commit()

        if retry_counter[failed_task_id] >= MAX_RETRIES:
            logger.warning(f"{failed_task_id} has failed after maximum retries.")
            # put the task in the failed queue
            failed_max_retries_queue.put(failed_task_id)
            logger.info(f"{failed_task_id} has been added to failed_max_retries_queue")
            # decrease number of running tasks by 1
            running_counter.dec(1) 

            # increase number of completely failed tasks
            completely_failed_counter.inc()
        else:
            # put the task back in the queue
            pending_task_queue.put(failed_task_id)
            logger.info(f"{failed_task_id} has been readded to pending_task_queue")
        return ''


if __name__ == "__main__":
    # create the parser and add arguments
    parser = argparse.ArgumentParser(description='Coordinator for task queue management.')
    parser.add_argument('input_file', help='Path to the input file containing task identifiers.')
    parser.add_argument('--reset', action='store_true', help='Reset and delete all existing task databases.')
    args = parser.parse_args()

    # check for '--reset' flag
    if args.reset:
        delete_databases()

    # initialise the persistent queues/databases
    pending_task_queue = LiteQueue("pending_tasks.db")
    succeeded_task_queue = LiteQueue("succeeded_tasks.db")
    failed_max_retries_queue = LiteQueue("failed_tasks.db")
    retry_counter = SqliteDict("retry_counter.db")

    # populate tasks queue from the input file
    populate_queue(args.input_file, pending_task_queue)

    # start Prometheus and Flask
    prometheus_client.start_http_server(8001)
    app.run(host="0.0.0.0", port=8000)

