#!/bin/bash

docker run -d -p 4321:4321 mjbright/docker-demo:20
docker run -d -p 4322:4321 mjbright/docker-demo:21

curl 127.0.0.1:4321
#read

curl 127.0.0.1:4322
#read




