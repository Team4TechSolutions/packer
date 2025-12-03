# AWS Parameter Store Setup Guide

This guide explains how to set up AWS Systems Manager Parameter Store parameters for storing sensitive database credentials securely.

## Overview

Instead of storing database credentials directly in the `sandbox.hcl` files (which would be committed to git), we use AWS Parameter Store to securely store:
- Database host
- Database username
- Database password

## Prerequisites

- AWS CLI configured with appropriate permissions
- IAM permissions to create/read SSM parameters

## Required IAM Permissions

The Packer build process needs the following permissions:
- `ssm:GetParameter` - to read parameter values
- `ssm:GetParameters` - to read multiple parameters at once

## Creating Parameters

### Using AWS CLI

```bash
# Set AWS region
export AWS_REGION=ca-central-1

# Create database host parameter (String type)
aws ssm put-parameter \
  --name "/spectrum/sandbox/db-host" \
  --value "database-1.cdq6ga82mq0v.ca-central-1.rds.amazonaws.com" \
  --type "String" \
  --description "Spectrum database hostname for sandbox environment"

# Create database user parameter (String type)
aws ssm put-parameter \
  --name "/spectrum/sandbox/db-user" \
  --value "admin" \
  --type "String" \
  --description "Spectrum database username for sandbox environment"

# Create database password parameter (SecureString type - encrypted)
aws ssm put-parameter \
  --name "/spectrum/sandbox/db-password" \
  --value "welcome12345" \
  --type "SecureString" \
  --description "Spectrum database password for sandbox environment" \
  --key-id "alias/aws/ssm"  # Uses AWS managed key
```

### Using AWS Console

1. Navigate to **Systems Manager** → **Parameter Store**
2. Click **Create parameter**
3. For each parameter:
   - **Name**: `/spectrum/sandbox/db-host`, `/spectrum/sandbox/db-user`, `/spectrum/sandbox/db-password`
   - **Type**: 
     - `String` for host and user
     - `SecureString` for password (recommended)
   - **Value**: Enter the actual value
   - **Description**: Optional description
   - Click **Create parameter**

## Verifying Parameters

```bash
# List all Spectrum parameters
aws ssm describe-parameters \
  --parameter-filters "Key=Name,Values=/spectrum/sandbox/" \
  --region ca-central-1

# Get a specific parameter value (non-sensitive)
aws ssm get-parameter \
  --name "/spectrum/sandbox/db-host" \
  --region ca-central-1 \
  --query 'Parameter.Value' \
  --output text

# Get a SecureString parameter (requires decryption)
aws ssm get-parameter \
  --name "/spectrum/sandbox/db-password" \
  --with-decryption \
  --region ca-central-1 \
  --query 'Parameter.Value' \
  --output text
```

## Updating Parameters

```bash
# Update an existing parameter
aws ssm put-parameter \
  --name "/spectrum/sandbox/db-password" \
  --value "new-password" \
  --type "SecureString" \
  --overwrite
```

## Configuration in Packer

The `sandbox.hcl` files are configured to use Parameter Store:

```hcl
# Database credentials from AWS Parameter Store
ssm_db_host_path = "/spectrum/sandbox/db-host"
ssm_db_user_path = "/spectrum/sandbox/db-user"
ssm_db_password_path = "/spectrum/sandbox/db-password"
```

Packer will automatically retrieve these values during the build process.

## Fallback to Direct Values

If Parameter Store paths are not provided, Packer will fall back to direct variable values (if set). However, this is **NOT RECOMMENDED** for production as these values will be committed to git.

## Security Best Practices

1. **Always use SecureString** for passwords and other sensitive data
2. **Use KMS encryption** for SecureString parameters (default uses AWS managed key)
3. **Limit IAM permissions** - only grant `ssm:GetParameter` for specific parameter paths
4. **Use parameter hierarchies** - organize parameters by environment (e.g., `/spectrum/sandbox/`, `/spectrum/production/`)
5. **Enable parameter versioning** - allows tracking changes and rollback
6. **Use parameter policies** - set expiration dates for temporary credentials

## Troubleshooting

### Error: "Parameter not found"
- Verify the parameter name matches exactly (case-sensitive)
- Check that the parameter exists in the correct AWS region
- Ensure your AWS credentials have permissions to read the parameter

### Error: "Access denied"
- Verify IAM permissions include `ssm:GetParameter` and `ssm:GetParameters`
- For SecureString parameters, ensure KMS decrypt permissions are granted

### Error: "Invalid parameter type"
- Ensure password parameters use `SecureString` type
- Host and user can use `String` type

## Example: Creating Parameters for Multiple Environments

```bash
# Sandbox environment
aws ssm put-parameter --name "/spectrum/sandbox/db-host" --value "sandbox-db.example.com" --type "String"
aws ssm put-parameter --name "/spectrum/sandbox/db-user" --value "admin" --type "String"
aws ssm put-parameter --name "/spectrum/sandbox/db-password" --value "sandbox-password" --type "SecureString"

# Production environment
aws ssm put-parameter --name "/spectrum/production/db-host" --value "prod-db.example.com" --type "String"
aws ssm put-parameter --name "/spectrum/production/db-user" --value "admin" --type "String"
aws ssm put-parameter --name "/spectrum/production/db-password" --value "prod-password" --type "SecureString"
```

Then update the respective `sandbox.hcl` or `production.hcl` files with the appropriate paths.

