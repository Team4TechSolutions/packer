# 00-Install-Dependencies.ps1
$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host "Installing system dependencies"
Write-Host "========================================="

# 1. Ensure TLS 1.2 is enabled (required for downloads)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Install Chocolatey if not already installed
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."

    Set-ExecutionPolicy Bypass -Scope Process -Force

    # Run Chocolatey installer in a separate scope to avoid variable conflicts
    & {
        $ErrorActionPreference = "Continue"
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    # Refresh PATH to include Chocolatey
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $chocoPath = "$env:ProgramData\chocolatey\bin"
    if (Test-Path $chocoPath) {
        $env:Path = "$env:Path;$chocoPath"
    }

    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey failed to install. Exiting."
        exit 1
    }

    Write-Host "Chocolatey installed."
} else {
    Write-Host "Chocolatey already installed."
}

# 3. Install basic tools
Write-Host "Installing tools (git, curl, unzip, 7zip)..."
choco install -y git curl unzip 7zip --no-progress

# 4. Install AWS CLI v2
Write-Host "Installing AWS CLI v2..."
if (-not (Get-Command aws.exe -ErrorAction SilentlyContinue)) {
    $installer = "$env:TEMP\AWSCLIV2.msi"
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $installer

    $awsInstallResult = Start-Process msiexec.exe -ArgumentList "/i `"$installer`" /quiet /norestart" -Wait -PassThru

    if ($awsInstallResult.ExitCode -ne 0 -and $awsInstallResult.ExitCode -ne 3010) {
        Write-Host "AWS CLI installer returned exit code $($awsInstallResult.ExitCode)"
    } else {
        Write-Host "AWS CLI installed."
    }

    Remove-Item $installer -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "AWS CLI already installed."
}

# 5. Verify AWS CLI
# Refresh PATH to include AWS CLI
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
if (Test-Path $awsCliPath) {
    $env:Path = "$env:Path;$awsCliPath"
}

try {
    # Try full path first, then PATH
    $awsExe = "$awsCliPath\aws.exe"
    if (Test-Path $awsExe) {
        $awsVersion = & $awsExe --version
        Write-Host "AWS CLI Version: $awsVersion"
    } elseif (Get-Command aws.exe -ErrorAction SilentlyContinue) {
        $awsVersion = aws --version
        Write-Host "AWS CLI Version: $awsVersion"
    } else {
        Write-Host "[WARN] Unable to verify AWS CLI (may need PATH refresh on next session)"
    }
} catch {
    Write-Host "[WARN] Unable to verify AWS CLI: $_"
}

Write-Host "========================================="
Write-Host "Dependencies installed successfully"
Write-Host "========================================="
