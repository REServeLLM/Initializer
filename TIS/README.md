```bash
docker run -it -d --network=host --runtime=nvidia \
                  --cap-add=SYS_PTRACE --cap-add=SYS_ADMIN \
                  --security-opt seccomp=unconfined \
                  --shm-size=16g --privileged --ulimit memlock=-1 \
                  --gpus=all --name=reserve \
                  reserve-llm:latest
                  
docker exec -it reserve /bin/bash
```