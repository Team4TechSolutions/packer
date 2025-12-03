#!/bin/bash

echo "========================================="
echo "Checking Database Credentials in AMI"
echo "========================================="
echo ""

# Try to find context.xml in common locations
CONTEXT_XML=""
for location in \
    "/opt/tomcat/conf/context.xml" \
    "/usr/share/tomcat*/conf/context.xml" \
    "/var/lib/tomcat*/conf/context.xml" \
    "$(find /opt -name context.xml -type f 2>/dev/null | head -1)" \
    "$(find /usr -name context.xml -path '*/tomcat*/conf/*' -type f 2>/dev/null | head -1)"; do
    
    if [ -n "$location" ] && [ -f "$location" ]; then
        CONTEXT_XML="$location"
        break
    fi
done

if [ -z "$CONTEXT_XML" ] || [ ! -f "$CONTEXT_XML" ]; then
    echo "Error: context.xml not found!"
    echo ""
    echo "Searched locations:"
    echo "  - /opt/tomcat/conf/context.xml"
    echo "  - /usr/share/tomcat*/conf/context.xml"
    echo "  - /var/lib/tomcat*/conf/context.xml"
    echo ""
    echo "Checking if Tomcat is installed..."
    if command -v systemctl &> /dev/null; then
        if systemctl list-units --all | grep -q tomcat; then
            echo "  ✓ Tomcat service exists"
        else
            echo "  ✗ Tomcat service not found"
        fi
    fi
    
    if [ -d "/opt/tomcat" ]; then
        echo "  ✓ /opt/tomcat directory exists"
        echo "    Contents: $(ls -la /opt/tomcat 2>/dev/null | head -5)"
    else
        echo "  ✗ /opt/tomcat directory not found"
    fi
    
    echo ""
    echo "Database credentials configured in sandbox.hcl (used during AMI build):"
    echo "  Username: admin"
    echo "  Password: welcome1"
    echo "  Database: kioskmgr"
    echo "  Host: database-1.cdq6ga82mq0v.ca-central-1.rds.amazonaws.com"
    echo ""
    echo "These credentials should be in the AMI's context.xml file once Tomcat is configured."
    exit 1
fi

echo "Found context.xml at: $CONTEXT_XML"
echo ""

echo "1. Database Configuration in context.xml:"
echo "----------------------------------------"

DB_URL=$(grep -oP 'url="\K[^"]+' "$CONTEXT_XML" | head -1)
DB_USER=$(grep -oP 'username="\K[^"]+' "$CONTEXT_XML" | head -1)
DB_PASSWORD=$(grep -oP 'password="\K[^"]+' "$CONTEXT_XML" | head -1)

echo "  Username: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo "  Connection URL: $DB_URL"
echo ""

# Parse MySQL connection
if [[ $DB_URL =~ jdbc:mysql://([^:]+):([0-9]+)/([^?]+) ]]; then
    DB_HOST="${BASH_REMATCH[1]}"
    DB_PORT="${BASH_REMATCH[2]}"
    DB_NAME="${BASH_REMATCH[3]}"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
fi

echo ""
echo "2. Expected from sandbox.hcl (used during AMI build):"
echo "----------------------------------------"
echo "  Username: admin"
echo "  Password: welcome1"
echo "  Database: kioskmgr"
echo "  Host: database-1.cdq6ga82mq0v.ca-central-1.rds.amazonaws.com"
echo ""

if [ "$DB_PASSWORD" = "welcome1" ]; then
    echo "✓ Password matches expected value from AMI build"
else
    echo "⚠ Password differs from expected 'welcome1'"
    echo "  Current password in context.xml: '$DB_PASSWORD'"
fi

echo ""
echo "3. Next Steps:"
echo "----------------------------------------"
echo "Verify that the RDS MySQL user 'admin' has:"
echo "  - Password set to: welcome1"
echo "  - Permission to connect from your EC2 instance IP"
echo ""
echo "To check RDS password, connect to RDS and run:"
echo "  SELECT user, host FROM mysql.user WHERE user='admin';"
echo ""

