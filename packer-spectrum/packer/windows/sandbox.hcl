# Sandbox Environment Configuration - Windows

# AWS Infrastructure
region = "ca-central-1"
vpc_id = "vpc-04260fe320f45b2e5"
subnet_id = "subnet-074e17391bcc381df"
account = "891377304437"

# IAM Instance Profile for S3 access during build
iam_instance_profile_name = "packer-s3-role"

# Spectrum Application
spectrum_version = "5.9.0"

# Option 1: Download from S3 bucket (configured)
spectrum_s3_bucket = "warfilefortestspectrum"
spectrum_s3_path = "5.9.0"

# Option 2: Download from HTTP/HTTPS URL (ZIP file) - uncomment if needed
# spectrum_package_url = "https://example.com/SpectrumV5.9.0.zip"

# Option 3: Use local path - uncomment if needed
# spectrum_package_path = "C:\\path\\to\\SpectrumV5.9.0.zip"

# Database Configuration
db_type = "mysql"  # or "sqlserver"
db_name = "kioskmgr"

# Database credentials from AWS Parameter Store (recommended for security)
# Create these parameters in AWS Systems Manager Parameter Store:
# - /spectrum/sandbox/db-host
# - /spectrum/sandbox/db-user
# - /spectrum/sandbox/db-password (use SecureString type)
ssm_db_host_path = "/spectrum/sandbox/db-host"
ssm_db_user_path = "/spectrum/sandbox/db-user"
ssm_db_password_path = "/spectrum/sandbox/db-password"

# Alternative: Direct values (NOT RECOMMENDED - will be committed to git)
# db_host = "database-1.cdq6ga82mq0v.ca-central-1.rds.amazonaws.com"
# db_user = "admin"
# db_password = "welcome1"

# Server Configuration
server_ip = "sandbox-server.example.com"  # Change to your sandbox server

# JVM Configuration (optional - defaults shown)
jvm_xmx = "2g"
jvm_xms = "1g"

