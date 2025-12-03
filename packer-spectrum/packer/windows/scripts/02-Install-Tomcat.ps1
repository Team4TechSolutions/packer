# Install Apache Tomcat for Windows
# Downloads and installs Tomcat 10.1.20

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Installing Apache Tomcat" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$TOMCAT_VERSION = "10.1.20"
$TOMCAT_MAJOR_VERSION = "10"
# Match official guide: Use C:\Tomcat10 instead of Program Files
$TOMCAT_HOME = "C:\Tomcat10"
$TOMCAT_USER = "tomcat"
$TOMCAT_PASSWORD = "Tomcat@2024!"

Write-Host "Tomcat Version: $TOMCAT_VERSION" -ForegroundColor Yellow
Write-Host "Installation Path: $TOMCAT_HOME" -ForegroundColor Yellow
Write-Host ""

# Create Tomcat directory
Write-Host "Creating Tomcat directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $TOMCAT_HOME | Out-Null

# Download Tomcat
Write-Host "Downloading Tomcat $TOMCAT_VERSION..." -ForegroundColor Yellow
$tomcatUrl = "https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR_VERSION/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION-windows-x64.zip"
$tomcatZip = "$env:TEMP\apache-tomcat-$TOMCAT_VERSION.zip"

try {
    Invoke-WebRequest -Uri $tomcatUrl -OutFile $tomcatZip -UseBasicParsing
    Write-Host "[OK] Tomcat downloaded" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to download Tomcat: $_" -ForegroundColor Red
    exit 1
}

# Extract Tomcat
Write-Host "Extracting Tomcat..." -ForegroundColor Yellow
Expand-Archive -Path $tomcatZip -DestinationPath "$env:TEMP" -Force
$extractedPath = "$env:TEMP\apache-tomcat-$TOMCAT_VERSION"
Copy-Item -Path "$extractedPath\*" -Destination $TOMCAT_HOME -Recurse -Force
Remove-Item -Path $extractedPath -Recurse -Force
Remove-Item -Path $tomcatZip -Force
Write-Host "[OK] Tomcat extracted" -ForegroundColor Green

# Create Tomcat service user (optional - can use existing user)
Write-Host ""
Write-Host "Setting up Tomcat service..." -ForegroundColor Yellow

# Set CATALINA_HOME environment variable (as per guide)
Write-Host "Setting CATALINA_HOME environment variable..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("CATALINA_HOME", $TOMCAT_HOME, "Machine")
$env:CATALINA_HOME = $TOMCAT_HOME
Write-Host "[OK] CATALINA_HOME set to: $TOMCAT_HOME" -ForegroundColor Green

# Install Tomcat as Windows Service using service.bat
# Match official guide: Service name is Tomcat10
$serviceScript = "$TOMCAT_HOME\bin\service.bat"
if (Test-Path $serviceScript) {
    # Install service (guide uses service name Tomcat10)
    & $serviceScript install Tomcat10
    Write-Host "[OK] Tomcat service installed as 'Tomcat10'" -ForegroundColor Green
    
    # Configure service to start automatically
    Set-Service -Name "Tomcat10" -StartupType Automatic
    Write-Host "[OK] Tomcat service configured for auto-start" -ForegroundColor Green
} else {
    Write-Host "[WARN] Service script not found - service may need manual installation" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[OK] Tomcat $TOMCAT_VERSION installed successfully at $TOMCAT_HOME" -ForegroundColor Green

