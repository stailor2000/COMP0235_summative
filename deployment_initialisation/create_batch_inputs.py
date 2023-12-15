# directory to experiment_ids.txt
input_file = "/home/ec2-user/summative_work/coursework_docs/experiment_ids.txt"

# directory to where i plan to save the batch files before copying to them to the s3 bucket
output_directory = "local_batches"

# creat output directory given it doesnt exist
import os
os.makedirs(output_directory, exist_ok=True)

# read protein IDs from input file into a list
with open(input_file, "r") as f:
    protein_ids = [line.strip() for line in f]

# split protein IDs into batches of 8 (hopefully will prevent a load average above 2 on client nodes)
# save each batch as a seperate txt file
batch_size = 8
number_batches = int(6000 / batch_size)
for i in range(number_batches) :
    batch, protein_ids = protein_ids[:batch_size], protein_ids[batch_size:]
    batch_filename = f"batch_{i + 1}.txt"
    batch_content = "\n".join(batch)
    batch_path = os.path.join(output_directory, batch_filename)

    with open(batch_path, "w") as f:
        f.write(batch_content)

