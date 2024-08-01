
FROM ubuntu:22.04

RUN apt-get update && apt-get upgrade -y && apt-get install -y python3-pip && apt-get clean

RUN python3 -m pip install kubernetes

RUN mkdir -p /app

WORKDIR /app

ADD ./list_pods.py /app

