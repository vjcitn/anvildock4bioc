# syntax=docker/dockerfile:1.6

FROM us.gcr.io/broad-dsp-gcr-public/terra-base:1.0.0

# terra-base runs as a non-root user; apt needs root and /var/lib/apt/lists/partial must exist.
USER root

ARG DEBIAN_FRONTEND=noninteractive

# Pin to a ref (tag, branch, or commit). "main" is fine but less reproducible.
ARG RSTUDIO_REF=main

# Ensure apt list directories exist and are writable, then install minimal prerequisites
RUN mkdir -p /var/lib/apt/lists/partial /var/cache/apt/archives/partial \
 && chmod -R 0755 /var/lib/apt/lists /var/cache/apt/archives \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    sudo \
    lsb-release \
    ca-certificates \
    git \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Build RStudio Server from source (Ubuntu 22.04 / jammy dependency set)
# ------------------------------------------------------------------------------

WORKDIR /opt/src

# Clone upstream source
RUN git clone https://github.com/rstudio/rstudio.git
WORKDIR /opt/src/rstudio
RUN git checkout "${RSTUDIO_REF}"

# Install build dependencies (Ubuntu 22.04 "jammy")
# This script installs a large set of apt deps and then runs dependencies/common/install-common jammy.
RUN chmod +x dependencies/linux/install-dependencies-jammy \
 && cd dependencies/linux \
 && ./install-dependencies-jammy

# Configure + build + install (per INSTALL doc)
# Default CMAKE_INSTALL_PREFIX for Server on Linux is /usr/local/lib/rstudio-server.
RUN mkdir -p build \
 && cd build \
 && cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release \
 && make -j"$(nproc)" \
 && make install

# ------------------------------------------------------------------------------
# Runtime configuration for container usage
# ------------------------------------------------------------------------------

# Create service user as described in INSTALL (optional but recommended)
RUN useradd -r -m rstudio-server || true

# Required runtime directories (INSTALL)
RUN mkdir -p /var/log/rstudio/rstudio-server \
 && mkdir -p /var/lib/rstudio-server \
 && chown -R rstudio-server:rstudio-server /var/log/rstudio /var/lib/rstudio-server

# Expose default port
EXPOSE 8787

# Run in foreground (container-friendly).
# rserver is installed under /usr/local/lib/rstudio-server/bin by default.
CMD ["/usr/local/lib/rstudio-server/bin/rserver", "--server-daemonize=0", "--www-port=8787"]