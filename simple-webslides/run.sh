#!/bin/bash

PORT=8080

if [ "$1" = "-l" ]; then
    python3 -m http.server $PORT
else
    python3 -m http.server --bind 0.0.0.0 $PORT
fi
