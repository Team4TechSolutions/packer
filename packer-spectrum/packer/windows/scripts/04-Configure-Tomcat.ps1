# Configure Tomcat for Windows
# Sets up JVM options, Windows Service, and environment

param(
    [string]$JVM_XMX = $env:JVM_XMX,
    [string]$JVM_XMS = $env:JVM_XMS
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Configuring Tomcat" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Match official guide: Use C:\Tomcat10
$TOMCAT_HOME = "C:\Tomcat10"

if (-not $JVM_XMX) { $JVM_XMX = "2g" }
if (-not $JVM_XMS) { $JVM_XMS = "1g" }

Write-Host "JVM Configuration:" -ForegroundColor Yellow
Write-Host "  Xmx: $JVM_XMX" -ForegroundColor Yellow
Write-Host "  Xms: $JVM_XMS" -ForegroundColor Yellow
Write-Host ""

# Create setenv.bat from template if available
$setenvTemplate = "C:\Windows\Temp\setenv.bat.tpl"
$setenvBat = "$TOMCAT_HOME\bin\setenv.bat"

if (Test-Path $setenvTemplate) {
    Write-Host "Creating setenv.bat from template..." -ForegroundColor Yellow
    $content = Get-Content $setenvTemplate -Raw
    $content = $content -replace '\{\{JVM_XMX\}\}', $JVM_XMX
    $content = $content -replace '\{\{JVM_XMS\}\}', $JVM_XMS
    Set-Content -Path $setenvBat -Value $content
    Write-Host "[OK] setenv.bat created" -ForegroundColor Green
} else {
    # Create default setenv.bat
    Write-Host "Creating default setenv.bat..." -ForegroundColor Yellow
    $setenvContent = "@echo off`r`nset `"JAVA_OPTS=-Xmx$JVM_XMX -Xms$JVM_XMS -XX:+UseG1GC -Dfile.encoding=UTF-8`"`r`nset `"CATALINA_OPTS=-Dfile.encoding=UTF-8`""
    Set-Content -Path $setenvBat -Value $setenvContent -Encoding ASCII
    Write-Host "[OK] setenv.bat created" -ForegroundColor Green
}

# Configure Windows Firewall (if enabled)
Write-Host ""
Write-Host "Configuring Windows Firewall..." -ForegroundColor Yellow
try {
    New-NetFirewallRule -DisplayName "Tomcat HTTP" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null
    Write-Host "[OK] Firewall rule added for port 8080" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not configure firewall (may be disabled)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[OK] Tomcat configuration completed!" -ForegroundColor Green

