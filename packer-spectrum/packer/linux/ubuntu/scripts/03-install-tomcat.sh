#!/bin/bash
set -e

echo "Installing Apache Tomcat..."

# Variables
TOMCAT_VERSION="${TOMCAT_VERSION:-10.1.20}"
TOMCAT_MAJOR_VERSION="10"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"
TOMCAT_HOME="/opt/tomcat"
TOMCAT_DOWNLOAD_URL="https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

# Create tomcat user and group
sudo groupadd -r ${TOMCAT_GROUP} || true
sudo useradd -r -g ${TOMCAT_GROUP} -d ${TOMCAT_HOME} -s /bin/false ${TOMCAT_USER} || true

# Create Tomcat directory
sudo mkdir -p ${TOMCAT_HOME}

# Download and extract Tomcat
cd /tmp
wget -q ${TOMCAT_DOWNLOAD_URL} -O apache-tomcat-${TOMCAT_VERSION}.tar.gz
sudo tar xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C ${TOMCAT_HOME} --strip-components=1

# Verify extraction
if [ ! -d "${TOMCAT_HOME}/bin" ]; then
    echo "Error: Tomcat extraction failed"
    exit 1
fi

# Set ownership
sudo chown -R ${TOMCAT_USER}:${TOMCAT_GROUP} ${TOMCAT_HOME}

# Make scripts executable
if [ -d "${TOMCAT_HOME}/bin" ]; then
    sudo chmod +x ${TOMCAT_HOME}/bin/*.sh 2>/dev/null || true
fi

# Set CATALINA_HOME
echo "export CATALINA_HOME=${TOMCAT_HOME}" | sudo tee /etc/profile.d/tomcat.sh > /dev/null
source /etc/profile.d/tomcat.sh

# Clean up
rm -f /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz

echo "Tomcat ${TOMCAT_VERSION} installed successfully at ${TOMCAT_HOME}"

# Create systemd service file directly in install script to ensure it persists
cat << 'EOF' | sudo tee /etc/systemd/system/tomcat.service > /dev/null
[Unit]
Description=Apache Tomcat 10 - Spectrum Server
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=on-failure

LimitNOFILE=65536
LimitNPROC=32768

[Install]
WantedBy=multi-user.target
EOF

# Create temp directory for PID file
sudo mkdir -p /opt/tomcat/temp
sudo chown tomcat:tomcat /opt/tomcat/temp

# Reload systemd and enable service (but don't start yet - will start after configuration)
sudo systemctl daemon-reload
sudo systemctl enable tomcat

# Verify service file exists
if [ -f /etc/systemd/system/tomcat.service ]; then
    echo "✓ Tomcat systemd service file created successfully at /etc/systemd/system/tomcat.service"
    echo "✓ Service enabled for auto-start on boot"
else
    echo "✗ ERROR: Tomcat service file was not created!"
    exit 1
fi

