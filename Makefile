# -*- mode: makefile; tab-width: 8; indent-tabs-mode: 1 -*-
# vim: ts=8 sw=8 ft=make noet

default: all

.PHONY: all

all: stable

.PHONY: test

test:
	stdbuf -oL test/run_all.sh 2.8
	stdbuf -oL test/run_all.sh 3.0

.PHONY: stable beta alpha

stable:
	@./util/publish.sh stable

beta:
	@./util/publish.sh beta

alpha:
	@./util/publish.sh alpha