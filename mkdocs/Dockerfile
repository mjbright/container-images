
FROM python:3

WORKDIR /app

RUN python3 -m pip install mkdocs mkdocs-material

ADD web-mkdocs /app/web-mkdocs

EXPOSE 8080

# Note: The default command to run when a Container is created from this Container Image
#CMD python3 -m http.server --bind 0.0.0.0 8080
CMD /app/web-mkdocs/build-web-mkdocs.sh

