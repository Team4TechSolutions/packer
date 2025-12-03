#!/bin/bash
set -e

echo "Deploying Spectrum applications..."

# Variables
SPECTRUM_VERSION="${SPECTRUM_VERSION:-5.x.x}"
SPECTRUM_PACKAGE_URL="${SPECTRUM_PACKAGE_URL:-}"
SPECTRUM_PACKAGE_PATH="${SPECTRUM_PACKAGE_PATH:-}"
SPECTRUM_S3_BUCKET="${SPECTRUM_S3_BUCKET:-}"
SPECTRUM_S3_PATH="${SPECTRUM_S3_PATH:-}"
TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"

# Check if Spectrum package is provided
if [ -z "$SPECTRUM_PACKAGE_URL" ] && [ -z "$SPECTRUM_PACKAGE_PATH" ] && [ -z "$SPECTRUM_S3_BUCKET" ]; then
    echo "Warning: No Spectrum package provided (SPECTRUM_PACKAGE_URL, SPECTRUM_PACKAGE_PATH, or SPECTRUM_S3_BUCKET)"
    echo "Skipping Spectrum application deployment."
    exit 0
fi

# Function to deploy from S3
deploy_from_s3() {
    local S3_BUCKET="$1"
    local S3_PATH="${2:-5.9.0}"  # Default to 5.9.0 if not specified
    
    echo "Downloading Spectrum from S3: s3://${S3_BUCKET}/${S3_PATH}/"
    
    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed. Cannot download from S3."
        exit 1
    fi
    
    # Set region if provided
    if [ -n "$AWS_REGION" ]; then
        export AWS_DEFAULT_REGION="$AWS_REGION"
        export AWS_REGION="$AWS_REGION"
    fi
    
    # AWS credentials come from the IAM instance profile attached to the EC2 instance
    # The AWS CLI will automatically use credentials from the instance metadata service
    # No need to set AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY
    
    echo "Verifying AWS access via instance metadata service..."
    
    # Test credentials (will use instance profile automatically)
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: Unable to access AWS. Check that:"
        echo "  1. IAM instance profile is attached to the build instance"
        echo "  2. Instance profile has permissions to access S3 bucket: ${S3_BUCKET}"
        echo "  3. Instance metadata service is enabled (IMDSv2)"
        exit 1
    fi
    
    # Show which identity is being used
    IDENTITY=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "unknown")
    echo "✓ AWS access verified via instance profile (Identity: ${IDENTITY})"
    
    cd /tmp
    
    # Download Backend WAR
    echo "Downloading backend WAR file..."
    aws s3 cp "s3://${S3_BUCKET}/${S3_PATH}/server/spectrum-server.war" /tmp/spectrum-server.war
    if [ -f "/tmp/spectrum-server.war" ]; then
        sudo cp /tmp/spectrum-server.war $TOMCAT_HOME/webapps/
        sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum-server.war
        echo "✓ Backend WAR deployed: spectrum-server.war"
        rm -f /tmp/spectrum-server.war
    else
        echo "✗ Error: Failed to download spectrum-server.war from S3"
        exit 1
    fi
    
    # Download Frontend directory
    echo "Downloading frontend directory..."
    aws s3 sync "s3://${S3_BUCKET}/${S3_PATH}/client/spectrum" /tmp/spectrum-frontend --delete
    if [ -d "/tmp/spectrum-frontend" ]; then
        sudo cp -r /tmp/spectrum-frontend $TOMCAT_HOME/webapps/spectrum
        sudo chown -R $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum
        echo "✓ Frontend deployed: spectrum/"
        rm -rf /tmp/spectrum-frontend
    else
        echo "✗ Error: Failed to download frontend from S3"
        exit 1
    fi
}

# Function to deploy from ZIP file
deploy_from_zip() {
    local PACKAGE_FILE="$1"
    
    echo "Extracting and deploying from ZIP package..."
    cd /tmp
    unzip -q -o "$PACKAGE_FILE" -d spectrum-package || true
    
    # Deploy Backend WAR
    WAR_FILE=$(find spectrum-package -name "spectrum-server.war" -type f | head -n 1)
    if [ -n "$WAR_FILE" ] && [ -f "$WAR_FILE" ]; then
        sudo cp "$WAR_FILE" $TOMCAT_HOME/webapps/
        sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum-server.war
        echo "✓ Backend WAR deployed: spectrum-server.war"
    else
        echo "✗ Warning: spectrum-server.war not found in package"
    fi
    
    # Deploy Frontend
    FRONTEND_DIR=$(find spectrum-package -type d -name "spectrum" -not -path "*/.*" | head -n 1)
    if [ -n "$FRONTEND_DIR" ] && [ -d "$FRONTEND_DIR" ]; then
        sudo cp -r "$FRONTEND_DIR" $TOMCAT_HOME/webapps/
        sudo chown -R $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum
        echo "✓ Frontend deployed: spectrum/"
    else
        echo "✗ Warning: Frontend directory not found in package"
    fi
    
    # Cleanup
    rm -rf spectrum-package
    if [ -f "/tmp/SpectrumV${SPECTRUM_VERSION}.zip" ]; then
        rm -f /tmp/SpectrumV${SPECTRUM_VERSION}.zip
    fi
}

# Determine deployment method and deploy
if [ -n "$SPECTRUM_S3_BUCKET" ]; then
    # Deploy from S3 bucket
    deploy_from_s3 "$SPECTRUM_S3_BUCKET" "$SPECTRUM_S3_PATH"
elif [ -n "$SPECTRUM_PACKAGE_PATH" ] && [ -f "$SPECTRUM_PACKAGE_PATH" ]; then
    # Deploy from local ZIP file
    echo "Using local Spectrum package: $SPECTRUM_PACKAGE_PATH"
    deploy_from_zip "$SPECTRUM_PACKAGE_PATH"
elif [ -n "$SPECTRUM_PACKAGE_URL" ]; then
    # Check if URL is S3 path
    if [[ "$SPECTRUM_PACKAGE_URL" == s3://* ]]; then
        # Extract bucket and path from S3 URL
        S3_URL="${SPECTRUM_PACKAGE_URL#s3://}"
        S3_BUCKET="${S3_URL%%/*}"
        S3_PATH="${S3_URL#*/}"
        # Remove trailing filename if present, keep directory path
        S3_PATH="${S3_PATH%/*}"
        deploy_from_s3 "$S3_BUCKET" "$S3_PATH"
    else
        # Download ZIP from HTTP/HTTPS URL
        echo "Downloading Spectrum package from: $SPECTRUM_PACKAGE_URL"
        cd /tmp
        wget -q "$SPECTRUM_PACKAGE_URL" -O SpectrumV${SPECTRUM_VERSION}.zip
        deploy_from_zip "/tmp/SpectrumV${SPECTRUM_VERSION}.zip"
    fi
else
    echo "Error: Spectrum package not found"
    exit 1
fi

echo "Spectrum applications deployed successfully!"

