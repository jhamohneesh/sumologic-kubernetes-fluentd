BUILD_TAG ?= latest
BUILD_CACHE_TAG = latest-builder-cache
IMAGE_NAME = kubernetes-fluentd
ECR_URL = odidev
REPO_URL = $(ECR_URL)/$(IMAGE_NAME)

build:
	DOCKER_BUILDKIT=1 docker buildx build --platform linux/amd64 \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		--cache-from $(REPO_URL):$(BUILD_CACHE_TAG) \
		--target builder \
		--tag $(IMAGE_NAME):$(BUILD_CACHE_TAG) \
	        .

	DOCKER_BUILDKIT=1 docker buildx build --platform linux/amd64 \
		--build-arg BUILD_TAG=$(BUILD_TAG) \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		--cache-from $(REPO_URL):$(BUILD_CACHE_TAG) \
		--cache-from $(REPO_URL):latest \
		--tag $(IMAGE_NAME):$(BUILD_TAG) \
		.

build-arm64:
        DOCKER_BUILDKIT=1 docker buildx build --platform linux/arm64 \
                --build-arg BUILDKIT_INLINE_CACHE=1 \
                --cache-from $(REPO_URL):$(BUILD_CACHE_TAG) \
                --target builder \
                --tag $(IMAGE_NAME):$(BUILD_CACHE_TAG)-arm64 \
                -f Dockerfile.aarch64 \
                .

        DOCKER_BUILDKIT=1 docker buildx build --platform linux/arm64 \
                --build-arg BUILD_TAG=$(BUILD_TAG) \
                --build-arg BUILDKIT_INLINE_CACHE=1 \
                --cache-from $(REPO_URL):$(BUILD_CACHE_TAG) \
                --cache-from $(REPO_URL):latest \
                --tag $(IMAGE_NAME):$(BUILD_TAG)-arm64 \
                -f Dockerfile.aarch64 \
                .

push:
	docker tag $(IMAGE_NAME):$(BUILD_CACHE_TAG) $(REPO_URL):$(BUILD_CACHE_TAG)
	docker push $(REPO_URL):$(BUILD_CACHE_TAG)
	docker tag $(IMAGE_NAME):$(BUILD_TAG) $(REPO_URL):$(BUILD_TAG)
	docker push $(REPO_URL):$(BUILD_TAG)
	docker tag $(IMAGE_NAME):$(BUILD_CACHE_TAG)-arm64 $(REPO_URL):$(BUILD_CACHE_TAG)-arm64
	docker push $(REPO_URL):$(BUILD_CACHE_TAG)-arm64
	docker tag $(IMAGE_NAME):$(BUILD_TAG)-arm64 $(REPO_URL):$(BUILD_TAG)-arm64
	docker push $(REPO_URL):$(BUILD_TAG)-arm64

login:
	docker login --username odidev --password nibble@123

.PHONY: image-test
image-test:
	ruby test/test_docker.rb

.PHONY: test
test: test-fluent-plugin-datapoint test-fluent-plugin-enhance-k8s-metadata test-fluent-plugin-events test-fluent-plugin-kubernetes-metadata-filter test-fluent-plugin-kubernetes-sumologic test-fluent-plugin-prometheus-format test-fluent-plugin-protobuf

.PHONY: test-fluent-plugin-datapoint
test-fluent-plugin-datapoint:
	( cd fluent-plugin-datapoint && bundle install && bundle exec rake )

.PHONY: test-fluent-plugin-enhance-k8s-metadata
test-fluent-plugin-enhance-k8s-metadata:
	( cd fluent-plugin-enhance-k8s-metadata && bundle install && bundle exec rake )

.PHONY: test-fluent-plugin-events
test-fluent-plugin-events:
	( cd fluent-plugin-events && bundle install && bundle exec rake )

.PHONY: test-fluent-plugin-kubernetes-metadata-filter
test-fluent-plugin-kubernetes-metadata-filter:
	( cd fluent-plugin-kubernetes-metadata-filter && bundle install && bundle exec rake )

.PHONY: test-fluent-plugin-kubernetes-sumologic
test-fluent-plugin-kubernetes-sumologic:
	( cd fluent-plugin-kubernetes-sumologic && bundle install && bundle exec rake )

.PHONY: test-fluent-plugin-prometheus-format
test-fluent-plugin-prometheus-format:
	( cd fluent-plugin-prometheus-format && bundle install && bundle exec rake )

.PHONY: test-fluent-plugin-protobuf
test-fluent-plugin-protobuf:
	( cd fluent-plugin-protobuf && bundle install && bundle exec rake )
