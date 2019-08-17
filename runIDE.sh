#! /bin/bash 

docker run --rm -d -v /tmp/.X11-unix/:/tmp/.X11-unix/ \
              -v /dev/shm:/dev/shm \
              -v `pwd`/IDE:/home/atom/.atom \
              -v `pwd`:/home/atom/src \
              -e DISPLAY \
              jamesnetherton/docker-atom-editor
