REPO := $(shell basename $$(git rev-parse --show-toplevel))
DOCKER_IMAGE := yunielrc/$(REPO):latest
DOCKER_CONTAINER := $(REPO)
VERSION=v$(shell date +'%Y%m%d-%H%M%S')

.PHONY: commit push-version build run remove build-run test

commit:
	git cz

push-version:
	git tag -a "$(VERSION)" -m "New version $(VERSION)"
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
