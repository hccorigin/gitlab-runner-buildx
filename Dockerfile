
# syntax=docker/dockerfile:1.2
# <- BuildKit new features 사용을 위해서 반드시 적어줘야함.

ARG DEBIAN_VERSION=12
ARG DEBIAN_VERSION_CODENAME=bookworm
ARG GITLAB_RUNNER_VERSION=16.10.0
ARG PYTHON_VERSION=3.12
ARG PYTHON_PIP_VERSION=24.0
ARG PYTHON_SETUPTOOLS_VERSION=58.1.0
ARG DOCKER_VERSION=25.0.2

#[===========================================================================] 
#[] Install python user's packages
# copy or cache mount 방식중 이미지 크기를 줄이는 방식을 택하자.
FROM --platform=$BUILDPLATFORM python:${PYTHON_VERSION} as python-pkg
COPY pypi/requirements.txt .
# pip에게 케시 위치를 알려주는 환경 변수
ENV PIP_CACHE_DIR=/root/.cache/pip
RUN mkdir -p $PIP_CACHE_DIR 
RUN \
    --mount=type=cache,target=/root/.cache/pip <<EOT
    pip install --upgrade pip wheel setuptools
    pip install -r requirements.txt
    ls -al /root/.cache/pip
EOT

FROM --platform=$BUILDPLATFORM python:${PYTHON_VERSION} as gitlab-runner
ARG TARGETOS
ARG TARGETARCH
WORKDIR /var/install_pkgs
RUN \
    --mount=type=bind,source=scripts/install_pkgs.sh,target=./install_pkgs.sh <<EOT
    echo $PWD
    ls -al
    sh install_pkgs.sh
    
EOT

# Executable Test
# whereis gitlab-runner -v && whereis kubectl version  && whereis trivy -v && whereis helm version && whereis helm2 version && whereis tiller2 -version
RUN whereis trivy 


#[===========================================================================] 
#[] import python tool && packages
FROM --platform=$BUILDPLATFORM python:${PYTHON_VERSION} as base
ARG TARGETPLATFORM
ARG TARGETARCH
# os and python packages installed:
COPY --from=python-pkg /usr/local/bin /usr/local/bin
COPY --from=python-pkg /usr/local/lib /usr/local/lib
COPY --from=gitlab-runner /usr/bin/trivy /usr/bin/trivy
COPY --from=gitlab-runner /var/install_pkgs/gitlab-runner /usr/bin/gitlab-runner
COPY --from=gitlab-runner /var/install_pkgs/kubectl /usr/bin/kubectl
COPY --from=gitlab-runner /var/install_pkgs/helm /usr/bin/helm
COPY --from=gitlab-runner /var/install_pkgs/helm2 /usr/bin/helm2
COPY --from=gitlab-runner /var/install_pkgs/tiller2 /usr/bin/tiller2
COPY --from=gitlab-runner /usr/bin/dumb-init /usr/bin/dumb-init


RUN chmod +x /usr/bin/dumb-init \
        /usr/bin/gitlab-runner \
        /usr/bin/kubectl \
        /usr/bin/trivy \
        /usr/bin/helm \
        /usr/bin/helm2 \
        /usr/bin/tiller2 \
    && rm -f /etc/apt/apt.conf.d/docker-clean

# install apt users tools
# -> debian 기준 cache for apt as "/var/cache/apt", 이 mount 디렉토리에 설치된 것들과 다를경우만 재설치한다.
# -> clamav: installed on /etc/clamav
# -> docker: iptables less ssh
# Could not get lock /var/cache/apt/archives/lock 오류대처방법
# killall apt apt-get
# or rm -rf /var/cache/apt/archives/lock
#    rm -rf /var/lib/dpkg/lock*
#    rm -rf /var/lib/apt/lists/lock

# Dockerfile 빌드시 "platform=linux/arm64,linux/amd64" 옵션으로
# 병렬 프로세스로 빌드시 apt 동시접근시 발생하는 .lock파일 충돌을 막기 위해서
# 'sharing=locked' 옵션을 추가해 줘야 합니다.
RUN \
    --mount=type=cache,sharing=locked,target=/var/cache/apt <<EOT
    set -e
    echo "Building on ${BUILDPLATFORM} ..."
    apt-get update -y
    apt-get upgrade -y
    apt-get install -yqq --no-install-recommends \
        sudo tzdata bash curl wget ncat iperf3 psmisc \
        mc htop git tmux vim bash-completion dnsutils net-tools \
        iptables less openssl \
        clamav clamav-daemon \
        qemu-user-static binfmt-support
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOT



#[===========================================================================] 
#[==] release
FROM --platform=$BUILDPLATFORM base as release
ARG TARGETPLATFORM
ARG TARGETARCH
COPY --chmod=777 scripts/entrypoint /
WORKDIR /home/gitlab-runner
COPY --chmod=775 scripts/create_builder.sh .
COPY --chmod=775 scripts/create_executor.sh .
COPY --chmod=775 tools ./tools
VOLUME [/etc/gitlab-runner, /home/gitlab-runner]
STOPSIGNAL SIGQUIT
RUN groupadd gitlab-runner \
    && useradd -g gitlab-runner gitlab-runner
ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
