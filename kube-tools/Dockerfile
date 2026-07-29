
#FROM ubuntu:22.04
#FROM ubuntu:26.04
FROM ghcr.io/astral-sh/uv:debian-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates wget git

RUN uv venv /opt/venv
# Use the virtual environment automatically
ENV VIRTUAL_ENV=/opt/venv
# Place entry points in the environment at the front of the path
ENV PATH="/opt/venv/bin:$PATH"

RUN uv pip install kubernetes

RUN mkdir -p /app

WORKDIR /app

RUN echo 'set -o vi' >> /root/.bashrc

RUN curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod a+x kubectl && mv kubectl /usr/local/bin &&
    echo 'source <(kubectl completion bash)' >> /root/.bashrc

RUN wget -q https://github.com/janosmiko/lfk/releases/download/v0.15.14/lfk_0.15.14_linux_amd64.tar.gz && \
  tar xf lfk_0.15.14_linux_amd64.tar.gz  lfk && chmod a+x lfk && mv lfk /usr/local/bin && \
  rm lfk_0.15.14_linux_amd64.tar.gz

RUN wget https://github.com/derailed/k9s/releases/download/v0.51.0/k9s_Linux_amd64.tar.gz && \
  tar xf k9s_Linux_amd64.tar.gz  k9s && chmod +x k9s && mv k9s /usr/local/bin && \
  rm k9s_Linux_amd64.tar.gz

RUN wget https://github.com/kdash-rs/kdash/releases/download/v2.1.1/kdash-linux.tar.gz && \
  tar xf kdash-linux.tar.gz  kdash && chmod +x kdash && mv kdash /usr/local/bin && \
  rm kdash-linux.tar.gz

ADD ./container-scripts/list_pods.py /app

ADD ./install_krew.sh /app
RUN /app/install_krew.sh

CMD ['/app/list_pods.py']
#CMD ['/opt/venv/bin/python3', './list_pods.py']

