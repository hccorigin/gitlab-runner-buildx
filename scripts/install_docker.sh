#!/bin/bash

set -e

# Docker,Compose 설치 for DEBIAN
echo "DOCKER_VERSION = ${DOCKER_VERSION}"
echo ">>Downloading Docker packages..."
DOCKER_TARGET=$(case ${TARGETARCH} in \
"arm64")    echo "arm64" ;; \
"amd64")    echo "amd64"  ;; \
"ppc64el")  echo "ppc64le" ;; \
*)          echo "${TARGETARCH}" ;; esac)
echo "${DOCKER_TARGET}"
DOCKER_DOWNLOAD=https://download.docker.com/linux/debian/dists/bookworm/pool/stable
curl -LO $DOCKER_DOWNLOAD/$DOCKER_TARGET/containerd.io_1.7.22-1_amd64.deb
curl -LO $DOCKER_DOWNLOAD/$DOCKER_TARGET/docker-ce_27.3.1-1~debian.12~bookworm_amd64.deb
curl -LO $DOCKER_DOWNLOAD/$DOCKER_TARGET/docker-ce-cli_27.3.1-1~debian.12~bookworm_amd64.deb
curl -LO $DOCKER_DOWNLOAD/$DOCKER_TARGET/docker-buildx-plugin_0.17.1-1~debian.12~bookworm_amd64.deb
curl -LO $DOCKER_DOWNLOAD/$DOCKER_TARGET/docker-compose-plugin_2.29.7-1~debian.12~bookworm_amd64.deb
curl -LO $DOCKER_DOWNLOAD/$DOCKER_TARGET/docker-scan-plugin_0.23.0~debian-bookworm_amd64.deb

echo ">> installing docker..."
dpkg -i ./containerd.io_1.7.22-1_amd64.deb \
  ./docker-ce_27.3.1-1~debian.12~bookworm_amd64.deb \
  ./docker-ce-cli_27.3.1-1~debian.12~bookworm_amd64.deb \
  ./docker-buildx-plugin_0.17.1-1~debian.12~bookworm_amd64.deb \
  ./docker-compose-plugin_2.29.7-1~debian.12~bookworm_amd64.deb
rm *.deb

# docker start service : chnage 62 line option 
# 동시최대접속자수(ulimit -Hn 524288 -> ulimit -Hn 524288)
cat /etc/init.d/docker
sed -i 's/ulimit -Hn/ulimit -n/g' /etc/init.d/docker


#Client: Docker Engine - Community
# Version:    27.3.1
# Context:    default
# Debug Mode: false
# Plugins:
#  buildx: Docker Buildx (Docker Inc.)
#    Version:  v0.17.1
#    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
#  compose: Docker Compose (Docker Inc.)
#    Version:  v2.29.7
#    Path:     /usr/libexec/docker/cli-plugins/docker-compose#
#Server:
# Containers: 0
#  Running: 0
#  Paused: 0
#  Stopped: 0
# Images: 0
# Server Version: 27.3.1
# Storage Driver: vfs
# Logging Driver: json-file
# Cgroup Driver: cgroupfs
# Cgroup Version: 1
# Plugins:
#  Volume: local
#  Network: bridge host ipvlan macvlan null overlay
#  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
# Swarm: inactive
# Runtimes: io.containerd.runc.v2 runc
# Default Runtime: runc
# Init Binary: docker-init
# containerd version: 7f7fdf5fed64eb6a7caf99b3e12efcf9d60e311c
# runc version: v1.1.14-0-g2c9f560
# init version: de40ad0
# Security Options:
#  seccomp
#   Profile: builtin
# Kernel Version: 4.18.0-348.7.1.el8_5.x86_64
# Operating System: Debian GNU/Linux 12 (bookworm) (containerized)
# OSType: linux
# Architecture: x86_64
# CPUs: 4
# Total Memory: 7.492GiB
# Name: runner
# ID: d54ee88c-7e13-49ae-ae79-83a0c31e6d82
# Docker Root Dir: /var/lib/docker
# Debug Mode: false
# Experimental: false
# Insecure Registries:
#  127.0.0.0/8
# Live Restore Enabled: false
