# Windows 10/Server 2022 Setup Guide

This document explains the Windows version of the Spectrum AMI builder and how it differs from the Linux version.

## Directory Structure

The Windows setup mirrors the Linux structure but uses Windows-specific files:

```
packer/
├── ubuntu.pkr.hcl          # Linux AMI builder
├── windows/
│   ├── windows.pkr.hcl     # Windows AMI builder
│   ├── sandbox.hcl         # Environment config (Windows)
│   ├── Makefile            # Build commands
│   ├── README.md           # Windows-specific documentation
│   ├── scripts/            # PowerShell scripts
│   │   ├── 00-Install-Dependencies.ps1
│   │   ├── 01-Install-Java.ps1
│   │   ├── 02-Install-Tomcat.ps1
│   │   ├── 03-Install-Spectrum.ps1
│   │   ├── 04-Configure-Tomcat.ps1
│   │   ├── 05-Configure-Spectrum.ps1
│   │   ├── 06-Hardening.ps1
│   │   └── 99-Cleanup.ps1
│   ├── files/
│   │   └── templates/
│   │       ├── context.xml.tpl      # Same as Linux
│   │       ├── appConfig.js.tpl     # Same as Linux
│   │       └── setenv.bat.tpl       # Windows version (not .sh)
│   └── userdata/
│       └── windows-userdata.ps1      # WinRM setup
└── (Linux files...)
```

## Key Differences

### 1. Communication Protocol
- **Linux**: SSH (port 22)
- **Windows**: WinRM (port 5985/5986)

### 2. Script Language
- **Linux**: Bash (`.sh`)
- **Windows**: PowerShell (`.ps1`)

### 3. Package Manager
- **Linux**: `apt-get` (Ubuntu package manager)
- **Windows**: Chocolatey (Windows package manager)

### 4. Service Management
- **Linux**: systemd service file
- **Windows**: Windows Service (installed via `service.bat`)

### 5. Installation Paths
- **Linux**: `/opt/tomcat`
- **Windows**: `C:\Tomcat10` (matches official deployment guide)

### 6. Environment Configuration
- **Linux**: `setenv.sh`
- **Windows**: `setenv.bat`

### 7. AMI Source
- **Linux**: Ubuntu 22.04 LTS
- **Windows**: Windows Server 2022

## Building Windows AMI

### Prerequisites
1. Packer installed
2. AWS credentials configured
3. IAM role with S3 access (if using S3)
4. Public subnet for WinRM access

### Build Command

```bash
cd packer/windows
packer build -var-file=sandbox.hcl windows.pkr.hcl
```

Or using Makefile:

```bash
cd packer/windows
make build
```

## Configuration

Edit `windows/sandbox.hcl` to configure:
- AWS region, VPC, subnet
- Database connection (MySQL or SQL Server)
- Spectrum package source (S3, URL, or local path)
- JVM settings
- Server IP address

## Script Mapping

| Linux Script | Windows Script | Purpose |
|-------------|----------------|---------|
| `00-install-dependencies.sh` | `00-Install-Dependencies.ps1` | Install tools (Chocolatey, AWS CLI) |
| `01-install-docker.sh` | (Not needed) | Docker installation (optional) |
| `02-install-java.sh` | `01-Install-Java.ps1` | Install OpenJDK 17 |
| `03-install-tomcat.sh` | `02-Install-Tomcat.ps1` | Install Apache Tomcat |
| `04-install-spectrum.sh` | `03-Install-Spectrum.ps1` | Deploy Spectrum app |
| `05-configure-tomcat.sh` | `04-Configure-Tomcat.ps1` | Configure Tomcat |
| `06-configure-spectrum.sh` | `05-Configure-Spectrum.ps1` | Configure Spectrum |
| `07-hardening.sh` | `06-Hardening.ps1` | Security hardening |
| `99-cleanup.sh` | `99-Cleanup.ps1` | Cleanup before AMI finalization |

## Windows-Specific Features

1. **Chocolatey Installation**: Automatically installs if not present
2. **Windows Service**: Tomcat runs as a Windows Service
3. **WinRM Configuration**: Automatically configured via user data
4. **Windows Firewall**: Automatically configured for port 8080
5. **Path Handling**: All paths use Windows format

## Troubleshooting

### WinRM Connection Issues
- Ensure security group allows WinRM (ports 5985/5986)
- Check user data script executed successfully
- Verify WinRM service is running: `Get-Service WinRM`

### Service Management
```powershell
# Check service status
Get-Service Tomcat10

# Start/Stop service
Start-Service Tomcat10
Stop-Service Tomcat10

# View service logs
Get-EventLog -LogName Application -Source Tomcat
```

### Path Issues
- All paths use Windows format: `C:\Program Files\...`
- PowerShell handles path separators automatically
- Use `$env:ProgramFiles` for system paths

## Same Files (No Changes)

These files are identical between Linux and Windows:
- `context.xml.tpl` - Database connection template
- `appConfig.js.tpl` - Frontend configuration template
- Configuration files in `files/conf/` - Tomcat configuration

## Next Steps

1. Review `windows/sandbox.hcl` and update with your values
2. Ensure IAM role has S3 access (if using S3)
3. Build the AMI: `packer build -var-file=sandbox.hcl windows.pkr.hcl`
4. Launch an instance from the AMI
5. Access Spectrum at `http://<instance-ip>:8080/spectrum/`

