.ONESHELL:   # Enable single-shell mode for all recipes in this Makefile
# Makefile for image_builder/qemu/alpine/tests
TERRAFORM := /usr/bin/terraform
GEN_SCRIPT  := ./files/generate_provisioner_tfvars.sh
.PHONY: all tests destroy ssh_config

all: tests destroy

tests: ssh_config generate_provisioner_tfvars provion_test_vms run_testinfra_tests

ssh_config:
	echo -e "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null" > ssh_config

generate_provisioner_tfvars:
	$(GEN_SCRIPT)

provion_test_vms:
	$(TERRAFORM) apply -auto-approve

run_testinfra_tests:
	./.testinfra_py_venv/bin/python3 ./run_alpine_vm_image_tests.py

destroy:
	$(TERRAFORM) destroy -auto-approve
