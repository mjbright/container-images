# FROM ghcr.io/astral-sh/uv:latest
FROM python:3.12-slim-trixie
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ADD   . /app
WORKDIR /app

# Disable development dependencies
ENV UV_NO_DEV=1
RUN uv sync --locked

COPY pyproject.toml .
RUN uv pip install -r pyproject.toml
#COPY . .
RUN uv pip install -e .

WORKDIR /app
COPY static        /app/static
COPY templates     /app/templates
COPY tmp/httpd.py  /app/httpd.py

# Note: Not necessary to be able to access the Container but provides information useable by
#       the Container Engine/Orchestrator
EXPOSE 8080

# Note: The default command to run when a Container is created from this Container Image
CMD ["uv", "run", "/app/httpd.py"]

