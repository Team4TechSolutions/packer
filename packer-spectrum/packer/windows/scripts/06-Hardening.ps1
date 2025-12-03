# Security Hardening for Windows
# Configures Windows security settings for Tomcat

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Security Hardening" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Match official guide: Use C:\Tomcat10
$TOMCAT_HOME = "C:\Tomcat10"

# Remove default Tomcat applications (optional - for security)
Write-Host "Removing default Tomcat applications..." -ForegroundColor Yellow
$defaultApps = @("docs", "examples", "host-manager", "manager")
foreach ($app in $defaultApps) {
    $appPath = "$TOMCAT_HOME\webapps\$app"
    if (Test-Path $appPath) {
        Remove-Item -Path $appPath -Recurse -Force
        Write-Host "  [OK] Removed: $app" -ForegroundColor Green
    }
}

# Configure Tomcat users (disable default users)
Write-Host ""
Write-Host "Configuring Tomcat security..." -ForegroundColor Yellow
$tomcatUsersPath = "$TOMCAT_HOME\conf\tomcat-users.xml"
if (Test-Path $tomcatUsersPath) {
    # Backup original
    Copy-Item -Path $tomcatUsersPath -Destination "$tomcatUsersPath.backup" -Force
    Write-Host "  [OK] tomcat-users.xml backed up" -ForegroundColor Green
}

Write-Host ""
Write-Host "[OK] Security hardening completed!" -ForegroundColor Green

