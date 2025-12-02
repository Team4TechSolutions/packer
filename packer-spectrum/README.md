# Packer Spectrum AMI Builder

A modular Packer configuration to build AWS AMIs with Spectrum application, Tomcat, and Docker pre-installed. This setup follows industry best practices with proper template separation, modular scripts, and CI/CD support.

## 📚 Documentation

- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Detailed guide explaining each file, what it does, and what information you need to provide.

## 📁 Directory Structure

```
packer-spectrum/
├── packer/
│   ├── ubuntu.pkr.hcl              # Main Packer template (HCL)
│   ├── variables.pkr.hcl           # Variable definitions
│   ├── Makefile                    # Utility commands (build/validate/fmt)
│   ├── VERSION                     # Version metadata for traceability
│   ├── sandbox.hcl                 # Environment-specific variables
│   │
│   ├── scripts/                    # Modular provisioning steps
│   │   ├── 00-install-dependencies.sh   # unzip, wget, net-tools, etc.
│   │   ├── 01-install-docker.sh         # Optional: docker for testing
│   │   ├── 02-install-java.sh           # Install OpenJDK 17
│   │   ├── 03-install-tomcat.sh         # Install Tomcat 10.1.x
│   │   ├── 04-install-spectrum.sh       # Install Spectrum backend + frontend
│   │   ├── 05-configure-tomcat.sh       # JVM, systemd, logging, catalina settings
│   │   ├── 06-configure-spectrum.sh     # appConfig.js, API URL, feature flags
│   │   ├── 07-hardening.sh              # OS hardening (optional)
│   │   └── 99-cleanup.sh                # Cleanup before AMI creation
│   │
│   ├── files/                      # Static assets included in the AMI
│   │   ├── templates/               # Template files rendered by Packer
│   │   │   ├── appConfig.js.tpl       # Spectrum frontend config template
│   │   │   ├── context.xml.tpl         # JNDI DB connection template
│   │   │   ├── setenv.sh.tpl          # JVM tuning template
│   │   │   └── tomcat.service        # Systemd service template
│   │   │
│   │   ├── conf/                    # Optional Tomcat override configs
│   │   │   ├── logging.properties
│   │   │   ├── catalina.properties
│   │   │   └── jvm.options
│   │   │
│   │   ├── spectrum/                # Optional pre-bundled Spectrum files
│   │   │   ├── spectrum-server.war
│   │   │   └── client/
│   │   │
│   │   └── jdbc/                    # Optional pre-bundled JDBC drivers
│   │       ├── mysql-connector-java.jar
│   │       └── mssql-jdbc-driver.jar
│   │
│   └── userdata/
│       └── firstboot.sh            # Optional first-boot configuration
│
└── README.md                       # This file
```

## ✨ Key Features

- ✅ **Modular Scripts** - Each script has a single responsibility
- ✅ **Template-Based Configuration** - Avoids hard-coded sed operations
- ✅ **Separated Concerns** - Tomcat and Spectrum configuration are separate
- ✅ **Version Tracking** - VERSION file for AMI build traceability
- ✅ **CI/CD Ready** - Makefile with standard commands
- ✅ **Environment-Specific** - Easy switching between environments (sandbox, production, etc.)
- ✅ **Tomcat Overrides** - Custom configuration files for logging, JVM, etc.

## 🚀 Quick Start

### Prerequisites

- Packer installed (>= 1.8.0)
- AWS credentials configured
- Access to VPC and subnet for building

### 1. Initialize Packer

```bash
cd packer-spectrum/packer
make init
# OR
packer init ubuntu.pkr.hcl
```

### 2. Configure Environment

Edit `sandbox.hcl` (or create your own environment file):

```hcl
# AWS Infrastructure
region = "ca-central-1"
vpc_id = "vpc-xxxxx"
subnet_id = "subnet-xxxxx"
account = "123456789012"

# Spectrum Application
spectrum_version = "5.x.x"
spectrum_package_url = "https://example.com/SpectrumV5.x.x.zip"

# Database Configuration
db_type = "mysql"  # or "sqlserver"
db_host = "your-db-host.example.com"
db_user = "spectrum"
db_password = "your-password"
db_name = "kioskmgr"

# Server Configuration
server_ip = "your-server-ip-or-hostname"
jvm_xmx = "2g"
jvm_xms = "1g"
```

### 3. Build AMI

**Using Makefile (Recommended):**
```bash
make build ENV_FILE=sandbox.hcl
```

**Or using Packer directly:**
```bash
packer build -var-file=sandbox.hcl ubuntu.pkr.hcl
```

## 🛠️ Makefile Commands

The Makefile provides convenient commands for common tasks:

```bash
make help              # Show available commands
make init              # Initialize Packer plugins
make validate          # Validate Packer configuration
make fmt               # Format Packer HCL files
make build             # Build AMI (requires ENV_FILE)
make clean             # Clean Packer cache
make version           # Show current version
make update-version    # Update version (make update-version VERSION=1.0.1)
```

### CI/CD Targets

```bash
make ci-validate       # CI: Validate configuration
make ci-build          # CI: Build AMI
```

## 📋 Scripts Overview

### 00-install-dependencies.sh
Installs basic system dependencies (wget, curl, unzip, etc.)

### 01-install-docker.sh
Installs Docker Engine, CLI, and Docker Compose

### 02-install-java.sh
Installs OpenJDK 17 and configures JAVA_HOME

### 03-install-tomcat.sh
Downloads and installs Apache Tomcat 10.1.x

### 04-install-spectrum.sh
Deploys Spectrum backend (WAR) and frontend applications

### 05-configure-tomcat.sh
Configures Tomcat-specific settings:
- JVM parameters (setenv.sh)
- Systemd service
- Firewall rules
- Tomcat configuration overrides (from files/conf/)

