#!/bin/bash
set -e

echo "Installing Java 17..."

# Update package index
sudo apt-get update

# Install OpenJDK 17
sudo apt-get install -y openjdk-17-jdk

# Verify installation
java -version

# Set JAVA_HOME
JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
sudo tee /etc/profile.d/java.sh > /dev/null <<EOF
export JAVA_HOME=${JAVA_HOME}
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

source /etc/profile.d/java.sh

echo "Java 17 installed successfully!"
echo "JAVA_HOME: $JAVA_HOME"

