# FROM ghcr.io/astral-sh/uv:latest
FROM python:3.12-slim-trixie
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ADD   . /code
WORKDIR /code

# Disable development dependencies
ENV UV_NO_DEV=1
RUN uv sync --locked

COPY pyproject.toml .
RUN uv pip install -r pyproject.toml
COPY . .
RUN uv pip install -e .

CMD ["uv", "run", "app.py"]

