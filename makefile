PROJECT_DIR=${shell cd .; pwd}
PROJECT_NAME=${shell basename ${PROJECT_DIR}}
DOCKER_RUN=docker run --rm -it \
				--mount type=bind,src=${PROJECT_DIR},target=/${PROJECT_NAME} \
				--workdir=/${PROJECT_NAME} ${PROJECT_NAME}

.PHONY: all
all:	build-docker \
		test

.PHONY: help
help:
	@echo "Targets:"
	@sed -nr 's/^.PHONY:(.*)/\1/p' ${MAKEFILE_LIST}		

.PHONY: build-docker
build-docker:
	@docker build --tag ${PROJECT_NAME} ${PROJECT_DIR}

.PHONY: clean
clean:
	@${DOCKER_RUN} swift package clean

.PHONY: shell
shell:
	@${DOCKER_RUN} bash

.PHONY: test
test:	test-swift \
		test-turnt

.PHONY: test-swift
test-swift:
	@${DOCKER_RUN} swift test

.PHONY: test-turnt
test-turnt:
	@${DOCKER_RUN} bash ./run_turnt_tests.sh

.PHONY: driver
driver:
	@${DOCKER_RUN} swift run driver

.PHONY: format
format:
	@swift-format -i --recursive ./Sources ./Tests Package.swift
