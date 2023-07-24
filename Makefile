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
	@$(eval WORKDIR := ../$(subst -env,,$@))
	@$(eval DOCKERFILE := Containerfile.$(subst -env,,$@))
	@$(eval FORK := git@github.com:kevydotvinu/$(subst -env,,$@))
	@$(eval UPSTREAM := git@github.com:$(subst -,/,$(subst -env,,$@)))
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
					--volume $(WORKDIR):/home/$(USER)/code/src/go.universe.tf/$(notdir $(WORKDIR)) \
					--volume $(HOME)/.kube:/home/$(USER)/.kube \
					--volume /run/user/$(UID)/gnupg:/home/$(USER)/.gnupg \
					--workdir /home/$(USER)/code/src/go.universe.tf/$(notdir $(WORKDIR)) \
					localhost/kevydotvinu/$(notdir $(WORKDIR))
endef

TARGETS := metallb-metallb openshift-installer openshift-oc

$(TARGETS):
	$(go-devtainer)

.PHONY: $(TARGETS) $(addsuffix -env,$(TARGETS))
