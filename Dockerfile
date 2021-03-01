FROM debian:latest
LABEL maintainer="Kevin Dungs <kevin@dun.gs>"

ENV CI=true
ENV CLAFOUTIS_VERSION="1.0.2"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
         ca-certificates \
         curl \
         parted \
         unzip \
         zerofree \
         zip \
    && rm -rf /var/lib/apt/lists/*
COPY clafoutis /bin/clafoutis
