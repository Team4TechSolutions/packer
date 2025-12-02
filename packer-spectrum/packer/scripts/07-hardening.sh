#!/bin/bash
set -e

echo "Applying security hardening..."

# Set up security limits
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
# Spectrum Tomcat limits
tomcat soft nofile 65536
tomcat hard nofile 65536
tomcat soft nproc 32768
tomcat hard nproc 32768
EOF

# Configure systemd service limits
if [ -f "/etc/systemd/system/tomcat.service" ]; then
    if ! grep -q "LimitNOFILE" /etc/systemd/system/tomcat.service; then
        sudo sed -i '/\[Service\]/a\
LimitNOFILE=65536\
LimitNPROC=32768' /etc/systemd/system/tomcat.service
        sudo systemctl daemon-reload
        echo "Systemd limits configured"
    fi
fi

# Remove unnecessary packages
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "Security hardening completed!"

