from flask import Flask, request, jsonify
import prometheus_client
from litequeue import LiteQueue
from sqlitedict import SqliteDict
import sys

# prometheus scraping metrics
root_counter = prometheus_client.Counter('get_root', 'number of times get / was done')
completed_counter = prometheus_client.Counter('get_completed', 'number of tasks thats have been completed')
failed_counter = prometheus_client.Counter('get_failed_retried', 'number of tasks that have failed, but are being retried')
total_left_counter = prometheus_client.Counter('get_total_left', 'number of tasks that are yet to be processed')
running_counter = prometheus_client.Counter('get_running', 'number of tasks that are running at the moment')
completely_failed_counter = prometheus_client.Counter('get_failed_completely', 'number of tasks that have failed after max retries')


# create queues of pending and successful tasks
pending_task_queue = LiteQueue("pending_tasks.db")
succeeded_task_queue = LiteQueue("succeeded_tasks.db")
failed_max_retries_queue = LiteQueue("failed_tasks.db")

#initialise max retries
MAX_RETRIES = 4
retry_counter = SqliteDict("retry_counter.db")   # Initialize a dictionary to track retries

# create a LiteQueue and populate it txt file of inputs aka experiment_ids.txt
def populate_queue(file_path, task_queue):
    with open(file_path, 'r') as file:
        for line in file:
            pending_task_queue.put(line.strip())
            total_left_counter.inc()            # incremeent queue to get total number of tasks

# Create a Flask application
app = Flask(__name__)



@app.route("/next_task", methods=["GET"])
def next_task():
    try:
        # .pop() gets next task out of the queue
        next_message = pending_task_queue.pop()  
        next_task = next_message.data

        # decrease number of tasks left by 1
        total_left_counter.inc(-1)  

        # increase number of running tasks by 1
        running_counter.inc()  
    except Exception as e:
        next_task = None
    return jsonify({"task": next_task})



@app.route("/mark_done", methods=["POST"])
def mark_done():
    # get the completed task id
    succeeded_task_id = request.json["task"]

    # put the task in the completed queue
    succeeded_task_queue.put(succeeded_task_id)

    # increase completed counter
    completed_counter.inc()

    # decrease number of running tasks by 1
    running_counter.inc(-1)  

    return ""



@app.route("/mark_failed", methods=["POST"])
def mark_failed():
    # get the failed task id
    failed_task_id = request.json["task"]

    # bump the failed task counter
    failed_counter.inc()

    # update the retry count
    retry_counter[failed_task_id] = retry_counter.get(failed_task_id, 0) + 1
    retry_counter.commit()

    if retry_counter[failed_task_id] >= MAX_RETRIES:
        print(f"Task {failed_task_id} failed after maximum retries.")
        # put the task in the failed queue
        failed_max_retries_queue.put(failed_task_id)
    else:
        # put the task back in the queue
        pending_task_queue.put(failed_task_id)

    # decrease number of running tasks by 1
    running_counter.inc(-1)  

    return ''


if __name__ == "__main__":
    # error handling: forgettingo t add the input file
    if len(sys.argv) != 2:
        print("Forgot to add input file to cmd line")
        sys.exit(1)

    # get the file paths of the txt file form the cmd line
    input_file_path = sys.argv[1]

    # create and populate LiteQueue
    populate_queue(input_file_path, pending_task_queue)

    prometheus_client.start_http_server(8001)
    app.run(host="0.0.0.0", port=8000)

