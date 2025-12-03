# Spectrum AMI Builder - Windows 10/Server 2022

This directory contains the Windows version of the Spectrum AMI builder, mirroring the Linux structure but adapted for Windows Server.

## Directory Structure

```
windows/
├── windows.pkr.hcl          # Main Packer configuration for Windows
├── sandbox.hcl              # Environment-specific variables (Windows)
├── scripts/                 # PowerShell installation scripts
│   ├── 00-Install-Dependencies.ps1
│   ├── 01-Install-Java.ps1
│   ├── 02-Install-Tomcat.ps1
│   ├── 03-Install-Spectrum.ps1
│   ├── 04-Configure-Tomcat.ps1
│   ├── 05-Configure-Spectrum.ps1
│   ├── 06-Hardening.ps1
│   └── 99-Cleanup.ps1
├── files/
│   ├── templates/           # Configuration templates
│   │   ├── context.xml.tpl
│   │   ├── appConfig.js.tpl
│   │   └── setenv.bat.tpl
│   └── conf/                # Tomcat configuration overrides
└── userdata/
    └── windows-userdata.ps1 # WinRM setup for Packer
```

## Key Differences from Linux Version

### 1. **Communication**
- **Linux**: Uses SSH
- **Windows**: Uses WinRM (Windows Remote Management)

### 2. **Scripts**
- **Linux**: Bash shell scripts (`.sh`)
- **Windows**: PowerShell scripts (`.ps1`)

### 3. **Package Management**
- **Linux**: `apt-get` (Ubuntu)
- **Windows**: Chocolatey package manager

### 4. **Service Management**
- **Linux**: systemd service files
- **Windows**: Windows Service (installed via `service.bat`)

### 5. **File Paths**
- **Linux**: `/opt/tomcat`
- **Windows**: `C:\Tomcat10` (matches official deployment guide)

### 6. **Environment Configuration**
- **Linux**: `setenv.sh`
- **Windows**: `setenv.bat`

### 7. **User Data**
- **Linux**: Cloud-init scripts
- **Windows**: PowerShell user data script

## Prerequisites

1. **Packer** installed on your build machine
2. **AWS Credentials** configured
3. **IAM Role** with S3 access (if using S3 for Spectrum package)
4. **VPC/Subnet** with public subnet for WinRM access

## Usage

### Build Windows AMI

```bash
cd windows
packer build -var-file=sandbox.hcl windows.pkr.hcl
```

### Using Makefile (if available)

```bash
make build-windows
```

## Configuration

Edit `sandbox.hcl` to configure:
- AWS region, VPC, subnet
- Database connection details
- Spectrum package source (S3, URL, or local path)
- JVM settings
- Server IP address

## Windows-Specific Notes

1. **WinRM Setup**: The user data script automatically configures WinRM for Packer communication
2. **Chocolatey**: Automatically installed if not present
3. **Java Installation**: Uses Chocolatey to install OpenJDK 17
4. **Tomcat Service**: Installed as Windows Service for automatic startup
5. **Firewall**: Automatically configured to allow port 8080

## Troubleshooting

### WinRM Connection Issues
- Ensure security group allows WinRM (port 5985/5986)
- Check that user data script executed successfully
- Verify WinRM service is running on the instance

### Service Installation
- Tomcat service is installed via `service.bat`
- Service name: "Tomcat10" (matches official guide)
- Can be managed via Services MMC or PowerShell: `Get-Service Tomcat10`

### Path Issues
- All paths use Windows format (`C:\...`)
- PowerShell handles path separators automatically

## File Comparison

| Linux File | Windows Equivalent |
|------------|-------------------|
| `ubuntu.pkr.hcl` | `windows.pkr.hcl` |
| `*.sh` scripts | `*.ps1` scripts |
| `setenv.sh.tpl` | `setenv.bat.tpl` |
| `tomcat.service` | Windows Service (via service.bat) |
| `/opt/tomcat` | `C:\Tomcat10` |

## Same Files (No Changes Needed)

- `context.xml.tpl` - Same for both platforms
- `appConfig.js.tpl` - Same for both platforms
- Configuration files in `files/conf/` - Same for both platforms