### 06-configure-spectrum.sh
Configures Spectrum-specific settings:
- JDBC driver installation (MySQL or SQL Server)
- Database connection in context.xml
- Frontend appConfig.js configuration

### 07-hardening.sh
Applies security hardening (file limits, process limits)

### 99-cleanup.sh
Cleans up temporary files before AMI finalization

## 📄 Template Files

Templates are used to avoid hard-coded configuration:

### `files/templates/appConfig.js.tpl`
Spectrum frontend configuration template with placeholders for server IP.

### `files/templates/context.xml.tpl`
Database connection template with placeholders for DB credentials.

### `files/templates/setenv.sh.tpl`
JVM tuning template with placeholders for heap sizes.

### `files/templates/tomcat.service`
Systemd service file for Tomcat.

## ⚙️ Configuration Files

### `files/conf/logging.properties`
Custom Tomcat logging configuration. Modify to change log levels, handlers, etc.

### `files/conf/catalina.properties`
Tomcat Catalina properties override. Add custom properties here.

### `files/conf/jvm.options`
Additional JVM options. Add custom JVM flags here.

## 🔐 Variable Configuration

Variables are defined in `variables.pkr.hcl` and values come from environment files (e.g., `sandbox.hcl`).

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `region` | AWS region | `"ca-central-1"` |
| `vpc_id` | VPC ID | `"vpc-xxxxx"` |
| `subnet_id` | Subnet ID | `"subnet-xxxxx"` |
| `account` | AWS account ID | `"123456789012"` |
| `spectrum_package_url` | Spectrum package URL | `"https://..."` |
| `db_host` | Database hostname | `"db.example.com"` |
| `db_password` | Database password | `"password"` |
| `server_ip` | Server IP/hostname | `"server.example.com"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `spectrum_version` | Spectrum version | `"5.x.x"` |
| `db_type` | Database type | `"mysql"` |
| `db_user` | Database user | `"spectrum"` |
| `db_name` | Database name | `"kioskmgr"` |
| `jvm_xmx` | JVM max heap | `"2g"` |
| `jvm_xms` | JVM initial heap | `"1g"` |

## 📝 Version Management

The `VERSION` file tracks AMI builds:

```
VERSION=1.0.0
BUILD_DATE=2025-12-02
BUILD_ENV=sandbox
```

Update version for each build:
```bash
make update-version VERSION=1.0.1
```

## 🌍 Environment Files

Create environment-specific variable files for different environments:

- `sandbox.hcl` - Sandbox environment
- `production.hcl` - Production environment
- `staging.hcl` - Staging environment

Each file contains environment-specific values (VPC, subnet, database, etc.).

## 🔄 Build Process

1. **Initialize** - `make init` - Downloads Packer plugins
2. **Validate** - `make validate ENV_FILE=sandbox.hcl` - Validates configuration
3. **Build** - `make build ENV_FILE=sandbox.hcl` - Builds AMI
4. **Result** - AMI ID is displayed and saved to `manifest.json`

## 📦 Post-Deployment

After launching an instance from the AMI:

1. **Verify Services:**
   ```bash
   sudo systemctl status tomcat
   ```

2. **Check Logs:**
   ```bash
   sudo tail -f /opt/tomcat/logs/catalina.out
   ```

3. **Access Spectrum:**
   - Frontend: `http://your-server-ip:8080/spectrum/`
   - Default credentials: `admin` / `admin`
   - **Important:** Change default password immediately!

4. **Configure Database:**
   - Ensure database is accessible from the instance
   - Database should be pre-created with required schema

## 🎯 Best Practices

### Template Usage
- Use templates (`.tpl` files) instead of hard-coded `sed` commands
- Templates are more maintainable and version-controllable

### Configuration Separation
- Tomcat configuration → `05-configure-tomcat.sh`
- Spectrum configuration → `06-configure-spectrum.sh`
- Clear separation of concerns

### Version Tracking
- Update `VERSION` file for each build
- Track build date and environment

### Environment Management
- Use separate `.hcl` files for each environment
- Never commit passwords to version control
- Use AWS Secrets Manager or environment variables for sensitive data

## 🚨 Important Notes

1. **Database Password:** Never commit passwords to version control. Use:
   - Environment variables
   - AWS Secrets Manager
   - Separate variables file (not in git)

2. **Spectrum Package:** The package must be:
   - Accessible via URL, OR
   - Uploaded to build instance before script runs

3. **Network Access:** Build instance needs:
   - Internet access (to download packages)
   - SSH access from your machine (for Packer)
   - Database access (if database is external)

4. **Default Credentials:** After deployment, Spectrum default login is:
   - Username: `admin`
   - Password: `admin`
   - **CHANGE THIS IMMEDIATELY!**

## 🐛 Troubleshooting

### Build Fails at SSH Connection
- Ensure subnet allows SSH from your IP
- Check security groups
- Verify `associate_public_ip_address = true` for public subnets

### Spectrum Package Not Found
- Verify `SPECTRUM_PACKAGE_URL` is accessible
- Or provide `SPECTRUM_PACKAGE_PATH` with absolute path

### Database Connection Issues
- Verify database credentials
- Ensure database is accessible from build instance
- Check firewall rules

### Template Not Found
- Ensure template files are in `files/templates/`
- Check file provisioner paths in `ubuntu.pkr.hcl`

## 📞 Additional Resources

- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Detailed setup instructions and file explanations
- [Packer Documentation](https://www.packer.io/docs)
- [Apache Tomcat Documentation](https://tomcat.apache.org/tomcat-10.1-doc/)

## 📄 License

[Your License Here]

---

**Last Updated:** 2025-12-02  
**Version:** 1.0.0
