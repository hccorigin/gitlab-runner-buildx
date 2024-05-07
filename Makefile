# 주의: --load 옵션 사용시 local Docker engine 의 CPU arch 타입에 맞게 --platform 옵션을 지정해야 한다.

export BUILDX_CMD ?= docker buildx
# --progress=plain : stdout 출력 하게함.
# --push : docker hub에 저장됨.
# --builder
# upload to DockerHub as multi architecure

# Create and push the manifest
.PHONY: all
all: release-arm64 release-amd64
	docker buildx imagetools create --tag hccorigin/gitlab-runner:16.10.0 hccorigin/gitlab-runner:16.10.0-arm64 hccorigin/gitlab-runner:16.10.0-amd64
	docker buildx imagetools inspect hccorigin/gitlab-runner:16.10.0


.PHONY: release-update
release-update:
	$(BUILDX_CMD) imagetools create --tag hccorigin/gitlab-runner:16.10.0 hccorigin/gitlab-runner:16.10.0-arm64 hccorigin/gitlab-runner:16.10.0-amd64
	$(BUILDX_CMD) imagetools inspect hccorigin/gitlab-runner:16.10.0

# upload to Docker Engine as only linux/arm64
.PHONY: release-arm64
release-arm64:
	$(BUILDX_CMD) build \
		--push \
		--target release \
		--platform=linux/arm64 \
		--progress=plain --no-cache \
		-t hccorigin/gitlab-runner:16.10.0-arm64 \
		-f Dockerfile .

# upload to Docker Engine as only linux/amd64
.PHONY: release-amd64
release-amd64:
	$(BUILDX_CMD) build \
		--push \
		--target release \
		--platform=linux/amd64 \
		--progress=plain --no-cache \
		-t hccorigin/gitlab-runner:16.10.0-amd64 \
		-f Dockerfile .

# upload to Docker hub as only linux/arm64
.PHONY: aws-deploy-arm64
aws-deploy-arm64:
	$(BUILDX_CMD) build \
		--push \
		--platform=linux/arm64 \
		--progress=plain --no-cache \
		-t hccorigin/aws-deploy-container:0.2-arm64 \
		-f Dockerfile.aws-deploy .


.PHONY: base-arm64
base-arm64:
	$(BUILDX_CMD) build \
		--push \
		--target base \
		--platform=linux/arm64 \
		--progress=plain --no-cache \
		-t hccorigin/gitlab-runner:16.10.0-base \
		-f Dockerfile .

.PHONY: base-amd64
base-amd64:
	$(BUILDX_CMD) build \
		--load \
		--target base \
		--platform=linux/amd64 \
		--progress=plain --no-cache \
		-t hccorigin/gitlab-runner:16.10.0-base \
		-f Dockerfile .


.PHONY: clear
clear:
	$(BUILDX_CMD) build prune

