<powershell>

# Simple, robust WinRM setup for Packer (HTTP / 5985)
$ErrorActionPreference = "Continue"

Write-Host "===== User data: starting WinRM configuration ====="

# 1. Make sure EC2Launch v2 can run user-data scripts (Windows 2022)
try {
    Write-Host "Enabling EC2Launch user-data execution..."
    New-Item -Path "HKLM:\SOFTWARE\Amazon\EC2Launch" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\EC2Launch" -Name "RunUserDataScripts" -Value 1 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\EC2Launch" -Name "ExecuteUserData"     -Value 1 -Force
} catch {
    Write-Host "WARNING: Failed to set EC2Launch registry keys: $_"
}

# 2. Relax execution policy so our script can run fully
try {
    Write-Host "Setting execution policy..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Set-ExecutionPolicy RemoteSigned -Force
} catch {
    Write-Host "WARNING: Failed to set execution policy: $_"
}

# 3. Put network profile to Private so WinRM isn’t blocked
try {
    Write-Host "Setting network profile to Private..."
    $profile = Get-NetConnectionProfile | Where-Object {$_.NetworkCategory -ne "Private"} | Select-Object -First 1
    if ($profile) {
        Set-NetConnectionProfile -Name $profile.Name -NetworkCategory Private
    }
} catch {
    Write-Host "WARNING: Failed to set network profile: $_"
}

# 4. Enable WinRM and configure HTTP listener on 5985
try {
    Write-Host "Enabling WinRM and configuring HTTP listener..."

    Enable-PSRemoting -Force -SkipNetworkProfileCheck

    winrm quickconfig -q -force

    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service        '@{AllowUnencrypted="true"}'

    # Clean + recreate listener
    winrm delete winrm/config/Listener?Address=*+Transport=HTTP 2>$null
    winrm create winrm/config/Listener?Address=*+Transport=HTTP
} catch {
    Write-Host "ERROR: WinRM configuration failed: $_"
}

# 5. Open firewall for WinRM HTTP
try {
    Write-Host "Configuring firewall for port 5985..."
    netsh advfirewall firewall delete rule name="WinRM-HTTP" 2>$null
    netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in action=allow protocol=TCP localport=5985
} catch {
    Write-Host "WARNING: Failed to update firewall: $_"
}

# 6. Ensure WinRM service is running
try {
    Write-Host "Ensuring WinRM service is running..."
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service WinRM -ErrorAction SilentlyContinue
} catch {
    Write-Host "WARNING: Failed to start WinRM service: $_"
}

Write-Host "===== User data: WinRM HTTP (5985) setup complete ====="

</powershell>
