
#FROM python:3
FROM python:3.11-slim-bookworm

WORKDIR /app

COPY httpd.py /app/httpd.py
COPY content  /app/content

# Note: Not necessary to be able to access the Container but provides information useable by
#       the Container Engine/Orchestrator
EXPOSE 8080

# Note: The default command to run when a Container is created from this Container Image
CMD /app/httpd.py

