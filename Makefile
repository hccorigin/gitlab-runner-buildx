# 주의: --load 옵션 사용시 local Docker engine 의 CPU arch 타입에 맞게 --platform 옵션을 지정해야 한다.

export BUILDX_CMD ?= docker buildx
# --progress=plain : stdout 출력 하게함.
# --push : docker hub에 저장됨.
# --builder
# upload to DockerHub as multi architecure


#export RUNNER_VER=16.11.3
export RUNNER_VER=17.4.1
export PYTHON_VERSION=bookworm
export DOCKER_VERSION=27.3.1
# Create and push the manifest
.PHONY: all
all: release-arm64 release-amd64
	docker buildx imagetools create --tag hccorigin/gitlab-runner:${RUNNER_VER} hccorigin/gitlab-runner:${RUNNER_VER}-arm64 hccorigin/gitlab-runner:${RUNNER_VER}-amd64
	docker buildx imagetools inspect hccorigin/gitlab-runner:${RUNNER_VER}


.PHONY: release-update
release-update:
	$(BUILDX_CMD) imagetools create --tag hccorigin/gitlab-runner:${RUNNER_VER} hccorigin/gitlab-runner:${RUNNER_VER}-arm64 hccorigin/gitlab-runner:${RUNNER_VER}-amd64
	$(BUILDX_CMD) imagetools inspect hccorigin/gitlab-runner:${RUNNER_VER}

# upload to Docker Engine as only linux/arm64
.PHONY: release-arm64
release-arm64:
	$(BUILDX_CMD) build \
		--push \
		--target release \
		--platform=linux/arm64 \
		--progress=plain --no-cache \
		--build-arg GITLAB_RUNNER_VERSION=${RUNNER_VER} \		
		--build-arg PYTHON_VERSION=${PYTHON_VERSION} \
		--build-arg DOCKER_VERSION=${DOCKER_VERSION} \
		-t hccorigin/gitlab-runner:${RUNNER_VER}-arm64 \
		-f Dockerfile .

# upload to Docker Engine as only linux/amd64
.PHONY: release-amd64
release-amd64:
	$(BUILDX_CMD) build \
		--push \
		--target release \
		--platform=linux/amd64 \
		--progress=plain --no-cache \
		--build-arg GITLAB_RUNNER_VERSION=${RUNNER_VER} \
		--build-arg PYTHON_VERSION=${PYTHON_VERSION} \
		--build-arg DOCKER_VERSION=${DOCKER_VERSION} \
		-t hccorigin/gitlab-runner:${RUNNER_VER}-amd64 \
		-f Dockerfile .

# upload to Docker hub as only linux/arm64
.PHONY: aws-deploy-arm64
aws-deploy-arm64:
	$(BUILDX_CMD) build \
		--push \
		--platform=linux/arm64 \
		--progress=plain --no-cache \
		--build-arg GITLAB_RUNNER_VERSION=${RUNNER_VER} \
		--build-arg PYTHON_VERSION=${PYTHON_VERSION} \
		-t hccorigin/aws-deploy-container:0.2-arm64 \
		-f Dockerfile.aws-deploy .


.PHONY: base-arm64
base-arm64:
	$(BUILDX_CMD) build \
		--push \
		--target base \
		--platform=linux/arm64 \
		--progress=plain --no-cache \
		--build-arg GITLAB_RUNNER_VERSION=${RUNNER_VER} \
		-t hccorigin/gitlab-runner:${RUNNER_VER}-base \
		-f Dockerfile .

.PHONY: base-amd64
base-amd64:
	$(BUILDX_CMD) build \
		--load \
		--target base \
		--platform=linux/amd64 \
		--progress=plain --no-cache \
		--build-arg GITLAB_RUNNER_VERSION=${RUNNER_VER} \
		-t hccorigin/gitlab-runner:${RUNNER_VER}-base \
		-f Dockerfile .

.PHONY: clear
clear:
	$(BUILDX_CMD) build prune
