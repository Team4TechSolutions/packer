#!/bin/bash
set -e

echo "Deploying Spectrum applications..."

# Variables
SPECTRUM_VERSION="${SPECTRUM_VERSION:-5.x.x}"
SPECTRUM_PACKAGE_URL="${SPECTRUM_PACKAGE_URL:-}"
SPECTRUM_PACKAGE_PATH="${SPECTRUM_PACKAGE_PATH:-}"
TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"

# Check if Spectrum package is provided
if [ -z "$SPECTRUM_PACKAGE_URL" ] && [ -z "$SPECTRUM_PACKAGE_PATH" ]; then
    echo "Warning: No Spectrum package provided (SPECTRUM_PACKAGE_URL or SPECTRUM_PACKAGE_PATH)"
    echo "Skipping Spectrum application deployment."
    exit 0
fi

# Determine package source
if [ -n "$SPECTRUM_PACKAGE_PATH" ] && [ -f "$SPECTRUM_PACKAGE_PATH" ]; then
    echo "Using local Spectrum package: $SPECTRUM_PACKAGE_PATH"
    PACKAGE_FILE="$SPECTRUM_PACKAGE_PATH"
elif [ -n "$SPECTRUM_PACKAGE_URL" ]; then
    echo "Downloading Spectrum package from: $SPECTRUM_PACKAGE_URL"
    cd /tmp
    wget -q "$SPECTRUM_PACKAGE_URL" -O SpectrumV${SPECTRUM_VERSION}.zip
    PACKAGE_FILE="/tmp/SpectrumV${SPECTRUM_VERSION}.zip"
else
    echo "Error: Spectrum package not found"
    exit 1
fi

# Extract and deploy
cd /tmp
unzip -q -o "$PACKAGE_FILE" -d spectrum-package || true

# Deploy Backend WAR
WAR_FILE=$(find spectrum-package -name "spectrum-server.war" -type f | head -n 1)
if [ -n "$WAR_FILE" ] && [ -f "$WAR_FILE" ]; then
    sudo cp "$WAR_FILE" $TOMCAT_HOME/webapps/
    sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum-server.war
    echo "Backend WAR deployed: spectrum-server.war"
else
    echo "Warning: spectrum-server.war not found in package"
fi

# Deploy Frontend
FRONTEND_DIR=$(find spectrum-package -type d -name "spectrum" -not -path "*/.*" | head -n 1)
if [ -n "$FRONTEND_DIR" ] && [ -d "$FRONTEND_DIR" ]; then
    sudo cp -r "$FRONTEND_DIR" $TOMCAT_HOME/webapps/
    sudo chown -R $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum
    echo "Frontend deployed: spectrum/"
else
    echo "Warning: Frontend directory not found in package"
fi

# Cleanup
rm -rf spectrum-package
if [ -f "/tmp/SpectrumV${SPECTRUM_VERSION}.zip" ]; then
    rm -f /tmp/SpectrumV${SPECTRUM_VERSION}.zip
fi

echo "Spectrum applications deployed successfully!"

