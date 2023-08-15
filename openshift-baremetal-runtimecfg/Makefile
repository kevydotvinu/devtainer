.PHONY: help

help:
	@echo "AVAILABLE TARGETS"
	@awk '/^.PHONY:/ {print $$2}' ${HOME}/Makefile

.PHONY: ecmp6

ecmp6:
	sudo ip -6 r a default nexthop via fe80::2 dev eth0 nexthop via fe80:2::2 dev eth0 dev eth0
	ip -6 r

.PHONY: build

build:
	GO111MODULE=on go build --mod=vendor -o build ./cmd/...                                                  
