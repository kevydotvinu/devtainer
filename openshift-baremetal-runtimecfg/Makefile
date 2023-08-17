.PHONY: help

help:
	@echo "AVAILABLE TARGETS"
	@awk '/^.PHONY:/ {print $$2}' ${HOME}/Makefile

.PHONY: ecmp6

ecmp6:
	sudo ip -6 r a default nexthop via 2607:f878::1 dev eth0 nexthop via 2607:f878::10 dev eth0
	ip -6 r

.PHONY: build

build:
	# GO111MODULE=on go build -gcflags "all=-N -l" -tags=delve --mod=vendor -o build ./cmd/...
	GO111MODULE=on go build --mod=vendor -o build ./cmd/...

.PHONY: runtimecfg

runtimecfg:
	build/runtimecfg node-ip -6 show
