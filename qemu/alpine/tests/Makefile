.ONESHELL:   # Enable single-shell mode for all recipes in this Makefile
# Makefile for image_builder/qemu/alpine/tests
TERRAFORM := /usr/bin/terraform
GEN_SCRIPT  := ./files/generate_provisioner_tfvars.sh
.PHONY: all tests destroy

all: tests destroy

tests:
	$(GEN_SCRIPT)
	$(TERRAFORM) apply -auto-approve

destroy:
	$(TERRAFORM) destroy -auto-approve
