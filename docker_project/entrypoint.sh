#!/bin/bash

# Activate the Conda environment
source activate myenv

# Execute the Python script with provided arguments
python -u pipeline_script.py "$@"
