#!/bin/bash

aws s3 cp s3://your-bucket/your-script . --recursive

chmod +x run.sh

./run.sh
