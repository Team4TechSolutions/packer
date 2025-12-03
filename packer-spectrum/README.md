# Packer Spectrum AMI Builder

A modular Packer configuration to build AWS AMIs with Spectrum application, Tomcat, and Java pre-installed. This project supports both **Linux (Ubuntu)** and **Windows Server** platforms with a clean, organized structure following industry best practices.

## 📚 Documentation

- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Detailed guide explaining each file, what it does, and what information you need to provide.
- **[packer/PARAMETER-STORE-SETUP.md](packer/PARAMETER-STORE-SETUP.md)** - Guide for setting up AWS Parameter Store for secure credential storage.
- **[packer/linux/ubuntu/README.md](packer/linux/ubuntu/README.md)** - Linux/Ubuntu-specific documentation.
- **[packer/windows/README.md](packer/windows/README.md)** - Windows-specific documentation.

## 📁 Project Structure

```
packer-spectrum/
├── packer/                           # Main Packer configuration directory
│   ├── Makefile                      # Root-level build orchestrator
│   ├── VERSION                       # Version metadata for traceability
│   ├── PARAMETER-STORE-SETUP.md     # AWS Parameter Store setup guide
│   ├── WINDOWS-SETUP.md              # Windows deployment guide
│   │
│   ├── linux/                        # Linux distributions
│   │   └── ubuntu/                   # Ubuntu-specific configuration
│   │       ├── ubuntu.pkr.hcl        # Main Packer template for Ubuntu
│   │       ├── sandbox.hcl           # Environment-specific variables
│   │       ├── Makefile              # Ubuntu build commands
│   │       ├── README.md              # Ubuntu-specific documentation
│   │       │
│   │       ├── scripts/               # Modular provisioning scripts
│   │       │   ├── 00-install-dependencies.sh
│   │       │   ├── 01-install-docker.sh
│   │       │   ├── 02-install-java.sh
│   │       │   ├── 03-install-tomcat.sh
│   │       │   ├── 04-install-spectrum.sh
│   │       │   ├── 05-configure-tomcat.sh
│   │       │   ├── 06-configure-spectrum.sh
│   │       │   ├── 07-hardening.sh
│   │       │   └── 99-cleanup.sh
│   │       │
│   │       ├── files/                # Static assets and templates
│   │       │   ├── templates/       # Configuration templates
│   │       │   │   ├── appConfig.js.tpl
│   │       │   │   ├── context.xml.tpl
│   │       │   │   ├── setenv.sh.tpl
│   │       │   │   └── tomcat.service
│   │       │   └── conf/            # Tomcat configuration overrides
│   │       │
│   │       └── userdata/            # EC2 user data scripts
│   │
│   └── windows/                      # Windows Server configuration
│       ├── windows.pkr.hcl           # Main Packer template for Windows
│       ├── sandbox.hcl               # Environment-specific variables
│       ├── Makefile                  # Windows build commands
│       ├── README.md                 # Windows-specific documentation
│       │
│       ├── scripts/                  # PowerShell provisioning scripts
│       │   ├── 00-Install-Dependencies.ps1
│       │   ├── 01-Install-Java.ps1
│       │   ├── 02-Install-Tomcat.ps1
│       │   ├── 03-Install-Spectrum.ps1
│       │   ├── 04-Configure-Tomcat.ps1
│       │   ├── 05-Configure-Spectrum.ps1
│       │   ├── 06-Hardening.ps1
│       │   └── 99-Cleanup.ps1
│       │
│       ├── files/                    # Static assets and templates
│       │   └── templates/           # Configuration templates
│       │       ├── appConfig.js.tpl
│       │       ├── context.xml.tpl
│       │       └── setenv.bat.tpl
│       │
│       └── userdata/                 # EC2 user data scripts
│           └── windows-userdata.ps1
│
├── README.md                         # This file
└── SETUP-GUIDE.md                    # Detailed setup guide
```

## ✨ Key Features

- ✅ **Multi-Platform Support** - Build AMIs for both Linux (Ubuntu) and Windows Server
- ✅ **Modular Scripts** - Each script has a single responsibility
- ✅ **Template-Based Configuration** - Avoids hard-coded sed operations
- ✅ **Separated Concerns** - Tomcat and Spectrum configuration are separate
- ✅ **Version Tracking** - VERSION file for AMI build traceability
- ✅ **CI/CD Ready** - Makefile with standard commands
- ✅ **Environment-Specific** - Easy switching between environments (sandbox, production, etc.)
- ✅ **Secure Credential Storage** - AWS Parameter Store integration for sensitive data
- ✅ **S3 Support** - Download Spectrum packages from S3 buckets
- ✅ **IAM Role-Based Access** - Uses instance profiles for secure S3 access

