# COMP0235 Coursework - Sita Tailor


## Introduction

This guide is designed to provide instructions on deploying a distributed pipeline that uses a web server to parallelize task processing for predicting protein structures. Each section contains a detailed explanation of the steps involved, followed by specific command-line instructions. These instructions are essential for setting up and executing a distributed data analysis system aimed at protein structure prediction. The pipeline is initially configured for 6 AWS nodes, comprising 1 host node and 5 client nodes. However, it can be scaled to accommodate more nodes if needed.

### 1. SSH Key Generation
- On your local machine, create a new key pair called `student_aws_key` to gain access to your host node, and then copy it over using the already known lecturer_key.

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/student_aws_key -N ""
scp -i /path/to/lecturer_key ~/.ssh/student_aws_key.pub ec2-user@host_ip:~/
ssh -i /path/to/lecturer_key ec2-user@host_ip
cat student_aws_key.pub >> ~/.ssh/authorized_keys
```

- To access your AWS host node, you can SSH using the `student_aws_key`. Once connected to the host node and within the home directory, proceed to clone the GitHub repository.

```bash
ssh -i ~/.ssh/student_aws_key ec2-user@host_ip
```


- Once cloned, download Ansible.
```bash
python3 -m pip install --user ansible
```


- Modify the `inventory.ini` file located at `~/summative_work/inventory.ini` to include your AWS external IP addresses for your Ansible playbooks:

```plain text

[host]
# Replace 'your_host_ip' with the IP address of your host machine
your_host_ip ansible_connection=local

[clients]
# Add your client IP addresses below:
# client1_ip
# client2_ip
# client3_ip
# ...
```

- Modify the `worker_machines.txt` file located at `~/summative_work/setup_monitoring_logging/worker_machines.txt` to include your AWS internal IP addresses for your cluster:

```plain text
# client1_ip
# client2_ip
# client3_ip
# ...
```

- Create a new ssh key called `id_cluster`, to avoid using the lecturer key.

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_cluster -N ""
```

### 2. Deployment Instructions

#### 2.1. Starting the Deployment Process

- Open a terminal and change your current directory to `~/summative_work`:
```bash
cd ~/summative_work
```
- Initiate the deployment process by executing `deploy.sh`. Replace `<ucl_username_s3_bucket>` with your UCL username formatted like `ucabst7` and `<host_ip_internal>` with the internal IP address of your host node, `<inputs_file>` with your txt file with your protein IDs and use `--reset` if you want to reset the persistent queues:
```bash
./deploy.sh <ucl_username_s3_bucket> <host_ip_internal> <inputs_file> [--reset]
```

#### 2.2. Understanding the `deploy.sh` Script
- This script triggers a series of Ansible playbooks located in `~/summative_work/cluster_initialisation`:

    - `ssh_key_setup.yml`: Distributes the newly created SSH key across client nodes.
    - `cluster_setup.yml`: Updates nodes with the latest software packages and security patches, and installs essential tools.
    - `docker_installation.yml`: Installs Docker on all nodes.
    - mount_client_disk.yml: Attaches additional disk space to each client node.
    - `download_pdb70.yml`: Downloads the PDB70 dataset from the internet to the mounted disk space on all client nodes.
    - `change_docker_directory.yml`: Redirects the Docker directory to `/mnt/data/docker` on client nodes to utilize the extra space.
- The script also downloads the `uniprotkb_proteome_UP000005640_2023_10_05.fasta` file into the specified s3 bucket.
- It opens ports on the host node required for Flask, Prometheus, Grafana and Node Exporter.
- It executes `./setup_monitoring_logging/./install_all.sh` which installs Prometheus, Grafana and node exporter on the host node, and node exporter on all the client nodes.

#### 2.3. Deploying the Data Analysis Pipeline

- `deploy.sh` finally executes `./web_server_method/start_cluster.sh`, which initializes the `./web_server_method/coordinator.py` python script to start the host node, and then deploys the docker container on the client nodes to connect them to the cluster.
- Once `deploy.sh` is complete the cluster is running and has started completing tasks.
- Access the monitoring tools via your local machine's web browser:
    - **Prometheus**: `Navigate to http://<host_node_external_ip>:9090`
    - **Grafana**: `Visit http://<host_node_external_ip>:3000`




### 3. Results Collations
- To collate the results once the pipeline has completed processing all protein IDs, execute the code below where `<ucl_username_s3_bucket>` is your UCL username formatted like `ucabst7`.

```bash
cd ~/summative_work/final_files
./collated_results.sh <ucl_username_s3_bucket>
```

- To transfer the results files from this pipeline: `profile_output.csv` and `hits_output.csv`, on your local machine run the code below. Replace `host_ip` with the aws instances external IP address and `/path/to/directory/local/machine` to the location on your local machine where you want the files saved.

```bash
scp -i ~/.ssh/student_aws_key -r ec2-user@host_ip:/home/ec2-user/summative_work/final_files/transfer_local /path/to/directory/local/machine
```
