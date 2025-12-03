#!/bin/bash
set -e

echo "Configuring Tomcat..."

# Variables
JVM_XMX="${JVM_XMX:-2g}"
JVM_XMS="${JVM_XMS:-1g}"
TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"

# Step 1: Configure JVM (setenv.sh)
echo "Configuring JVM settings..."

sudo tee $TOMCAT_HOME/bin/setenv.sh > /dev/null <<EOF
#!/bin/bash
export JAVA_OPTS="-Xmx${JVM_XMX} -Xms${JVM_XMS} -XX:+UseG1GC -Djava.security.egd=file:/dev/./urandom"
export CATALINA_OPTS="-Dfile.encoding=UTF-8"
EOF

sudo chmod +x $TOMCAT_HOME/bin/setenv.sh
sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/bin/setenv.sh
echo "JVM configuration created"

# Step 2: Copy Tomcat configuration overrides if they exist
if [ -d "/tmp/tomcat-conf" ]; then
    echo "Copying Tomcat configuration overrides..."
    sudo cp -r /tmp/tomcat-conf/* $TOMCAT_HOME/conf/ 2>/dev/null || true
    sudo chown -R $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/conf/
    echo "Tomcat configuration overrides applied"
fi

# Step 3: Update systemd service description
if [ -f "/etc/systemd/system/tomcat.service" ]; then
    echo "Updating systemd service for Spectrum..."
    sudo sed -i 's/Description=Apache Tomcat.*/Description=Apache Tomcat 10 - Spectrum Server/' /etc/systemd/system/tomcat.service
    sudo systemctl daemon-reload
    echo "Systemd service updated"
fi

# Step 4: Configure Firewall
echo "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 8080/tcp || true
    echo "Firewall rule added for port 8080"
fi

echo "Tomcat configuration completed!"