## 🚀 Quick Start

### Prerequisites

- **Packer** installed (>= 1.8.0)
- **AWS CLI** configured with appropriate credentials
- **AWS Parameter Store** parameters created (see [PARAMETER-STORE-SETUP.md](packer/PARAMETER-STORE-SETUP.md))
- **IAM Permissions**:
  - EC2: Create instances, AMIs, security groups, key pairs
  - SSM: Read Parameter Store values
  - S3: Read from Spectrum package bucket (if using S3)

### 1. Set Up AWS Parameter Store

Database credentials are stored securely in AWS Parameter Store. Create the required parameters:

```bash
# Database host
aws ssm put-parameter \
  --name "/spectrum/sandbox/db-host" \
  --value "your-db-host.example.com" \
  --type "String" \
  --region ca-central-1

# Database user
aws ssm put-parameter \
  --name "/spectrum/sandbox/db-user" \
  --value "admin" \
  --type "String" \
  --region ca-central-1

# Database password (SecureString - encrypted)
aws ssm put-parameter \
  --name "/spectrum/sandbox/db-password" \
  --value "your-password" \
  --type "SecureString" \
  --region ca-central-1
```

See [packer/PARAMETER-STORE-SETUP.md](packer/PARAMETER-STORE-SETUP.md) for detailed instructions.

### 2. Configure Environment

Edit the environment-specific file (e.g., `packer/linux/ubuntu/sandbox.hcl` or `packer/windows/sandbox.hcl`):

```hcl
# AWS Infrastructure
region = "ca-central-1"
vpc_id = "vpc-xxxxx"
subnet_id = "subnet-xxxxx"
account = "123456789012"

# IAM Instance Profile for S3 access
iam_instance_profile_name = "packer-s3-role"

# Spectrum Application
spectrum_version = "5.9.0"
spectrum_s3_bucket = "warfilefortestspectrum"
spectrum_s3_path = "5.9.0"

# Database Configuration (from Parameter Store)
ssm_db_host_path = "/spectrum/sandbox/db-host"
ssm_db_user_path = "/spectrum/sandbox/db-user"
ssm_db_password_path = "/spectrum/sandbox/db-password"
db_type = "mysql"
db_name = "kioskmgr"

# Server Configuration
server_ip = "your-server-ip-or-hostname"
jvm_xmx = "2g"
jvm_xms = "1g"
```

### 3. Build AMI

#### For Linux (Ubuntu):

```bash
cd packer/linux/ubuntu
make build
# OR
packer build -var-file=sandbox.hcl ubuntu.pkr.hcl
```

#### For Windows:

```bash
cd packer/windows
make build
# OR
packer build -var-file=sandbox.hcl windows.pkr.hcl
```

## 🛠️ Build Commands

Each platform has its own Makefile with convenient commands:

### Linux/Ubuntu (`packer/linux/ubuntu/`)

```bash
make help              # Show available commands
make validate          # Validate Packer configuration
make fmt               # Format Packer HCL files
make build             # Build Ubuntu AMI
make clean             # Clean build artifacts
```

### Windows (`packer/windows/`)

```bash
make help              # Show available commands
make validate          # Validate Packer configuration
make fmt               # Format Packer HCL files
make build             # Build Windows AMI
make clean             # Clean build artifacts
```

## 📋 What Gets Installed

### Linux (Ubuntu)
1. **System Dependencies**: wget, curl, unzip, AWS CLI v2
2. **Docker**: Docker Engine (optional)
3. **Java**: OpenJDK 17
4. **Tomcat**: Apache Tomcat 10.1.20 (as systemd service)
5. **Spectrum Application**: Backend WAR + Frontend static files
6. **JDBC Drivers**: MySQL or SQL Server connector
7. **Configuration**: Database connection, JVM settings, firewall rules

### Windows Server
1. **System Tools**: Chocolatey, Git, curl, unzip, AWS CLI v2
2. **Java**: OpenJDK 17 (via Chocolatey)
3. **Tomcat**: Apache Tomcat 10.1.20 (as Windows Service)
4. **Spectrum Application**: Backend WAR + Frontend static files
5. **JDBC Drivers**: MySQL or SQL Server connector
6. **Configuration**: Database connection, JVM settings, firewall rules

## 🔐 Security Features

- **AWS Parameter Store Integration** - Database credentials stored securely (not in git)
- **IAM Instance Profiles** - S3 access via IAM roles (no hardcoded credentials)
- **SecureString Parameters** - Encrypted password storage in Parameter Store
- **Security Hardening** - Default Tomcat apps removed, firewall configured
- **Encrypted Boot Volumes** - AMI boot volumes are encrypted

## 📦 Spectrum Package Sources

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

