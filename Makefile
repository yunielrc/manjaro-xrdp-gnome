REPO := $(shell basename $$(git rev-parse --show-toplevel))
DOCKER_IMAGE := yunielrc/$(REPO):latest
DOCKER_CONTAINER := $(REPO)

.PHONY: commit build run remove build-run test

commit:
	git cz

push-version:
	version="v$$(date +"%Y%m%d-%H%M%S")"
	git tag -a "$${version}" -m "New version v$${version}"
	git push origin --tags

build:
	docker build -t $(DOCKER_IMAGE) .

run:
	docker run --name $(DOCKER_CONTAINER) \
		--privileged \
		--tty \
		--interactive \
		--shm-size 2G \
		--publish 23389:3389 \
		--publish 8022:22 \
		$(DOCKER_IMAGE)

remove:
	docker rm -f $(DOCKER_CONTAINER)

build-run: | remove build run

test: build
