#!/bin/bash
set -e

# Apply setenv.sh template
sudo sed -e "s|{{JVM_XMX}}|${JVM_XMX}|g" -e "s|{{JVM_XMS}}|${JVM_XMS}|g" /tmp/setenv.sh.tpl | sudo tee /opt/tomcat/bin/setenv.sh > /dev/null
sudo chmod +x /opt/tomcat/bin/setenv.sh
sudo chown tomcat:tomcat /opt/tomcat/bin/setenv.sh

echo "setenv.sh template applied successfully"

