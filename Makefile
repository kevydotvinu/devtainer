SHELL=/bin/bash
DIR=$(shell pwd)
USER=$(shell id -un)
UID=$(shell id -u)
IMAGE=docker.io/kevydotvinu/go-devtainer
DOCKERFILE=${DIR}/Dockerfile.ubuntu

ifeq ($(USER), 0)
        PODMAN=podman
else
        PODMAN=sudo podman
endif

.PHONY: go-devtainer
go-devtainer: build run

check-env:
ifndef WORKDIR
	$(error WORKDIR is undefined | Set repository path as volume)
endif

build:
	${PODMAN} build . -f ${DOCKERFILE} -t ${IMAGE} --no-cache --build-arg USER=${USER} --build-arg UID=${UID} --build-arg GO_VERSION=go

run: check-env
	${PODMAN} run --rm --name godev --user ${USER} --hostname go-devtainer -it -v ${WORKDIR}:/home/${USER}/Code/src/github.com/kevydotvinu/$$(basename ${WORKDIR}) ${IMAGE}
