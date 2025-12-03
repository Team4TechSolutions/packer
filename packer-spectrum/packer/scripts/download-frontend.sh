#!/bin/bash
set -e

echo "========================================="
echo "Downloading Spectrum Frontend from S3"
echo "========================================="
echo ""

# Variables
SPECTRUM_S3_BUCKET="${SPECTRUM_S3_BUCKET:-warfilefortestspectrum}"
SPECTRUM_S3_PATH="${SPECTRUM_S3_PATH:-5.9.0}"
TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"
FRONTEND_DIR="$TOMCAT_HOME/webapps/spectrum"
AWS_REGION="${AWS_REGION:-ca-central-1}"

echo "S3 Bucket: $SPECTRUM_S3_BUCKET"
echo "S3 Path: $SPECTRUM_S3_PATH"
echo "Frontend Directory: $FRONTEND_DIR"
echo ""

# Verify AWS access
echo "1. Verifying AWS access..."
echo "----------------------------------------"

# Check for AWS CLI in common locations
AWS_CMD=""
for path in /usr/local/bin/aws /usr/bin/aws /opt/aws/bin/aws; do
    if [ -x "$path" ]; then
        AWS_CMD="$path"
        break
    fi
done

# If not found, try command -v
if [ -z "$AWS_CMD" ]; then
    if command -v aws &> /dev/null; then
        AWS_CMD="aws"
    fi
fi

if [ -z "$AWS_CMD" ]; then
    echo "✗ AWS CLI is not installed or not found in PATH"
    echo "  Checked: /usr/local/bin/aws, /usr/bin/aws, /opt/aws/bin/aws"
    exit 1
fi

echo "✓ AWS CLI found: $AWS_CMD"

# Configure AWS region
$AWS_CMD configure set default.region "$AWS_REGION"

if ! $AWS_CMD sts get-caller-identity &> /dev/null; then
    echo "✗ AWS credentials not available"
    exit 1
fi

IDENTITY=$($AWS_CMD sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "unknown")
echo "✓ AWS access verified (Identity: ${IDENTITY})"
echo ""

# Create frontend directory
echo "2. Creating frontend directory..."
echo "----------------------------------------"
sudo mkdir -p "$FRONTEND_DIR"
sudo chown $TOMCAT_USER:$TOMCAT_GROUP "$FRONTEND_DIR"
echo "✓ Directory created: $FRONTEND_DIR"
echo ""

# Download frontend from S3
echo "3. Downloading frontend files from S3..."
echo "----------------------------------------"
S3_PATH="s3://${SPECTRUM_S3_BUCKET}/${SPECTRUM_S3_PATH}/client/spectrum/"
echo "Source: $S3_PATH"
echo "Destination: $FRONTEND_DIR"
echo ""

if sudo $AWS_CMD s3 sync "$S3_PATH" "$FRONTEND_DIR/" --delete; then
    echo "✓ Frontend files downloaded"
else
    echo "✗ Failed to download frontend files"
    exit 1
fi

# Set ownership
echo ""
echo "4. Setting file ownership..."
echo "----------------------------------------"
sudo chown -R $TOMCAT_USER:$TOMCAT_GROUP "$FRONTEND_DIR"
echo "✓ Ownership set"
echo ""

# Verify files
echo "5. Verifying downloaded files..."
echo "----------------------------------------"
if [ -d "$FRONTEND_DIR" ] && [ "$(ls -A $FRONTEND_DIR 2>/dev/null)" ]; then
    echo "✓ Frontend directory contains files:"
    ls -la "$FRONTEND_DIR" | head -10
    echo ""
    
    if [ -f "$FRONTEND_DIR/index.html" ] || [ -f "$FRONTEND_DIR/index.htm" ]; then
        echo "✓ Found index file"
    fi
    
    if [ -f "$FRONTEND_DIR/appConfig.js" ]; then
        echo "✓ Found appConfig.js"
    else
        echo "⚠ appConfig.js not found (may need to be configured)"
    fi
else
    echo "✗ Frontend directory is empty or doesn't exist"
    exit 1
fi

echo ""
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "1. Restart Tomcat (if needed):"
echo "   sudo systemctl restart tomcat"
echo ""
echo "2. Access the frontend at:"
echo "   http://YOUR-IP:8080/spectrum/"
echo ""
echo "3. If appConfig.js needs configuration, update it:"
echo "   sudo vi $FRONTEND_DIR/appConfig.js"
echo ""
echo "✓ Frontend deployment complete!"
echo ""

