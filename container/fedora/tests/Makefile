SHELL := /bin/bash

CONTAINER_STRUCTURE_TEST ?= container-structure-test
PYTEST ?= pytest
IMAGE ?= quay.io/deamen/fedora-init:latest

CONTAINER_TEST_FILES := $(wildcard container-structure-test_*.yml)
PYTEST_FILES := $(wildcard test_*.py)

CONTAINER_TEST_TARGETS := $(patsubst container-structure-test_%.yml,container-structure-test-%,$(CONTAINER_TEST_FILES))
PYTEST_TARGETS := $(patsubst test_%.py,pytest-%,$(PYTEST_FILES))
TEST_TARGETS := $(CONTAINER_TEST_TARGETS) $(PYTEST_TARGETS)

.PHONY: all tests list-tests $(TEST_TARGETS)

all: tests

tests: $(TEST_TARGETS)

list-tests:
	@printf '%s\n' $(TEST_TARGETS)

# Container-structure-test based checks.
container-structure-test-%: container-structure-test_%.yml
	$(CONTAINER_STRUCTURE_TEST) test --image "$(IMAGE)" --config "$<"

# Pytest-based checks.
pytest-%: test_%.py
	$(PYTEST) -q "$<"

# Keep the old name pattern as a convenience alias if desired.
container-structure-test_fedora-init: container-structure-test-fedora-init
