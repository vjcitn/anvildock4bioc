# syntax=docker/dockerfile:1.6
FROM us.gcr.io/broad-dsp-gcr-public/terra-base:1.0.0

USER root
ARG DEBIAN_FRONTEND=noninteractive

# Pick a version that exists for jammy; override at build time if desired
ARG RSTUDIO_VERSION=2024.12.0-467
ARG RSTUDIO_DEB_URL="https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb"

# Ensure apt is usable and jammy repos are enabled (main + universe + updates + security)
RUN mkdir -p /var/lib/apt/lists/partial /var/cache/apt/archives/partial \
 && if [ -f /etc/os-release ]; then . /etc/os-release; fi \
 && echo "Detected: ${ID:-unknown} ${VERSION_CODENAME:-unknown}" \
 && if [ "${VERSION_CODENAME:-}" = "jammy" ]; then \
      printf "%s\n" \
        "deb http://archive.ubuntu.com/ubuntu jammy main universe" \
        "deb http://archive.ubuntu.com/ubuntu jammy-updates main universe" \
        "deb http://security.ubuntu.com/ubuntu jammy-security main universe" \
        > /etc/apt/sources.list ; \
    else \
      echo "ERROR: base image is not jammy; VERSION_CODENAME=${VERSION_CODENAME:-unset}" >&2; \
      exit 1; \
    fi \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    gdebi-core \
    sudo \
    lsb-release \
    psmisc \
    procps \
    libclang-dev \
    libsqlite3-0 \
    libssl-dev \
 && rm -rf /var/lib/apt/lists/*

# Download + install RStudio Server
RUN wget -qO /tmp/rstudio-server.deb "${RSTUDIO_DEB_URL}" \
 && gdebi -n /tmp/rstudio-server.deb \
 && rm -f /tmp/rstudio-server.deb

# Create a user you can log into via RStudio
RUN useradd -m -s /bin/bash rstudio \
 && echo "rstudio:rstudio" | chpasswd \
 && adduser rstudio sudo \
 && echo "rstudio ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

EXPOSE 8787

ENTRYPOINT []

CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0", "--www-port=8787"]
