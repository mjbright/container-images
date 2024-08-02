#!/usr/bin/env bash

# Initial version with sudo capability:
# VERSION=0.1
VERSION=0.2

docker build -t mjbright/ubuntu-sshd:$VERSION .

docker login

docker push mjbright/ubuntu-sshd:$VERSION

