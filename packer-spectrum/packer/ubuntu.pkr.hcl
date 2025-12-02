packer {
  required_plugins {
    amazon = {
      version = "~> 1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Variable definitions
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
  description = "Subnet ID (should be public for SSH access during build)"
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

variable "spectrum_package_url" {
  type        = string
  default     = ""
  description = "URL to download Spectrum package (optional if using local file)"
}

variable "spectrum_package_path" {
  type        = string
  default     = ""
  description = "Local path to Spectrum package (optional if using URL)"
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
  default     = "localhost"
  description = "Database server hostname or IP address"
}

variable "db_user" {
  type        = string
  default     = "spectrum"
  description = "Database username"
}

variable "db_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Database password"
}

variable "db_name" {
  type        = string
  default     = "kioskmgr"
  description = "Database name"
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

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "spectrum-tomcat-${local.timestamp}"
  instance_type = "t3.large"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  imds_support                = "v2.0"
  ssh_username                = "ubuntu"
  ssh_timeout                 = "10m"
  ssh_handshake_attempts      = 30
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  encrypt_boot                = true
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  # Install dependencies
  provisioner "shell" {
    script = "./scripts/00-install-dependencies.sh"
  }

  # Install Docker
  provisioner "shell" {
    script = "./scripts/01-install-docker.sh"
  }

  # Install Java
  provisioner "shell" {
    script = "./scripts/02-install-java.sh"
  }

  # Install Tomcat
  provisioner "shell" {
    script = "./scripts/03-install-tomcat.sh"
  }

  # Deploy Spectrum applications
  provisioner "shell" {
    script = "./scripts/04-install-spectrum.sh"
    environment_vars = [
      "SPECTRUM_VERSION=${var.spectrum_version}",
      "SPECTRUM_PACKAGE_URL=${var.spectrum_package_url}",
      "SPECTRUM_PACKAGE_PATH=${var.spectrum_package_path}",
    ]
  }

  # Upload templates for configuration
  provisioner "file" {
    source      = "./files/templates/context.xml.tpl"
    destination = "/tmp/context.xml.tpl"
  }

  provisioner "file" {
    source      = "./files/templates/appConfig.js.tpl"
    destination = "/tmp/appConfig.js.tpl"
  }

  provisioner "file" {
    source      = "./files/templates/setenv.sh.tpl"
    destination = "/tmp/setenv.sh.tpl"
  }

  # Upload Tomcat configuration overrides
  provisioner "file" {
    source      = "./files/conf/logging.properties"
    destination = "/tmp/tomcat-conf/logging.properties"
  }

  provisioner "file" {
    source      = "./files/conf/catalina.properties"
    destination = "/tmp/tomcat-conf/catalina.properties"
  }

  provisioner "file" {
    source      = "./files/conf/jvm.options"
    destination = "/tmp/tomcat-conf/jvm.options"
  }

  # Configure Tomcat (JVM, systemd, logging, etc.)
  provisioner "shell" {
    script = "./scripts/05-configure-tomcat.sh"
    environment_vars = [
      "JVM_XMX=${var.jvm_xmx}",
      "JVM_XMS=${var.jvm_xms}",
    ]
  }

  # Configure Spectrum (JDBC, database, frontend)
  provisioner "shell" {
    script = "./scripts/06-configure-spectrum.sh"
    environment_vars = [
      "DB_TYPE=${var.db_type}",
      "DB_HOST=${var.db_host}",
      "DB_USER=${var.db_user}",
      "DB_PASSWORD=${var.db_password}",
      "DB_NAME=${var.db_name}",
      "SERVER_IP=${var.server_ip}",
    ]
  }

  # Apply setenv.sh template
  provisioner "shell" {
    script = "./scripts/apply-setenv-template.sh"
    environment_vars = [
      "JVM_XMX=${var.jvm_xmx}",
      "JVM_XMS=${var.jvm_xms}",
    ]
  }

  # Security hardening
  provisioner "shell" {
    script = "./scripts/07-hardening.sh"
  }

  # Start Tomcat service (service file was created in install-tomcat.sh)
  provisioner "shell" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable tomcat",
      "sudo systemctl start tomcat",
      "sleep 5",
    ]
  }

  # Cleanup before finalizing AMI
  provisioner "shell" {
    script = "./scripts/99-cleanup.sh"
  }

  # Add version metadata to AMI
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
