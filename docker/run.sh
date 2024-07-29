#!/bin/bash

# Replace MODEL_PATH to your own model path
MODEL_PATH="/home/LAB/zhangyh2/workspace/models"
# under MODEL_PATH:
# models/checkpoints
# models/engines
# models/models/Meta-Llama-3-8B-Instruct

docker run -it -d --network=reserve-network -p 8888:22 -p 8080:8080 -p 8081:8081 -p 8082:8082 \
                  --runtime=nvidia --cap-add=SYS_PTRACE --cap-add=SYS_ADMIN  --hostname reserve-leader \
                  --security-opt seccomp=unconfined --shm-size=16g --privileged \
                  --ulimit memlock=-1 --gpus=all --volume ${MODEL_PATH}:/mnt/models --workdir /code \
                  --name=reserve-leader reserve-llm:latest

docker run -it -d --network=reserve-network \
                  --runtime=nvidia --cap-add=SYS_PTRACE --cap-add=SYS_ADMIN --hostname reserve-worker \
                  --security-opt seccomp=unconfined --shm-size=16g --privileged \
                  --ulimit memlock=-1 --gpus=all --volume ${MODEL_PATH}:/mnt/models --workdir /code \
                  --name=reserve-worker reserve-llm:latest