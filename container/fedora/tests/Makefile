SHELL := /bin/bash

CONTAINER_STRUCTURE_TEST ?= container-structure-test
PYTEST ?= pytest
IMAGE ?= quay.io/deamen/fedora-init-amd64:latest

CONTAINER_TEST_FILES := $(wildcard container-structure-test_*.yml)
PYTEST_FILES := $(wildcard test_*.py)

CONTAINER_TEST_TARGETS := $(patsubst container-structure-test_%.yml,container-structure-test-%,$(CONTAINER_TEST_FILES))
PYTEST_TARGETS := $(patsubst test_%.py,pytest-%,$(PYTEST_FILES))
TEST_TARGETS := $(CONTAINER_TEST_TARGETS) $(PYTEST_TARGETS)

##
# Individual test targets (container-structure-test-*, pytest-*) are deliberately NOT
# listed here. Declaring their exact expanded names as .PHONY prerequisites creates an
# empty explicit rule for each one, which takes precedence over the pattern rules below
# and makes `make` print "Nothing to be done" instead of running the recipe.
##
.PHONY: all tests list-tests

all: tests

tests: $(TEST_TARGETS)

list-tests:
	@printf '%s\n' $(TEST_TARGETS)

# Container-structure-test based checks.
container-structure-test-%: container-structure-test_%.yml
	$(CONTAINER_STRUCTURE_TEST) test --image "$(IMAGE)" --config "$<"

# Pytest-based checks.
pytest-%: test_%.py
	IMAGE="$(IMAGE)" $(PYTEST) -q "$<"
