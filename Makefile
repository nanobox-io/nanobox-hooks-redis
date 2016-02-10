# -*- mode: makefile; tab-width: 8; indent-tabs-mode: 1 -*-
# vim: ts=8 sw=8 ft=make noet

FOLDERS= bin hookit
DEST:= ${DESTDIR}${PREFIX}/hooky/mod

bin:
	mkdir bin

hookit:
	mkdir hookit

default: all

.PHONY: all

all: ${FOLDERS}

.PHONY: install

install: all
	cp -r bin ${DESTDIR}${PREFIX}
	mkdir -p ${DESTDIR}${PREFIX}/hookit
	cp -r hookit ${DESTDIR}${PREFIX}/hookit/mod

.PHONY: test

test:
	# test/run_all.sh 2.6
	test/run_all.sh 2.8
	test/run_all.sh 3.0