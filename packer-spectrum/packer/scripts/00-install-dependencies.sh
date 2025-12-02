#!/bin/bash
set -e

echo "Installing system dependencies..."

# Update package index
sudo apt-get update

# Install essential tools
sudo apt-get install -y \
    wget \
    curl \
    unzip \
    tar \
    gzip \
    ca-certificates \
    gnupg \
    lsb-release

echo "Dependencies installed successfully!"

