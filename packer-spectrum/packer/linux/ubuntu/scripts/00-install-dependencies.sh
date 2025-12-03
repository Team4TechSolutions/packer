#!/bin/bash
set -e

echo "Installing system dependencies..."

# Clean up any GPG issues and update package index with retries
echo "Cleaning apt cache and fixing GPG issues..."
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean

# Retry apt-get update up to 3 times
for i in {1..3}; do
    echo "Attempting to update package index (attempt $i/3)..."
    if sudo apt-get update; then
        echo "✓ Package index updated successfully"
        break
    else
        if [ $i -lt 3 ]; then
            echo "Retrying in 5 seconds..."
            sleep 5
            sudo rm -rf /var/lib/apt/lists/*
        else
            echo "Failed to update package index after 3 attempts"
            exit 1
        fi
    fi
done

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

# Install AWS CLI v2 (not available as apt package in Ubuntu 22.04)
echo "Installing AWS CLI v2..."
cd /tmp
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    echo "✓ AWS CLI v2 installed"
else
    echo "✓ AWS CLI already installed"
fi

# Verify AWS CLI installation
aws --version

echo "Dependencies installed successfully!"