## 🌍 Environment Files

Create environment-specific variable files for different environments:

- `sandbox.hcl` - Sandbox environment
- `production.hcl` - Production environment
- `staging.hcl` - Staging environment

Each file contains environment-specific values (VPC, subnet, Parameter Store paths, etc.).

## 🔄 Build Process

### Linux Build Process:
1. Launch EC2 instance (Ubuntu 22.04 LTS)
2. Install system dependencies
3. Install Docker (optional)
4. Install Java 17
5. Install Tomcat 10.1.20
6. Deploy Spectrum applications
7. Configure Tomcat (JVM, systemd, logging)
8. Configure Spectrum (JDBC, database, frontend)
9. Security hardening
10. Cleanup
11. Create AMI

### Windows Build Process:
1. Launch EC2 instance (Windows Server 2022)
2. Configure WinRM for Packer communication
3. Install Chocolatey and system tools
4. Install Java 17
5. Install Tomcat 10.1.20
6. Deploy Spectrum applications
7. Configure Tomcat (JVM, Windows Service, firewall)
8. Configure Spectrum (JDBC, database, frontend)
9. Security hardening
10. Cleanup
11. Create AMI

## 📝 Version Management

The `VERSION` file tracks AMI builds:

```
VERSION=1.0.0
BUILD_DATE=2025-12-03
BUILD_ENV=sandbox
```

## 📦 Post-Deployment

After launching an instance from the AMI:

### Linux:
```bash
# Verify Tomcat service
sudo systemctl status tomcat10

# Check logs
sudo tail -f /opt/tomcat/logs/catalina.out

# Access Spectrum
# Frontend: http://your-server-ip:8080/spectrum/
```

### Windows:
```powershell
# Verify Tomcat service
Get-Service Tomcat10

# Check logs
Get-Content C:\Tomcat10\logs\catalina.out -Tail 50

# Access Spectrum
# Frontend: http://your-server-ip:8080/spectrum/
```

## 🎯 Best Practices

### Security
- ✅ Use AWS Parameter Store for all sensitive credentials
- ✅ Use IAM instance profiles for S3 access (no hardcoded keys)
- ✅ Use SecureString type for passwords in Parameter Store
- ✅ Never commit passwords to version control

### Configuration
- ✅ Use templates (`.tpl` files) instead of hard-coded `sed` commands
- ✅ Separate environment-specific files (sandbox.hcl, production.hcl)
- ✅ Update VERSION file for each build

### Organization
- ✅ Platform-specific files in their respective directories
- ✅ Shared documentation in root `packer/` directory
- ✅ Each platform has its own Makefile and README

## 🚨 Important Notes

1. **Database Credentials**: Stored in AWS Parameter Store (not in git). See [PARAMETER-STORE-SETUP.md](packer/PARAMETER-STORE-SETUP.md).

2. **IAM Permissions**: The build instance needs:
   - `ssm:GetParameter` for Parameter Store
   - `s3:GetObject` and `s3:ListBucket` for S3 bucket access
   - EC2 permissions for instance creation

3. **Network Access**: Build instance needs:
   - Internet access (to download packages)
   - SSH/WinRM access from your machine (for Packer)
   - Database access (if database is external)

4. **Default Credentials**: After deployment, change default Spectrum login credentials immediately!

## 🐛 Troubleshooting

### Build Fails with "Parameter not found"
- Ensure Parameter Store parameters exist in the correct region
- Verify parameter paths in `sandbox.hcl` match actual parameter names
- Check IAM permissions include `ssm:GetParameter`

### Build Fails with "Access Denied" (S3)
- Verify IAM instance profile is attached
- Check IAM role has `s3:GetObject` and `s3:ListBucket` permissions
- Ensure bucket name and path are correct

### Database Connection Issues
- Verify database credentials in Parameter Store
- Ensure database is accessible from build instance
- Check security groups allow database port (3306 for MySQL, 1433 for SQL Server)

### Template Not Found
- Ensure template files are in `files/templates/` directory
- Check file provisioner paths in Packer configuration

## 📞 Additional Resources

- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Detailed setup instructions
- **[packer/PARAMETER-STORE-SETUP.md](packer/PARAMETER-STORE-SETUP.md)** - Parameter Store setup guide
- **[packer/linux/ubuntu/README.md](packer/linux/ubuntu/README.md)** - Ubuntu-specific documentation
- **[packer/windows/README.md](packer/windows/README.md)** - Windows-specific documentation
- [Packer Documentation](https://www.packer.io/docs)
- [Apache Tomcat Documentation](https://tomcat.apache.org/tomcat-10.1-doc/)

## 📄 License

[Your License Here]

---

**Last Updated:** 2025-12-03  
**Version:** 1.0.0
