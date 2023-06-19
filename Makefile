SHELL=/bin/bash
DIR=$(shell pwd)
USER=$(shell id -un)
UID=$(shell id -u)
IMAGE=localhost/kevydotvinu/go-devtainer
CONTAINERFILE=${DIR}/Containerfile.ubuntu

ifeq ($(USER), 0)
        PODMAN=podman
else
        PODMAN=sudo podman
endif

check-env:
ifndef WORKDIR
	$(error WORKDIR is undefined | Set repository path as volume)
endif

.PHONY: go-devtainer
go-devtainer: build run

build:
	${PODMAN} build . -f ${DOCKERFILE} -t ${IMAGE} --no-cache --build-arg USER=${USER} --build-arg UID=${UID} --build-arg GO_VERSION=go

run: check-env
	@${PODMAN} run --rm --name go-devtainer --user ${USER} --hostname go-devtainer -it -v ${WORKDIR}:/home/${USER}/code/src/github.com/kevydotvinu/$$(basename ${WORKDIR}) ${IMAGE}

.PHONY: openshift-installer

openshift-installer: check-env
	@$(eval DOCKERFILE := Containerfile.openshift-installer)
	@${PODMAN} build . -f ${DOCKERFILE} -t ${IMAGE} --no-cache --build-arg USER=${USER} --build-arg UID=${UID} --build-arg GO_VERSION=go
	@echo ""
	@echo "To build openshift-baremetal-install, run: TAGS='baremetal libvirt' hack/build.sh"
	@echo ""
	@${PODMAN} run --rm --name go-devtainer --user ${USER} --hostname go-devtainer -it -v ${WORKDIR}:/home/${USER}/code/src/github.com/kevydotvinu/$$(basename ${WORKDIR}) ${IMAGE}

.PHONY: metallb

metallb: check-env
	@$(eval DOCKERFILE := Containerfile.metallb)
	@${PODMAN} build --security-opt label=disable . -f ${DOCKERFILE} -t ${IMAGE} --no-cache --build-arg USER=${USER} --build-arg UID=${UID} --build-arg GO_VERSION=go
	@${PODMAN} run --security-opt label=disable \
		       --rm --name go-devtainer \
		       --net host \
		       --user ${USER} \
		       --hostname go-devtainer \
		       --interactive \
		       --tty \
		       --volume ${WORKDIR}:/home/${USER}/code/src/go.universe.tf/$$(basename ${WORKDIR}) \
		       --volume ${HOME}/.kube:/home/${USER}/.kube \
		       ${IMAGE}
