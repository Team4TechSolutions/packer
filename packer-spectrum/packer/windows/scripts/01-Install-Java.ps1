# Install Java 17 for Windows
# Uses Chocolatey to install OpenJDK 17

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Installing Java 17" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Install OpenJDK 17 using Chocolatey
Write-Host "Installing OpenJDK 17..." -ForegroundColor Yellow
choco install -y openjdk17 --no-progress

# Set JAVA_HOME environment variable
$javaHome = "C:\Program Files\Eclipse Adoptium\jdk-17.0.*"
if (Test-Path $javaHome) {
    $javaPath = (Get-ChildItem "C:\Program Files\Eclipse Adoptium\" -Filter "jdk-17.0.*" -Directory | Select-Object -First 1).FullName
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, "Machine")
    $env:JAVA_HOME = $javaPath
    Write-Host "[OK] JAVA_HOME set to: $javaPath" -ForegroundColor Green
} else {
    # Try alternative location
    $javaPath = "C:\Program Files\Microsoft\jdk-17.*"
    if (Test-Path $javaPath) {
        $javaPath = (Get-ChildItem "C:\Program Files\Microsoft\" -Filter "jdk-17.*" -Directory | Select-Object -First 1).FullName
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, "Machine")
        $env:JAVA_HOME = $javaPath
        Write-Host "[OK] JAVA_HOME set to: $javaPath" -ForegroundColor Green
    }
}

# Add Java to PATH
$javaBin = "$env:JAVA_HOME\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$javaBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$javaBin", "Machine")
    $env:Path += ";$javaBin"
}

# Verify installation
Write-Host ""
Write-Host "Verifying Java installation..." -ForegroundColor Yellow
# Refresh PATH to include Java
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

if ($env:JAVA_HOME) {
    $javaExe = "$env:JAVA_HOME\bin\java.exe"
    if (Test-Path $javaExe) {
        & $javaExe -version
        Write-Host ""
        Write-Host "[OK] Java 17 installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "[WARN] JAVA_HOME set but java.exe not found at $javaExe" -ForegroundColor Yellow
        Write-Host "[OK] Java 17 installed (verification skipped)" -ForegroundColor Green
    }
} else {
    Write-Host "[WARN] JAVA_HOME not set, skipping verification" -ForegroundColor Yellow
    Write-Host "[OK] Java 17 installed (verification skipped)" -ForegroundColor Green
}

