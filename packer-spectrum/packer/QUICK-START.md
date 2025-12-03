# Quick Start Guide

## Prerequisites

1. **IAM Instance Profile**: Ensure the IAM instance profile `packer-s3-role` exists and has S3 access permissions
2. **AWS Credentials**: Packer needs AWS credentials to launch EC2 instances (your local AWS CLI credentials)
3. **Configuration**: `sandbox.hcl` file configured with your values

## Step 1: Verify Your AWS Credentials (for Packer)

Packer needs AWS credentials to launch the build instance. Verify you have credentials configured:

```bash
aws sts get-caller-identity
```

Should show your AWS account and user information.

## Step 2: Verify IAM Instance Profile

Ensure the IAM instance profile `packer-s3-role` exists and has the necessary S3 permissions:

```bash
aws iam get-instance-profile --instance-profile-name packer-s3-role
```

The instance profile should be attached to a role with S3 read permissions for the bucket `warfilefortestspectrum`.

## Step 3: Build the AMI

```bash
cd packer-spectrum/packer
packer build -var-file=sandbox.hcl ubuntu.pkr.hcl
```

## How It Works

1. **Packer launches EC2 instance**: Uses your local AWS credentials (from AWS CLI, environment, or config file)
2. **IAM role attached**: Packer attaches the `packer-s3-role` instance profile to the build instance
3. **Instance uses role**: The build instance automatically uses the role's credentials via AWS Instance Metadata Service (IMDS)
4. **S3 download**: The `04-install-spectrum.sh` script uses AWS CLI, which automatically picks up credentials from IMDS
5. **No credentials in AMI**: Credentials are never stored in the AMI - only used temporarily during build

## Security Benefits

- ✅ **No access keys in code**: No need to pass access keys as environment variables
- ✅ **IAM role-based**: Uses AWS IAM roles for secure, temporary credentials
- ✅ **Automatic credential rotation**: Instance metadata service provides temporary credentials
- ✅ **Least privilege**: Role can be scoped to only S3 bucket access
- ✅ **No credentials in AMI**: Credentials are never baked into the final image
- ✅ **Audit trail**: All S3 access is logged via CloudTrail with the role identity

## Configuration

The IAM instance profile name is configured in `sandbox.hcl`:

```hcl
iam_instance_profile_name = "packer-s3-role"
```

You can override this by setting the variable when running Packer:

```bash
packer build -var-file=sandbox.hcl -var 'iam_instance_profile_name=my-custom-profile' ubuntu.pkr.hcl
```

