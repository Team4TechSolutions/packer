# Makefile for Windows AMI Builder

.PHONY: help build validate fmt clean

help:
	@echo "Spectrum AMI Builder - Windows"
	@echo ""
	@echo "Available targets:"
	@echo "  build          - Build the Windows AMI"
	@echo "  validate       - Validate Packer configuration"
	@echo "  fmt            - Format Packer configuration"
	@echo "  clean          - Clean build artifacts"

build: validate
	@echo "Building Windows AMI..."
	packer build -var-file=sandbox.hcl windows.pkr.hcl

validate:
	@echo "Validating Packer configuration..."
	packer validate windows.pkr.hcl

fmt:
	@echo "Formatting Packer configuration..."
	packer fmt windows.pkr.hcl

clean:
	@echo "Cleaning build artifacts..."
	rm -f manifest.json
	rm -f *.log

