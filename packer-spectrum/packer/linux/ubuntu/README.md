# Spectrum AMI Builder - Linux

This directory contains the Packer configuration for building Linux (Ubuntu) AMIs with Spectrum application, Tomcat, and Java pre-installed.

## Directory Structure

```
linux/
├── linux.pkr.hcl          # Main Packer configuration
├── sandbox.hcl            # Sandbox environment variables
├── Makefile               # Build automation
├── README.md              # This file
├── scripts/               # Installation and configuration scripts
│   ├── 00-install-dependencies.sh
│   ├── 01-install-docker.sh
│   ├── 02-install-java.sh
│   ├── 03-install-tomcat.sh
│   ├── 04-install-spectrum.sh
│   ├── 05-configure-tomcat.sh
│   ├── 06-configure-spectrum.sh
│   ├── 07-hardening.sh
│   └── 99-cleanup.sh
├── files/                 # Configuration files and templates
│   ├── templates/         # Template files for configuration
│   │   ├── context.xml.tpl
│   │   ├── appConfig.js.tpl
│   │   └── setenv.sh.tpl
│   └── conf/             # Tomcat configuration overrides
└── userdata/             # EC2 user data scripts (if needed)
```

## Prerequisites

1. **Packer** installed (version 1.7.0 or later)
2. **AWS CLI** configured with appropriate credentials
3. **AWS Parameter Store** parameters created (see `../PARAMETER-STORE-SETUP.md`)
4. **IAM Permissions**:
   - EC2: Create instances, AMIs, security groups, key pairs
   - SSM: Read Parameter Store values
   - S3: Read from Spectrum package bucket (if using S3)

## Quick Start

### 1. Configure Environment

Edit `sandbox.hcl` to set your environment-specific values:

```hcl
region = "ca-central-1"
vpc_id = "vpc-xxxxx"
subnet_id = "subnet-xxxxx"
spectrum_s3_bucket = "your-bucket-name"
spectrum_s3_path = "5.9.0"
```

### 2. Set Up Parameter Store

Create database credentials in AWS Parameter Store:

```bash
aws ssm put-parameter \
  --name "/spectrum/sandbox/db-host" \
  --value "your-db-host" \
  --type "String" \
  --region ca-central-1

aws ssm put-parameter \
  --name "/spectrum/sandbox/db-user" \
  --value "your-db-user" \
  --type "String" \
  --region ca-central-1

aws ssm put-parameter \
  --name "/spectrum/sandbox/db-password" \
  --value "your-db-password" \
  --type "SecureString" \
  --region ca-central-1
```

See `../PARAMETER-STORE-SETUP.md` for detailed instructions.

### 3. Build the AMI

```bash
# Validate configuration
make validate

# Build the AMI
make build
```

Or use Packer directly:

```bash
packer build -var-file=sandbox.hcl linux.pkr.hcl
```

## What Gets Installed

1. **System Dependencies**: wget, curl, unzip, AWS CLI v2
2. **Docker**: Docker Engine (optional, can be disabled)
3. **Java**: OpenJDK 17
4. **Tomcat**: Apache Tomcat 10.1.20
5. **Spectrum Application**:
   - Backend WAR file (`spectrum-server.war`)
   - Frontend static files (`spectrum/`)
6. **JDBC Drivers**: MySQL or SQL Server connector
7. **Configuration**: Database connection, JVM settings, firewall rules

## Configuration

### Database Configuration

Database credentials are retrieved from AWS Parameter Store. Configure the paths in `sandbox.hcl`:

```hcl
ssm_db_host_path = "/spectrum/sandbox/db-host"
ssm_db_user_path = "/spectrum/sandbox/db-user"
ssm_db_password_path = "/spectrum/sandbox/db-password"
```

### Spectrum Package Source

The build supports three methods for obtaining the Spectrum package:

1. **S3 Bucket** (recommended):
   ```hcl
   spectrum_s3_bucket = "warfilefortestspectrum"
   spectrum_s3_path = "5.9.0"
   ```

2. **HTTP/HTTPS URL**:
   ```hcl
   spectrum_package_url = "https://example.com/SpectrumV5.9.0.zip"
   ```

3. **Local Path**:
   ```hcl
   spectrum_package_path = "/path/to/SpectrumV5.9.0.zip"
   ```

### JVM Configuration

Adjust JVM heap size in `sandbox.hcl`:

```hcl
jvm_xmx = "2g"  # Maximum heap size
jvm_xms = "1g"  # Initial heap size
```

## Build Process

The build process follows these steps:

1. **Launch EC2 Instance**: Ubuntu 22.04 LTS base AMI
2. **Install Dependencies**: System packages, AWS CLI
3. **Install Docker**: (Optional) Docker Engine
4. **Install Java**: OpenJDK 17
5. **Install Tomcat**: Apache Tomcat 10.1.20 as systemd service
6. **Deploy Spectrum**: Download and deploy backend WAR and frontend
7. **Configure Tomcat**: JVM settings, systemd service, logging
8. **Configure Spectrum**: JDBC drivers, database connection, frontend config
9. **Security Hardening**: Remove default apps, configure firewall
10. **Cleanup**: Remove temporary files and logs
11. **Create AMI**: Finalize and create the AMI

## Output

After a successful build, you'll see:

```
--> amazon-ebs.linux: AMIs were created:
ca-central-1: ami-xxxxxxxxxxxxxxxxx
```

The AMI ID is also saved in `manifest.json`.

## Troubleshooting

### Build Fails with "Parameter not found"

Ensure Parameter Store parameters exist:
```bash
aws ssm describe-parameters \
  --parameter-filters "Key=Name,Values=/spectrum/sandbox/" \
  --region ca-central-1
```

### Build Fails with "Access Denied"

Check IAM permissions:
- `ssm:GetParameter` for Parameter Store
- `s3:GetObject` and `s3:ListBucket` for S3 bucket
- EC2 permissions for instance creation

### Tomcat Not Starting

Check the instance logs after launch:
```bash
ssh ubuntu@<instance-ip>
sudo systemctl status tomcat10
sudo journalctl -u tomcat10 -n 50
```

### Database Connection Issues

Verify database credentials in Parameter Store:
```bash
aws ssm get-parameter \
  --name "/spectrum/sandbox/db-host" \
  --with-decryption \
  --region ca-central-1
```

## Security Notes

- **Database credentials** are stored in AWS Parameter Store (not in git)
- **IAM instance profile** is used for S3 access (no hardcoded credentials)
- **Default Tomcat apps** are removed for security
- **Firewall rules** are configured to allow only necessary ports

## Related Documentation

- `../PARAMETER-STORE-SETUP.md` - Setting up AWS Parameter Store
- `../README.md` - Main project documentation
- `../windows/README.md` - Windows AMI builder documentation

