# Build GitLab Runner Image supported multi CPU architecuture
GitLab-Runner 에서 Multi-Architecture Image 빌드 기능을 제공하기 위한 환경구성을 합니다.
> Multi-Architecture 란, Host CPU Architecture 에 무관하게 Arm64, Amd64, x86_64 같은 다양한 CPU Architecture 에 맞는 Docker image 를 빌드하게 해주는 기능입니다.

GitLab-Runner 가 실행중인 Host의 CPU architecure 와 다른 CPU architecure 를 지원하는 Docker image 를 빌드할 수 있게 docker buildx 를 지원하는 환경을 구성합니다. 

Non-native architecure 란 host와 다른 아키텍쳐를 의미 합니다.

예를들면, GitLab-Runner 가 x86_64 에서 실행중인데, Arm64 or Arm 기반의 Docker image 를 빌드할 수 있는 환경을 지원한다는 의미 입니다.

### QEMU 제공에 대한 참고사항
QEMU emulator 는 host 에 직접 설치해서 제공할 수도 있고, 또는 Docker image 로 제공할 수도 있습니다.

__여기서는 host에 직접 설치해서 제공합니다.__

### __Non-native architecure Docker image build 지원을 위한 최소 조건:__
* docker version 19.03+ : supports buildx experimental feature.
* kernel version 4.18+ : has binfmt_misc fix-binary (F) support.
* binfmt_misc mount : /proc/sys/fs/binfmt_misc is mounted
* update-binfmts : 2.1.7+ has fix-binary (F) support.
    - binfmt-support 설치시 자동설치됨.
* QEMU 설치: emulator 직접설치 또는 대체 docker image 중 택일
* QEMU registered in binfmt_misc with flags $flags (F is required).

# 1. Host 직접 설치해야 하는 것들:
1. 초기 설치: Github 에서 소스 다운로드, Makefile 로 Dockerfile 를 위한 툴
    ```bash
    $ sudo yum install git make curl
    ```
1. docker version 체크:
    ```bash
    $ docker version
    ```
1. kernel version 체크:
    ```bash
    $ uname -r
    ```
1. binfmt_misc mount 체크: kernel이 다른 architecture binary 를 식별하기 위한 binfmt 포맷이 설치되었는가를 확인합니다.
    ```bash
    $ ls /proc/sys/fs/binfmt_misc/
    register status
    ```

# 2. Host 에 QEMU 직접설치(Docker image로 제공할수도 있음)
1. QEMU 설치: 다른 architecture binary 실행을 위한 에뮬레이터 설치합니다.

    ```bash
    # 반드시 root 계정으로 설치해야합니다:
    debian: sudo apt-get install -y qemu-user-static
    redhat: sudo dnf install qemu-user-static
        qemu-common                    aarch64  2:2.11.1-2.fc28             
        qemu-user-static               aarch64  2:2.11.1-2.fc28

    # QEMU설치후 다른 아키텍쳐 설치확인:
    $ ls -l /usr/bin/qemu-*-static
    /usr/bin/qemu-aarch64-static
    /usr/bin/qemu-x86_64-static
    ...

    $ qemu-aarch64-static --version
        qemu-aarch64 version 2.11.1(qemu-2.11.1-2.fc28)
        Copyright (c) 2003-2017 Fabrice Bellard and the QEMU Project developers
    ```
1. update-binfmts Tool 설치: 
    >이 툴은 보통 binfmt-support package 에 포함되어 있기 때문에 이 툴을 설치합니다.
위 `qemu-user-static` 설치시에 추천 패키지로 자동 설치되므로 이미 설치되어 있을 겁니다.

    만일 설치되어 있지 않다면 직접 설치합니다:
    ```bash
    $ sudo apt-get install -y binfmt-support
    # 설치확인: 2.1.7+ 부터 fix-binary (F) flag 지원됨.
    $ update-binfmts --version
        binfmt-support 2.1.8
    ```

1. 지금까지 설치된 환경 최종 체크 쉘:
모두 `OK` 로 표시되야함:
    ```bash
    $ bash tools/check-qemu-binfmt.sh
        OK: docker 26.0.0 supports buildx experimental feature.
        OK: kernel 4.18.0-305.88.1.el8_4.aarch64 has binfmt_misc fix-binary (F) support.
        OK: /proc/sys/fs/binfmt_misc is mounted
        ERROR: Can't find update-binfmts. Install with 'sudo apt-get install binfmt-support'.
    ```

## 3. GitLab-Runner Wrapper 이미지 빌드
이미지를 빌드하기 위해 Makefile 을 사용합니다.

> x86_64(amd64) 머신에서 make all 로 arm64/amd64 를 동시에 빌드해서 Docker Hub 에 정상 업로드 한후,
aarch64(arm64) 머신에서 arm64 이미지를 pull 해서 실행해본 결과 binary 실행 오류발생함(더 테스트해봐야함)

