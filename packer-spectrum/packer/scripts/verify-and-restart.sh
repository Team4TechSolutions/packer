#!/bin/bash

echo "========================================="
echo "Verifying Password Update & Restarting Tomcat"
echo "========================================="
echo ""

CONTEXT_XML="/opt/tomcat/conf/context.xml"

echo "1. Checking current password in context.xml..."
echo "----------------------------------------"

# Check if file exists (with sudo)
if sudo test -f "$CONTEXT_XML"; then
    echo "  ✓ Found context.xml at: $CONTEXT_XML"
    
    # Try to read the password
    CURRENT_PASSWORD=$(sudo grep -oP 'password="\K[^"]+' "$CONTEXT_XML" 2>/dev/null | head -1)
    DB_USER=$(sudo grep -oP 'username="\K[^"]+' "$CONTEXT_XML" 2>/dev/null | head -1)
    DB_URL=$(sudo grep -oP 'url="\K[^"]+' "$CONTEXT_XML" 2>/dev/null | head -1)
    
    if [ -z "$CURRENT_PASSWORD" ]; then
        echo "  ✗ Could not read password from context.xml"
        echo "  Showing file contents:"
        sudo cat "$CONTEXT_XML" | grep -A 5 "jdbc/kioskmgr" || sudo cat "$CONTEXT_XML"
        exit 1
    fi
    
    echo "  Username: $DB_USER"
    echo "  Password: $CURRENT_PASSWORD"
    echo "  Connection URL: $DB_URL"
    echo ""
    
    if [ "$CURRENT_PASSWORD" = "welcome12345" ]; then
        echo "  ✓ Password is correctly set to: welcome12345"
    else
        echo "  ⚠ Password is: $CURRENT_PASSWORD"
        echo "  Expected: welcome12345"
    fi
else
    echo "  ✗ context.xml not found at: $CONTEXT_XML"
    echo ""
    echo "  Searching for context.xml files..."
    sudo find /opt/tomcat -name "context.xml" -type f 2>/dev/null | while read file; do
        echo "    Found: $file"
    done
    exit 1
fi

echo ""
echo "2. Checking file ownership..."
echo "----------------------------------------"
OWNER=$(stat -c '%U:%G' "$CONTEXT_XML" 2>/dev/null || stat -f '%Su:%Sg' "$CONTEXT_XML" 2>/dev/null)
echo "  Current owner: $OWNER"
if [ "$OWNER" != "tomcat:tomcat" ]; then
    echo "  Fixing ownership..."
    sudo chown tomcat:tomcat "$CONTEXT_XML"
    echo "  ✓ Ownership fixed"
else
    echo "  ✓ Ownership is correct"
fi

echo ""
echo "3. Stopping Tomcat..."
echo "----------------------------------------"
sudo systemctl stop tomcat
sleep 2
echo "  ✓ Tomcat stopped"

echo ""
echo "4. Starting Tomcat..."
echo "----------------------------------------"
sudo systemctl start tomcat
sleep 3
echo "  ✓ Tomcat started"

echo ""
echo "5. Checking Tomcat status..."
echo "----------------------------------------"
if sudo systemctl is-active --quiet tomcat; then
    echo "  ✓ Tomcat is running"
else
    echo "  ✗ Tomcat is not running!"
    echo "  Check logs: sudo journalctl -u tomcat -n 50"
fi

echo ""
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "Monitor the logs to see if the database connection works:"
echo "  sudo tail -f /opt/tomcat/logs/catalina.out"
echo ""
echo "Look for:"
echo "  ✓ 'Started Application in X seconds' - SUCCESS!"
echo "  ✗ 'Access denied' - Still a connection issue"
echo "  ✗ 'Communications link failure' - Network/security group issue"
echo ""
echo "Test the application:"
echo "  curl http://localhost:8080/spectrum-server/api/health"
echo ""

