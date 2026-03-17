# syntax=docker/dockerfile:1.6
FROM us.gcr.io/broad-dsp-gcr-public/terra-base:1.0.0

USER root
ARG DEBIAN_FRONTEND=noninteractive

# Pin an OSS RStudio Server version; override at build time if desired
# Example:
#   docker build --build-arg RSTUDIO_VERSION=2024.12.0-467 .
ARG RSTUDIO_VERSION=2024.12.0-467

# Jammy (22.04) AMD64 builds are typically published here.
ARG RSTUDIO_DEB_URL="https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb"

RUN mkdir -p /var/lib/apt/lists/partial /var/cache/apt/archives/partial \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    gdebi-core \
    psmisc \
    procps \
    sudo \
 && rm -rf /var/lib/apt/lists/*

RUN wget -qO /tmp/rstudio-server.deb "${RSTUDIO_DEB_URL}" \
 && gdebi -n /tmp/rstudio-server.deb \
 && rm -f /tmp/rstudio-server.deb

# Create a user you can log in as via RStudio
RUN useradd -m -s /bin/bash rstudio \
 && echo "rstudio:rstudio" | chpasswd \
 && adduser rstudio sudo \
 && echo "rstudio ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

EXPOSE 8787
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0", "--www-port=8787"]
