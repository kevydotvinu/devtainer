SHELL=/bin/bash
DIR=$(shell pwd)
USER=$(shell id -un)
UID=$(shell id -u)

ifeq ($(USER), 0)
        PODMAN=podman
else
        PODMAN=sudo podman
endif

go-devtainer-build:
	@${PODMAN} build --security-opt label=disable \
		         --file ${DOCKERFILE} \
			 --tag localhost/kevydotvinu/$$(basename ${WORKDIR}) \
			 --build-arg USER=${USER} \
			 --build-arg UID=${UID} \
			 --build-arg GO_VERSION=go \
			 .

go-devtainer-run:
	@ls ${WORKDIR} || git clone ${FORK} ${WORKDIR}
	@git -C ${WORKDIR} checkout $$(git -C ${WORKDIR} branch -l master main | sed 's/^* //')
	git -C ${WORKDIR} remote add upstream ${UPSTREAM} || true
	git -C ${WORKDIR} fetch upstream $$(git -C ${WORKDIR} branch -l master main | sed 's/^* //')
	git -C ${WORKDIR} merge upstream/$$(git -C ${WORKDIR} branch -l master main | sed 's/^* //')
	git -C ${WORKDIR} --no-pager branch -a
	@${PODMAN} run --security-opt label=disable \
		       --rm --name go-devtainer-$$(basename ${WORKDIR}) \
		       --net host \
		       --user ${USER} \
		       --hostname go-devtainer-$$(basename ${WORKDIR}) \
		       --interactive \
		       --tty \
		       --volume ${HOME}/go:/home/${USER}/go \
		       --volume ${WORKDIR}:/home/${USER}/code/src/go.universe.tf/$$(basename ${WORKDIR}) \
		       --volume ${HOME}/.kube:/home/${USER}/.kube \
		       --volume /run/user/${UID}/gnupg:/home/${USER}/.gnupg \
		       --workdir /home/${USER}/code/src/go.universe.tf/$$(basename ${WORKDIR}) \
		       localhost/kevydotvinu/$$(basename ${WORKDIR})

.PHONY: metallb-metallb

metallb-metallb: metallb-metallb-env go-devtainer-build go-devtainer-run

metallb-metallb-env:
	@$(eval WORKDIR := ../$(subst -env,,$@))
	@$(eval DOCKERFILE := Containerfile.$(subst -env,,$@))
	@$(eval FORK := git@github.com:kevydotvinu/$(subst -env,,$@))
	@$(eval UPSTREAM := git@github.com:$(subst -,/,$(subst -env,,$@)))

.PHONY: openshift-installer

openshift-installer: openshift-installer-env go-devtainer-build go-devtainer-run

openshift-installer-env:
	@$(eval WORKDIR := ../$(subst -env,,$@))
	@$(eval DOCKERFILE := Containerfile.$(subst -env,,$@))
	@$(eval FORK := git@github.com:kevydotvinu/$(subst -env,,$@))
	@$(eval UPSTREAM := git@github.com:$(subst -,/,$(subst -env,,$@)))

.PHONY: openshift-oc

openshift-oc: openshift-oc-env go-devtainer-build go-devtainer-run

openshift-oc-env:
	@$(eval WORKDIR := ../$(subst -env,,$@))
	@$(eval DOCKERFILE := Containerfile.$(subst -env,,$@))
	@$(eval FORK := git@github.com:kevydotvinu/$(subst -env,,$@))
	@$(eval UPSTREAM := git@github.com:$(subst -,/,$(subst -env,,$@)))
