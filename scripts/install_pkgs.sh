#!/bin/bash

set -e


echo "Working directory=$PWD"
echo "TARTGET OS=$TARGETOS"
echo "TARTGET ARCH=$TARGETARCH"

# dumb-init
echo ">> dumb-init downloading..."


DUMB_INT_VERSION="1.2.5"
DUMB_TARGET=$(uname -m)
# new binary
DUMB_TARGET=$(case ${TARGETARCH} in \
"arm64")    echo "aarch64" ;; \
"amd64")    echo "x86_64"  ;; \
"ppc64el")  echo "ppc64le" ;; \
*)          echo "${TARGETARCH}" ;; esac)
echo "${DUMB_TARGET}"
# New version
DUMB_INT_ARCH_FILE="dumb-init_${DUMB_INT_VERSION}_${DUMB_TARGET}"
#DUMB_INT_ARCH_FILE="dumb-init_${DUMB_INT_VERSION}_${TARGETARCH}.deb"
URL_DUMB_INIT="https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INT_VERSION}"
curl -L "${URL_DUMB_INIT}/${DUMB_INT_ARCH_FILE}" -o /usr/bin/dumb-init
#curl -LO "${URL_DUMB_INIT}/${DUMB_INT_ARCH_FILE}"
#dpkg --add-architecture arm64
#dpkg -i ${DUMB_INT_ARCH_FILE}
echo "Installed dumb-init>>>$(whereis dumb-init)"

# GitLab Runner
# https://docs.gitlab.com/runner/install/linux-manually.html#using-binary-file
echo ">> GitLab-Runner downloading..."
URL_AWS_S3="https://gitlab-runner-downloads.s3.amazonaws.com"
curl -L "${URL_AWS_S3}/latest/binaries/gitlab-runner-linux-${TARGETARCH}" -o gitlab-runner

# kubectl
 echo ">> KubeCtl downloading..."
URL_K8S="https://dl.k8s.io"
KUBECTL_VERSION=$(curl -L -s "${URL_K8S}/release/stable.txt")
curl -LO "${URL_K8S}/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl"

# trivy
echo ">> Trivy downloading..."
TRIVY_ARCH=$(case ${TARGETARCH:-amd64} in \
"amd64")   echo "64bit"  ;; \
"arm/v6")  echo "ARM"   ;; \
"arm/v7")  echo "ARM"   ;; \
"arm64")   echo "ARM64" ;; \
"ppc64le") echo "PPC64LE" ;; \
"s390x")   echo "s390x"   ;; \
*)               echo ""        ;; esac)
TRIVY_VERSION=$(curl -L -s https://api.github.com/repos/aquasecurity/trivy/releases/latest| sed -En 's/"tag_name": "v(.+)",/\1/p'|sed 's/^ *//g')
TRIVY_ARCH_FILE="trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.deb"
URL_TRIVY="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}"
echo "TRIVY_VERSION=${TRIVY_VERSION}"
echo "URL_TRIVY=${URL_TRIVY}"
echo "TRIVY_ARCH_FILE=${TRIVY_ARCH_FILE}"
curl -LO "${URL_TRIVY}/${TRIVY_ARCH_FILE}"
dpkg -i ${TRIVY_ARCH_FILE}
#tar -xzf "${TRIVY_ARCH_FILE}"
whereis trivy

# Helm
echo ">> Helm downloading..."
HELM_ARCH=$(case ${TARGETARCH:-amd64} in \
"amd64")   echo "amd64"  ;; \
"arm/v5")  echo "armv5"   ;; \
"arm/v6")  echo "armv6"   ;; \
"arm/v7")  echo "arm"   ;; \
"arm64")   echo "arm64" ;; \
"ppc64le") echo "ppc64le" ;; \
"s390x")   echo "s390x"   ;; \
*)               echo ""        ;; esac)
#-> tags:2.17.0
HELM_VERSION="v2.17.0"
HELM_ARCH_FILE="helm-$HELM_VERSION-$TARGETOS-$HELM_ARCH.tar.gz"
URL_HELM="https://get.helm.sh"
echo "DOWN FROM HELM=${URL_HELM}/${HELM_ARCH_FILE}"
curl -LO "${URL_HELM}/${HELM_ARCH_FILE}"
tar -xzf "${HELM_ARCH_FILE}" --strip-components=1
mv -f helm helm2
mv -f tiller tiller2

#-> tags:latest
HELM_VERSION=$(curl -L -s https://get.helm.sh/helm-latest-version)
HELM_ARCH_FILE="helm-$HELM_VERSION-$TARGETOS-$HELM_ARCH.tar.gz"
curl -LO "${URL_HELM}/${HELM_ARCH_FILE}"
tar -xzf "${HELM_ARCH_FILE}" --strip-components=1

whereis helm

ls -al
