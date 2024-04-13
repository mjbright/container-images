#!/usr/bin/env bash

# Usage:
#   To watch status:
#     watch_httpd_status.sh 
#   To make normal requests:
#     watch_httpd_status.sh /
#   To make requests for single line:
#     watch_httpd_status.sh /1

if [ -z "$1" ]; then
    # Status
    watch -n 1 'curl -s $( kubectl get pods -o wide -l app=web | grep 10 | awk "{ print \$6; }" ):8080/status'
else
    watch -n 1 'curl -s $( kubectl get pods -o wide -l app=web | grep 10 | awk "{ print \$6; }" ):8080/'$1
fi

