
#FROM python:3
FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y wget curl net-tools && apt-get clean

WORKDIR /app

# Note: ADD is like COPY but has more (unnecessary) functionality:
#ADD static   /app
#ADD httpd.py /app

# Note: Best to add httpd.py after static/ IFF Python code will change more frequently
#       Allows to take advantage of cached image layers
COPY static        /app/static
COPY templates     /app/templates
COPY tmp/httpd.py  /app/httpd.py

# Note: Not necessary to be able to access the Container but provides information useable by
#       the Container Engine/Orchestrator
EXPOSE 8080

# Note: The default command to run when a Container is created from this Container Image
# Note: Use exec format, so that signal handling works:
CMD ["/app/httpd.py"]

