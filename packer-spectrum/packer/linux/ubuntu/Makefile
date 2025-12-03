# Makefile for Linux AMI Builder

.PHONY: help build validate fmt clean

help:
	@echo "Spectrum AMI Builder - Linux"
	@echo ""
	@echo "Available targets:"
	@echo "  build          - Build the Linux AMI"
	@echo "  validate       - Validate Packer configuration"
	@echo "  fmt            - Format Packer configuration"
	@echo "  clean          - Clean build artifacts"

build: validate
	@echo "Building Linux AMI..."
	packer build -var-file=sandbox.hcl linux.pkr.hcl

validate:
	@echo "Validating Packer configuration..."
	packer validate -var-file=sandbox.hcl linux.pkr.hcl

fmt:
	@echo "Formatting Packer configuration..."
	packer fmt linux.pkr.hcl

clean:
	@echo "Cleaning build artifacts..."
	rm -f manifest.json
	rm -f *.log

