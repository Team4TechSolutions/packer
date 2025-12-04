packer {
  required_plugins {
    amazon = {
      version = "~> 1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Variable definitions (same as Linux version)
# Variable values come from environment files (e.g., sandbox.hcl)

variable "region" {
  type        = string
  description = "AWS region where the AMI will be built"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the build instance will be launched"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID (should be public for WinRM access during build)"
}

variable "account" {
  type        = string
  description = "AWS account ID (12 digits)"
}

variable "spectrum_version" {
  type        = string
  default     = "5.x.x"
  description = "Spectrum application version to deploy"
}

variable "spectrum_s3_bucket" {
  type        = string
  default     = ""
  description = "S3 bucket name for Spectrum package (optional)"
}

variable "spectrum_s3_path" {
  type        = string
  default     = ""
  description = "S3 path/prefix for Spectrum package (optional)"
}

variable "spectrum_package_url" {
  type        = string
  default     = ""
  description = "URL to download Spectrum package (optional if using S3 or local file)"
}

variable "spectrum_package_path" {
  type        = string
  default     = ""
  description = "Local path to Spectrum package (optional if using S3 or URL)"
}

variable "iam_instance_profile_name" {
  type        = string
  default     = ""
  description = "IAM instance profile name for S3 access during build"
}

variable "db_type" {
  type        = string
  default     = "mysql"
  description = "Database type: mysql or sqlserver"
  validation {
    condition     = contains(["mysql", "sqlserver"], var.db_type)
    error_message = "The db_type variable must be either 'mysql' or 'sqlserver'."
  }
}

variable "db_host" {
  type        = string
  default     = ""
  description = "Database server hostname or IP address (optional if using Parameter Store)"
}

variable "db_user" {
  type        = string
  default     = ""
  description = "Database username (optional if using Parameter Store)"
}

variable "db_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Database password (optional if using Parameter Store)"
}

variable "db_name" {
  type        = string
  default     = "kioskmgr"
  description = "Database name"
}

# Parameter Store paths for sensitive database credentials
variable "ssm_db_host_path" {
  type        = string
  default     = ""
  description = "AWS SSM Parameter Store path for database host (e.g., /spectrum/sandbox/db-host)"
}

variable "ssm_db_user_path" {
  type        = string
  default     = ""
  description = "AWS SSM Parameter Store path for database user (e.g., /spectrum/sandbox/db-user)"
}

variable "ssm_db_password_path" {
  type        = string
  default     = ""
  sensitive   = true
  description = "AWS SSM Parameter Store path for database password (e.g., /spectrum/sandbox/db-password)"
}

variable "server_ip" {
  type        = string
  default     = "localhost"
  description = "Server IP address or hostname for frontend configuration"
}

variable "jvm_xmx" {
  type        = string
  default     = "2g"
  description = "JVM maximum heap size (e.g., 2g, 4g, 8g)"
}

variable "jvm_xms" {
  type        = string
  default     = "1g"
  description = "JVM initial heap size (e.g., 1g, 2g, 4g)"
}

# Data sources for AWS Parameter Store
# Only attempt to read from Parameter Store if paths are provided
data "amazon-parameterstore" "db_host" {
  name = var.ssm_db_host_path != "" ? var.ssm_db_host_path : "/spectrum/not-used/db-host"
}

data "amazon-parameterstore" "db_user" {
  name = var.ssm_db_user_path != "" ? var.ssm_db_user_path : "/spectrum/not-used/db-user"
}

data "amazon-parameterstore" "db_password" {
  name = var.ssm_db_password_path != "" ? var.ssm_db_password_path : "/spectrum/not-used/db-password"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  instance_profile_name = var.iam_instance_profile_name != "" ? var.iam_instance_profile_name : null
  
  # Use Parameter Store values if paths are provided, otherwise fall back to variables
  # Only use data source value if the path variable is actually set
  db_host = var.ssm_db_host_path != "" ? try(data.amazon-parameterstore.db_host.value, var.db_host != "" ? var.db_host : "localhost") : (var.db_host != "" ? var.db_host : "localhost")
  db_user = var.ssm_db_user_path != "" ? try(data.amazon-parameterstore.db_user.value, var.db_user != "" ? var.db_user : "spectrum") : (var.db_user != "" ? var.db_user : "spectrum")
  db_password = var.ssm_db_password_path != "" ? try(data.amazon-parameterstore.db_password.value, var.db_password) : var.db_password
}

source "amazon-ebs" "windows" {
  ami_name      = "spectrum-tomcat-windows-${local.timestamp}"
  instance_type = "t3.large"
  region        = var.region
  
  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  
  imds_support                = "v2.0"
  communicator                = "winrm"
  winrm_username              = "Administrator"
  winrm_timeout               = "90m"
  winrm_use_ssl               = false
  winrm_insecure              = true
  winrm_port                  = 5985
  
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  encrypt_boot                = true
  
  # IAM instance profile for S3 access during build
  iam_instance_profile = local.instance_profile_name
  
  # User data to enable WinRM and set password
  # Using user_data_file instead of user_data for direct file reference
  user_data_file = "${path.root}/userdata/windows-userdata.ps1"
}

build {
  sources = ["source.amazon-ebs.windows"]

  # Install dependencies (Chocolatey, AWS CLI, etc.)
  provisioner "powershell" {
    script = "./scripts/00-Install-Dependencies.ps1"
  }

  # Install Java
  provisioner "powershell" {
    script = "./scripts/01-Install-Java.ps1"
  }

  # Install Tomcat
  provisioner "powershell" {
    script = "./scripts/02-Install-Tomcat.ps1"
  }

  # Deploy Spectrum applications
  provisioner "powershell" {
    script = "./scripts/03-Install-Spectrum.ps1"
    environment_vars = [
      "SPECTRUM_VERSION=${var.spectrum_version}",
      "SPECTRUM_S3_BUCKET=${var.spectrum_s3_bucket}",
      "SPECTRUM_S3_PATH=${var.spectrum_s3_path}",
      "SPECTRUM_PACKAGE_URL=${var.spectrum_package_url}",
      "SPECTRUM_PACKAGE_PATH=${var.spectrum_package_path}",
      "AWS_REGION=${var.region}",
    ]
  }

  # Upload templates for configuration
  provisioner "file" {
    source      = "./files/templates/context.xml.tpl"
    destination = "C:\\Windows\\Temp\\context.xml.tpl"
  }

  provisioner "file" {
    source      = "./files/templates/appConfig.js.tpl"
    destination = "C:\\Windows\\Temp\\appConfig.js.tpl"
  }

  provisioner "file" {
    source      = "./files/templates/setenv.bat.tpl"
    destination = "C:\\Windows\\Temp\\setenv.bat.tpl"
  }

  # Configure Tomcat (JVM, Windows Service, etc.)
  provisioner "powershell" {
    script = "./scripts/04-Configure-Tomcat.ps1"
    environment_vars = [
      "JVM_XMX=${var.jvm_xmx}",
      "JVM_XMS=${var.jvm_xms}",
    ]
  }

  # Configure Spectrum (JDBC, database, frontend)
  provisioner "powershell" {
    script = "./scripts/05-Configure-Spectrum.ps1"
    environment_vars = [
      "DB_TYPE=${var.db_type}",
      "DB_HOST=${local.db_host}",
      "DB_USER=${local.db_user}",
      "DB_PASSWORD=${local.db_password}",
      "DB_NAME=${var.db_name}",
      "SERVER_IP=${var.server_ip}",
    ]
  }

  # Security hardening
  provisioner "powershell" {
    script = "./scripts/06-Hardening.ps1"
  }

  # Start Tomcat service (service name matches guide: Tomcat10)
  provisioner "powershell" {
    inline = [
      "Start-Service Tomcat10",
      "Start-Sleep -Seconds 10",
    ]
  }

  # Cleanup before finalizing AMI
  provisioner "powershell" {
    script = "./scripts/99-Cleanup.ps1"
  }

  # Add version metadata to AMI
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}

