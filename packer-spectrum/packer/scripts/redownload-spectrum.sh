#!/bin/bash

echo "========================================="
echo "Re-downloading Spectrum from S3"
echo "========================================="
echo ""

TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"

# Configuration (should match sandbox.hcl)
S3_BUCKET="warfilefortestspectrum"
S3_PATH="5.9.0"
REGION="ca-central-1"

# Set region
export AWS_DEFAULT_REGION="$REGION"
export AWS_REGION="$REGION"

# Verify AWS access
echo "1. Verifying AWS access..."
echo "----------------------------------------"

# Check if instance metadata service is available
echo "  Checking instance metadata service..."
if curl -s --max-time 2 http://169.254.169.254/latest/meta-data/ &> /dev/null; then
    echo "  ✓ Instance metadata service is accessible"
    
    # Get the IAM role name
    IAM_ROLE=$(curl -s --max-time 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null | head -1)
    if [ -n "$IAM_ROLE" ]; then
        echo "  ✓ IAM role attached: $IAM_ROLE"
    else
        echo "  ⚠ No IAM role found in metadata"
    fi
else
    echo "  ⚠ Cannot access instance metadata service"
fi
echo ""

# Try to get AWS credentials
echo "  Attempting to get AWS credentials..."
# Unset any existing AWS credentials to force use of instance profile
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

# Configure AWS CLI to use instance profile
export AWS_METADATA_SERVICE_TIMEOUT=5
export AWS_METADATA_SERVICE_NUM_ATTEMPTS=3

# Configure AWS CLI region if not set
if ! aws configure get region &> /dev/null; then
    echo "  Setting AWS region to $REGION..."
    aws configure set default.region $REGION
fi

# Test AWS access
if aws sts get-caller-identity &> /dev/null; then
    IDENTITY=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)
    echo "  ✓ AWS access verified (Identity: ${IDENTITY})"
else
    echo "  ✗ AWS credentials not available"
    echo ""
    echo "  Troubleshooting:"
    echo "    1. Checking instance metadata..."
    METADATA=$(curl -s --max-time 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null)
    if [ -n "$METADATA" ]; then
        echo "    ✓ IAM role found: $METADATA"
        echo "    Try running: aws configure set default.region $REGION"
        echo "    Then: aws sts get-caller-identity"
    else
        echo "    ✗ No IAM role found in metadata"
        echo "    Verify IAM role is attached to EC2 instance"
    fi
    echo ""
    echo "  Manual verification:"
    echo "    curl http://169.254.169.254/latest/meta-data/iam/security-credentials/"
    echo "    aws configure set default.region $REGION"
    echo "    aws sts get-caller-identity"
    exit 1
fi
echo ""

# Stop Tomcat to prevent conflicts
echo "2. Stopping Tomcat..."
echo "----------------------------------------"
sudo systemctl stop tomcat
sleep 3
echo "✓ Tomcat stopped"
echo ""

# Clean up old deployment
echo "3. Cleaning up old deployment..."
echo "----------------------------------------"
sudo rm -rf $TOMCAT_HOME/webapps/spectrum-server
sudo rm -f $TOMCAT_HOME/webapps/spectrum-server.war
echo "✓ Old deployment removed"
echo ""

# Download backend WAR
echo "4. Downloading backend WAR from S3..."
echo "----------------------------------------"
cd /tmp
if aws s3 cp s3://${S3_BUCKET}/${S3_PATH}/server/spectrum-server.war ./spectrum-server.war; then
    echo "✓ Backend WAR downloaded"
    ls -lh ./spectrum-server.war
else
    echo "✗ Failed to download backend WAR"
    exit 1
fi
echo ""

# Move WAR to webapps
echo "5. Installing backend WAR..."
echo "----------------------------------------"
sudo mv ./spectrum-server.war $TOMCAT_HOME/webapps/
sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum-server.war
echo "✓ WAR file installed"
echo ""

# Check if frontend exists, if not download it
echo "6. Checking frontend..."
echo "----------------------------------------"
if [ ! -d "$TOMCAT_HOME/webapps/spectrum" ]; then
    echo "  Frontend not found, downloading..."
    cd /tmp
    if aws s3 sync s3://${S3_BUCKET}/${S3_PATH}/client/spectrum/ $TOMCAT_HOME/webapps/spectrum/ --delete; then
        sudo chown -R $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum
        echo "✓ Frontend downloaded"
    else
        echo "✗ Failed to download frontend"
    fi
else
    echo "✓ Frontend already exists"
fi
echo ""

# Start Tomcat
echo "7. Starting Tomcat..."
echo "----------------------------------------"
sudo systemctl start tomcat
echo "✓ Tomcat started"
echo ""

# Wait for deployment
echo "8. Waiting for deployment (30 seconds)..."
echo "----------------------------------------"
sleep 30
echo ""

# Check deployment status
echo "9. Checking deployment status..."
echo "----------------------------------------"
if [ -d "$TOMCAT_HOME/webapps/spectrum-server" ]; then
    echo "✓ Backend directory exists - deployment in progress"
    echo ""
    echo "  Checking Spring Boot startup..."
    sleep 10
    if sudo grep -q "Started.*Application" /opt/tomcat/logs/catalina.out 2>/dev/null; then
        echo "✓ Spring Boot application started!"
        sudo grep "Started.*Application" /opt/tomcat/logs/catalina.out | tail -1
    else
        echo "⚠ Spring Boot may still be starting"
        echo "  Monitor logs: sudo tail -f /opt/tomcat/logs/catalina.out"
    fi
else
    echo "✗ Backend directory not found yet"
    echo "  Check logs: sudo tail -50 /opt/tomcat/logs/catalina.out"
fi
echo ""

echo "========================================="
echo "Summary"
echo "========================================="
echo "WAR file: $TOMCAT_HOME/webapps/spectrum-server.war"
echo "Backend:  $TOMCAT_HOME/webapps/spectrum-server/"
echo "Frontend: $TOMCAT_HOME/webapps/spectrum/"
echo ""
echo "Monitor deployment:"
echo "  sudo tail -f /opt/tomcat/logs/catalina.out"
echo ""
echo "Test endpoints:"
echo "  curl http://localhost:8080/spectrum/"
echo "  curl http://localhost:8080/spectrum-server/"
echo ""

