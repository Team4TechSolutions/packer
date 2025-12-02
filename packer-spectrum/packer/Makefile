.PHONY: help init validate fmt build clean version

# Default environment file
ENV_FILE ?= sandbox.hcl

# Packer file
PACKER_FILE = ubuntu.pkr.hcl

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

init: ## Initialize Packer plugins
	@echo "Initializing Packer plugins..."
	packer init $(PACKER_FILE)

validate: ## Validate Packer configuration
	@echo "Validating Packer configuration..."
	packer validate -var-file=$(ENV_FILE) $(PACKER_FILE)

fmt: ## Format Packer HCL files
	@echo "Formatting Packer files..."
	packer fmt $(PACKER_FILE)
	packer fmt $(ENV_FILE) 2>/dev/null || true

build: init validate ## Build AMI (requires ENV_FILE variable, e.g., make build ENV_FILE=sandbox.hcl)
	@echo "Building AMI with environment: $(ENV_FILE)"
	@echo "Version: $$(grep '^VERSION=' VERSION | cut -d'=' -f2)"
	packer build -var-file=$(ENV_FILE) $(PACKER_FILE)

clean: ## Clean Packer cache and temporary files
	@echo "Cleaning Packer cache..."
	rm -rf packer_cache/
	rm -f *.log

version: ## Show current version
	@echo "Current version:"
	@cat VERSION

update-version: ## Update version (usage: make update-version VERSION=1.0.1)
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required. Usage: make update-version VERSION=1.0.1"; \
		exit 1; \
	fi
	@sed -i.bak "s/^VERSION=.*/VERSION=$(VERSION)/" VERSION
	@sed -i.bak "s/^BUILD_DATE=.*/BUILD_DATE=$$(date +%Y-%m-%d)/" VERSION
	@rm -f VERSION.bak
	@echo "Version updated to $(VERSION)"

# CI/CD friendly targets
ci-validate: init validate ## CI: Validate configuration
	@echo "CI validation complete"

ci-build: init build ## CI: Build AMI
	@echo "CI build complete"

