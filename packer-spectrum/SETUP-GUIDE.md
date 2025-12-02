# Spectrum Packer Setup Guide

This guide explains each file in the Packer Spectrum setup, what it does, and what information you need to provide.

## 📋 Table of Contents

1. [Packer Configuration Files](#packer-configuration-files)
2. [Installation Scripts](#installation-scripts)
3. [Template Files](#template-files)
4. [Variable Configuration](#variable-configuration)
5. [Quick Start Checklist](#quick-start-checklist)

---

## 📁 Packer Configuration Files

### `packer/ubuntu.pkr.hcl`

**What it does:** Main Packer configuration file that defines how to build the AMI.

**What you need to configure:**

1. **AWS Infrastructure Variables** (REQUIRED):
   ```hcl
   region = "ca-central-1"        # Your AWS region
   vpc_id = "vpc-xxxxx"           # VPC ID where build instance will run
   subnet_id = "subnet-xxxxx"     # Subnet ID (should be public for SSH access)
   account = "123456789012"       # Your AWS account ID (12 digits)
   ```

2. **Spectrum Application Variables** (REQUIRED - choose one):
   ```hcl
   spectrum_version = "5.x.x"     # Version of Spectrum you're deploying
   
   # Option 1: Download from URL
   spectrum_package_url = "https://example.com/SpectrumV5.x.x.zip"
   
   # Option 2: Use local file (must be uploaded to build instance)
   spectrum_package_path = "/tmp/SpectrumV5.x.x.zip"
   ```

3. **Database Configuration** (REQUIRED):
   ```hcl
   db_type = "mysql"              # or "sqlserver"
   db_host = "your-db-host.example.com"  # Database server hostname/IP
   db_user = "spectrum"           # Database username
   db_password = "your-secure-password"  # Database password (sensitive)
   db_name = "kioskmgr"           # Database name
   ```

4. **Server Configuration** (REQUIRED):
   ```hcl
   server_ip = "your-server-ip-or-hostname"  # IP/hostname for frontend config
   ```

5. **JVM Configuration** (OPTIONAL - defaults provided):
   ```hcl
   jvm_xmx = "2g"                 # Maximum heap size (default: 2g)
   jvm_xms = "1g"                 # Initial heap size (default: 1g)
   ```

**Note:** You can create a separate `variables.hcl` file with these values and reference it with `-var-file=variables.hcl` when building.

---

## 🔧 Installation Scripts

### `scripts/00-install-dependencies.sh`

**What it does:** Installs basic system tools (wget, curl, unzip, etc.)

**What you need to configure:** 
- ✅ **Nothing** - This script is ready to use as-is

---

### `scripts/01-install-docker.sh`

**What it does:** Installs Docker Engine, CLI, and Docker Compose

**What you need to configure:**
- ✅ **Nothing** - This script is ready to use as-is
- ⚠️ **Optional:** Remove this provisioner from `ubuntu.pkr.hcl` if you don't need Docker

---

### `scripts/02-install-java.sh`

**What it does:** Installs OpenJDK 17 and sets up JAVA_HOME

**What you need to configure:**
- ✅ **Nothing** - This script is ready to use as-is
- ⚠️ **Note:** If you need a different Java version, modify the `apt-get install` line

---

### `scripts/03-install-tomcat.sh`

**What it does:** Downloads and installs Apache Tomcat 10.1.x

**What you need to configure:**
- ⚠️ **Optional:** Change Tomcat version at the top of the script:
  ```bash
  TOMCAT_VERSION="${TOMCAT_VERSION:-10.1.20}"  # Change version if needed
  ```
- ✅ **Otherwise ready to use** - Defaults to Tomcat 10.1.20

---

### `scripts/04-install-spectrum.sh`

**What it does:** Downloads/extracts and deploys Spectrum backend (WAR) and frontend

**What you need to configure:**
- ✅ **Nothing** - Uses variables from Packer config:
  - `SPECTRUM_VERSION`
  - `SPECTRUM_PACKAGE_URL` or `SPECTRUM_PACKAGE_PATH`
- ⚠️ **Important:** Make sure you've set `spectrum_package_url` or `spectrum_package_path` in your variables

---

### `scripts/05-configure-spectrum.sh`

**What it does:** 
- Installs JDBC drivers (MySQL or SQL Server)
- Configures database connection in `context.xml`
- Configures frontend `appConfig.js`
- Sets up JVM parameters
- Configures firewall

**What you need to configure:**
- ✅ **Nothing** - Uses environment variables passed from Packer:
  - `DB_TYPE` (mysql or sqlserver)
  - `DB_HOST`
  - `DB_USER`
  - `DB_PASSWORD`
  - `DB_NAME`
  - `SERVER_IP`
  - `JVM_XMX`
  - `JVM_XMS`

**What it does automatically:**
- Downloads appropriate JDBC driver based on `DB_TYPE`
- Configures database connection string
- Updates frontend API URL

---

### `scripts/06-hardening.sh`

**What it does:** Applies security hardening (file limits, process limits)

**What you need to configure:**
- ✅ **Nothing** - This script is ready to use as-is
- ⚠️ **Optional:** Adjust limits in the script if needed:
  ```bash
  tomcat soft nofile 65536  # Adjust if needed
  tomcat hard nofile 65536
  ```

---

### `scripts/99-cleanup.sh`

**What it does:** Cleans up temporary files before AMI finalization

**What you need to configure:**
- ✅ **Nothing** - This script is ready to use as-is
- ⚠️ **Optional:** Uncomment the zero-out section if you want smaller AMI (slower build):
  ```bash
  # sudo dd if=/dev/zero of=/EMPTY bs=1M || true
  # sudo rm -f /EMPTY
  ```

---

## 📄 Template Files

### `files/templates/tomcat.service`

**What it does:** Systemd service file for Tomcat

**What you need to configure:**
- ⚠️ **Check JAVA_HOME path** - Verify it matches your Java installation:
  ```ini
  Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
  ```
  - Find your Java path with: `dirname $(dirname $(readlink -f $(which java)))`
  - Update if different

- ✅ **Otherwise ready to use** - Defaults work for Ubuntu 22.04

---

### `files/templates/context.xml.tpl`

**What it does:** Template for Tomcat database connection configuration

**Status:** 
- ⚠️ **NOT CURRENTLY USED** - The script `05-configure-spectrum.sh` modifies `context.xml` directly
- This template is provided for reference or manual configuration

**If you want to use this template:**
1. Replace placeholders:
   - `{{DB_USER}}` → Your database username
   - `{{DB_PASSWORD}}` → Your database password
   - `{{DB_DRIVER}}` → `com.mysql.cj.jdbc.Driver` or `com.microsoft.sqlserver.jdbc.SQLServerDriver`
   - `{{DB_URL}}` → Your database connection URL

2. Add a file provisioner in `ubuntu.pkr.hcl`:
   ```hcl
   provisioner "file" {
     source      = "./files/templates/context.xml"
     destination = "/opt/tomcat/conf/context.xml"
   }
   ```

---

### `files/templates/appConfig.js.tpl`

**What it does:** Template for Spectrum frontend configuration

**Status:**
- ⚠️ **NOT CURRENTLY USED** - The script `05-configure-spectrum.sh` modifies `appConfig.js` directly
- This template is provided for reference or manual configuration

**If you want to use this template:**
1. Replace placeholder:
   - `{{SERVER_IP}}` → Your server IP or hostname

2. Add a file provisioner in `ubuntu.pkr.hcl`:
   ```hcl
   provisioner "file" {
     source      = "./files/templates/appConfig.js"
     destination = "/opt/tomcat/webapps/spectrum/appConfig.js"
   }
   ```

**Configuration options in appConfig.js:**
- `spectrumApiUrl`: Backend API URL
- `enableReports`: Enable/disable reports feature
- `enableInsights`: Enable/disable insights feature
- `recordsPerPage`: Number of records per page
- `dateFormat`: Date format string
- `maxFileUploadSize`: Maximum file upload size in MB

---

## 🔐 Variable Configuration

### Environment-Specific Files

Create environment-specific variable files for different environments (recommended approach):

**Example: `sandbox.hcl`** (Your current environment file)
```hcl
region = "ca-central-1"
vpc_id = "vpc-xxxxx"
subnet_id = "subnet-xxxxx"
account = "123456789012"
# ... etc
```

**Note:** You can create additional environment files as needed:
- `production.hcl` - for production environment
- `staging.hcl` - for staging environment
- `dev.hcl` - for development environment

### Required Variables

Create an environment file (e.g., `ca-central-1.hcl`, `sandbox.hcl`) or use command-line:

```hcl
# AWS Infrastructure
region = "ca-central-1"
vpc_id = "vpc-0123456789abcdef0"
subnet_id = "subnet-0123456789abcdef0"
account = "123456789012"

# Spectrum Application
spectrum_version = "5.x.x"
spectrum_package_url = "https://your-server.com/SpectrumV5.x.x.zip"
# OR
# spectrum_package_path = "/path/to/SpectrumV5.x.x.zip"

# Database Configuration
db_type = "mysql"  # or "sqlserver"
db_host = "database.example.com"
db_user = "spectrum"
db_password = "your-secure-password"
db_name = "kioskmgr"

# Server Configuration
server_ip = "your-server-ip-or-hostname"
```

### Optional Variables

```hcl
# JVM Configuration (defaults shown)
jvm_xmx = "2g"  # Maximum heap: 2g, 4g, 8g, etc.
jvm_xms = "1g"  # Initial heap: 1g, 2g, 4g, etc.
```

---

## ✅ Quick Start Checklist

Before building your AMI, ensure you have:

### 1. AWS Configuration
- [ ] AWS credentials configured (`aws configure` or environment variables)
- [ ] VPC ID identified
- [ ] Public subnet ID identified (for SSH access during build)
- [ ] AWS account ID (12 digits)

### 2. Spectrum Package
- [ ] Spectrum ZIP package URL accessible, OR
- [ ] Spectrum ZIP package path available

### 3. Database Configuration
- [ ] Database type decided (MySQL or SQL Server)
- [ ] Database hostname/IP
- [ ] Database username
- [ ] Database password
- [ ] Database name (default: `kioskmgr`)
- [ ] Database accessible from build instance network

### 4. Server Configuration
- [ ] Server IP or hostname for frontend configuration
- [ ] JVM heap sizes decided (optional, defaults: 2g/1g)

### 5. File Verification
- [ ] Check `tomcat.service` JAVA_HOME path matches your system
- [ ] All scripts are executable (`chmod +x scripts/*.sh`)

### 6. Build Command
```bash
cd packer-spectrum/packer
packer init ubuntu.pkr.hcl

# Build using your sandbox environment file
packer build -var-file=sandbox.hcl ubuntu.pkr.hcl
```

---

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

---

## 📞 Need Help?

- Check script logs during build for specific errors
- Verify all variables are set correctly
- Ensure network connectivity to required resources
- Review README.md for general usage information

