SHELL := /bin/bash
DIR := $(shell pwd)
USER := $(shell id -un)
UID := $(shell id -u)
BUILDOPTS ?=
RUNOPTS ?=

ifeq ($(USER), 0)
	PODMAN := podman
else
	PODMAN := sudo podman
endif

define devtainer
	@$(PODMAN) build --security-opt label=disable \
					${BUILDOPTS} \
					--file $(CONTAINERFILE) \
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
					${RUNOPTS} \
					--rm --name devtainer \
					--user $(USER) \
					--hostname devtainer \
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

TARGETS := metallb-metallb openshift-installer openshift-oc openshift-baremetal-runtimecfg

$(TARGETS): % : %-env
	$(devtainer)

metallb-metallb-env:
	@$(eval WORKDIR := ${HOME}/code/src/go.universe.tf/metallb)
	@$(eval CONTAINERFILE := metallb-metallb/Containerfile)
	@$(eval FORK := git@github.com:kevydotvinu/metallb-metallb)
	@$(eval UPSTREAM := git@github.com:metallb/metallb)

openshift-installer-env:
	@$(eval WORKDIR := ${HOME}/code/src/github.com/kevydotvinu/openshift-installer)
	@$(eval CONTAINERFILE := openshift-installer/Containerfile)
	@$(eval FORK := git@github.com:kevydotvinu/openshift-installer)
	@$(eval UPSTREAM := git@github.com:openshift/installer)

openshift-oc-env:
	@$(eval WORKDIR := ${HOME}/code/src/github.com/kevydotvinu/openshift-oc)
	@$(eval CONTAINERFILE := openshift-oc/Containerfile)
	@$(eval FORK := git@github.com:kevydotvinu/openshift-oc)
	@$(eval UPSTREAM := git@github.com:openshift/oc)

openshift-baremetal-runtimecfg-env:
	@$(eval WORKDIR := ${HOME}/code/src/github.com/kevydotvinu/baremetal-runtimecfg)
	@$(eval CONTAINERFILE := openshift-oc/Containerfile)
	@$(eval FORK := git@github.com:kevydotvinu/openshift-baremetal-runtimecfg)
	@$(eval UPSTREAM := git@github.com:openshift/baremetal-runtimecfg)
