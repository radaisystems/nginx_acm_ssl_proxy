ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

build_or_publish:
	./build_or_publish.sh $(WORKSPACE)
