SHELL=/bin/bash
DIR=$(shell pwd)
USER=$(shell id -un)
UID=$(shell id -u)
METALLB_IMAGE=localhost/kevydotvinu/go-devtainer-metallb
INSTALLER_IMAGE=localhost/kevydotvinu/go-devtainer-installer
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

.PHONY: openshift-installer-build

openshift-installer-build:
	@$(eval DOCKERFILE := Containerfile.openshift-installer)
	@${PODMAN} build --file ${DOCKERFILE} \
		         --tag ${INSTALLER_IMAGE} \
			 --no-cache \
			 --build-arg USER=${USER} \
			 --build-arg UID=${UID} \
			 --build-arg GO_VERSION=go \
			 .

.PHONY: openshift-installer-run

openshift-installer-run: check-env
	@${PODMAN} run --rm \
		       --name go-devtainer \
		       --user ${USER} \
		       --hostname go-devtainer \
		       --interactive \
		       --tty \
		       --volume ${WORKDIR}:/home/${USER}/code/src/github.com/kevydotvinu/$$(basename ${WORKDIR}) \
		       ${INSTALLER_IMAGE}

.PHONY: metallb-build

metallb-build:
	@$(eval DOCKERFILE := Containerfile.metallb)
	@${PODMAN} build --security-opt label=disable \
		         --file ${DOCKERFILE} \
			 --tag ${METALLB_IMAGE} \
			 --no-cache \
			 --build-arg USER=${USER} \
			 --build-arg UID=${UID} \
			 --build-arg GO_VERSION=go \
			 .

.PHONY: metallb-run

metallb-run: check-env
	@${PODMAN} run --security-opt label=disable \
		       --rm --name go-devtainer \
		       --net host \
		       --user ${USER} \
		       --hostname go-devtainer \
		       --interactive \
		       --tty \
		       --volume ${HOME}/go:/home/${USER}/go \
		       --volume ${WORKDIR}:/home/${USER}/code/src/go.universe.tf/$$(basename ${WORKDIR}) \
		       --volume ${HOME}/.kube:/home/${USER}/.kube \
		       ${METALLB_IMAGE}