### 최종 빌드 방식은 다음과 같이 진행 하였음:
1. x86_64(macOS) 머신에서 'make release-amd64' 이미지를 빌드후 DockerHub에 push
1. aarch64(tpdv) 머신에서 'make release-arm64' 이미지를 빌드후 DockerHub에 push
1. 위 2개의 머신중 1곳에서 'make release-update' 로 Docker Hub에 tag명 "15.5.9" 으로 amd64 와 arm64 2개의 이미지를 통합하였습니다.

#### Issue
DockerHub 에 image push 할때 아래와 같은 경고 메시지가 출력된다면, build 하는 현재 디렉토리에서 
'git config --global --add safe.directory < your build directory >' 명령어를 실행해준다음에 빌드한다.
```bash
current commit information was not captured by the build: failed to read current commit information with git rev-parse --is-inside-work-tree
```
#### 이미지 빌드 방법
```bash
# arm64기반 이미지 빌드
$ make release-arm64

# amd64
$ make release-amd64

# update manifest on Docker Hub
$ make release-update
```

## 4. GitLab Runner 실행방법
러너 실행은 `docker-compose.yml` 파일을 참고하면 됩니다.

실행 머신에 따라서 `platform: linux/arm64` 만 변경한후 사용하면 됩니다.

```bash
$ docker-compose down || docker compose up -d
```

### user permission 문제 해결
설치되는 host 머신의 디렉토리를 container의 `working_dir` 로 bind mount 하는 경우
모든 파이프라인에 대하여 `build` 디렉토리가 이 작업 디렉토리 아래에 생성이 되기 때문에 이 working_dir의
소유자 퍼미션 문제가 발생한다. 이런 경우 Dockerfile 내에 기본사용자인 'gitlab-runner' 를 무시하고
다음과 같이 설치되는 환경에 맞게 작업디렉토리 소유자를 컨테이너 내부에도 동일하게 일치시켜주기 위한 작업을 한다.
* host 러너 설치 디렉토리 소유자와 그룹을 컨테이너 내부에 uid and gid 동일하게 생성해준다.
* volume 에 bind mount 한 디렉토리를 working_dir: 지시자에 설정해준다.
* entrypoint 와 command 를 아래 예시와 같이 설정한다.
* 생성된 소유자로 gitlab-runner 서비스를 시작한다.

```yaml
working_dir: /prod/gitlab-runner
entrypoint: ["/bin/bash", "-c"]
command:
  - |
    groupadd docker --gid 1001
    useradd -g docker docker --uid 1001 -d /prod/gitlab-runner
    /usr/bin/dumb-init /entrypoint run --user=docker --working-directory=/prod/gitlab-runner
extra_hosts:
  - "xxx.example.com:xxx.xxx.xxx.xxx"
volume:
  - $PWD:/prod/gitlab-runner
```

### 파이프라인 실행시 퍼미션 오류
Runner 가 정상적으로 연결된후 파이프라인을 실행할때, 기 생성되었던 프로젝트가 로컬 러너 작업디렉토리로 다운로드 하게 되는데 이때 프로젝트를 처음 생성했던 사용자가 맴버로 등록되어 있지 않는다면 private 프로젝트는 다운로드 권한 오류가 발생하게 됩니다. 이런 경우는 현재 Gitlab의 'Admin' 사용자를 해당 프로젝트 맴버로 등록해주면 해결됩니다.



## 5. Executor 생성방법
연결할 Gitlab 이 실행되어 있어야 하고 이 GitLab 에 연결할 네트워크 설정등이 되어 있어야 합니다.
1. create_executor.sh 파일을 오픈후 생성할 executor 설정을 한후 저장합니다.
1. 위 shell 파일을 docker-compose.yml 파일에서 bind volume 마운트합니다.
1. docker-compose 실행합니다.
1. gitlab-runner container 로 진입합니다.
1. create_executor.sh 찾아서 실행합니다.
1. Gitlab Runner 메뉴에서 생성된 Executor들을 확인합니다.

```bash
# 생성할 executor 설정
$ vi scripts/create_executor.sh 
$ docker-compose up -d
# runner container 진입
$ docker exec -it gitlab-runner bash
# executor 생성
$ bash create_executor.sh
```

# 부록 
## Docker image 로 QEMU 제공방법
위 2번 QEMU를 Host에 직접 설치하는 방법대신 Docker image `multiarch/qemu-user-static and docker/binfmt` 로 대신 할 수 있습니다.


## 참고문헌
- https://medium.com/@artur.klauser/building-multi-architecture-docker-images-with-buildx-27d80f7e2408
