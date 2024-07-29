#!/bin/bash

docker exec -it reserve /bin/bash
docker exec -it reserve-leader /bin/bash
docker exec -it reserve-worker /bin/bash

/code/REServe/Initializer/main.sh run --tp 2