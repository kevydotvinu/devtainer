SHELL := /bin/bash
DIR := $(shell pwd)
USER := $(shell id -un)
UID := $(shell id -u)

ifeq ($(USER), 0)
	PODMAN := podman
else
	PODMAN := sudo podman
endif

define go-devtainer
	@$(PODMAN) build --security-opt label=disable \
					--file $(DOCKERFILE) \
					--tag localhost/kevydotvinu/$(notdir $(WORKDIR)) \
					--build-arg USER=$(USER) \
					--build-arg UID=$(UID) \
					--build-arg GO_VERSION=go \
					.
	@ls $(WORKDIR) || git clone $(FORK) $(WORKDIR)
	@git -C $(WORKDIR) checkout $$(git -C $(WORKDIR) branch -l master main | sed 's/^* //')
	git -C $(WORKDIR) remote add upstream $(UPSTREAM) || true
	git -C $(WORKDIR) fetch upstream $$(git -C $(WORKDIR) branch -l master main | sed 's/^* //')
	git -C $(WORKDIR) merge upstream/$$(git -C $(WORKDIR) branch -l master main | sed 's/^* //')
	git -C $(WORKDIR) --no-pager branch -a
	@$(PODMAN) run --security-opt label=disable \
					--rm --name go-devtainer-$(notdir $(WORKDIR)) \
					--net host \
					--user $(USER) \
					--hostname go-devtainer-$(notdir $(WORKDIR)) \
					--interactive \
					--tty \
					--volume $(HOME)/go:/home/$(USER)/go \
					--volume $(WORKDIR):$(WORKDIR) \
					--volume $(HOME)/.kube:/home/$(USER)/.kube \
					--volume /run/user/$(UID)/gnupg:/home/$(USER)/.gnupg \
					--workdir $(WORKDIR) \
					localhost/kevydotvinu/$(notdir $(WORKDIR))
endef

.PHONY: help $(TARGETS)

help:
	@echo "AVAILABLE TARGETS"
	@echo ${TARGETS} | tr ' ' '\n'

TARGETS := metallb-metallb openshift-installer openshift-oc

$(TARGETS): % : %-env
	$(go-devtainer)

metallb-metallb-env:
	@$(eval WORKDIR := ${HOME}/code/src/go.universe.tf/metallb)
	@$(eval DOCKERFILE := Containerfile.metallb-metallb)
	@$(eval FORK := git@github.com:kevydotvinu/metallb-metallb)
	@$(eval UPSTREAM := git@github.com:metallb/metallb)

openshift-installer-env:
	@$(eval WORKDIR := ${HOME}/code/src/github.com/kevydotvinu/openshift-installer)
	@$(eval DOCKERFILE := Containerfile.openshift-installer)
	@$(eval FORK := git@github.com:kevydotvinu/openshift-installer)
	@$(eval UPSTREAM := git@github.com:openshift/installer)

openshift-oc-env:
	@$(eval WORKDIR := ${HOME}/code/src/github.com/kevydotvinu/openshift-oc)
	@$(eval DOCKERFILE := Containerfile.openshift-oc)
	@$(eval FORK := git@github.com:kevydotvinu/openshift-oc)
	@$(eval UPSTREAM := git@github.com:openshift/oc)
