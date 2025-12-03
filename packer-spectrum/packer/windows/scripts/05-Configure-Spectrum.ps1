# Configure Spectrum Application for Windows
# Installs JDBC drivers and configures database connection

param(
    [string]$DB_TYPE = $env:DB_TYPE,
    [string]$DB_HOST = $env:DB_HOST,
    [string]$DB_USER = $env:DB_USER,
    [string]$DB_PASSWORD = $env:DB_PASSWORD,
    [string]$DB_NAME = $env:DB_NAME,
    [string]$SERVER_IP = $env:SERVER_IP
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Configuring Spectrum" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Match official guide: Use C:\Tomcat10
$TOMCAT_HOME = "C:\Tomcat10"

if (-not $DB_TYPE) { $DB_TYPE = "mysql" }
if (-not $DB_HOST) { $DB_HOST = "localhost" }
if (-not $DB_USER) { $DB_USER = "spectrum" }
if (-not $DB_NAME) { $DB_NAME = "kioskmgr" }
if (-not $SERVER_IP) { $SERVER_IP = "localhost" }

# Step 1: Install JDBC Driver
Write-Host "Installing JDBC driver for $DB_TYPE..." -ForegroundColor Yellow

$jdbcLibPath = "$TOMCAT_HOME\lib"

if ($DB_TYPE -eq "sqlserver") {
    Write-Host "Downloading Microsoft SQL Server JDBC driver..." -ForegroundColor Yellow
    $mssqlUrl = "https://go.microsoft.com/fwlink/?linkid=2222954"
    $mssqlZip = "$env:TEMP\mssql-jdbc.zip"
    Invoke-WebRequest -Uri $mssqlUrl -OutFile $mssqlZip -UseBasicParsing
    Expand-Archive -Path $mssqlZip -DestinationPath "$env:TEMP\mssql-jdbc" -Force
    $jdbcJar = Get-ChildItem -Path "$env:TEMP\mssql-jdbc" -Filter "mssql-jdbc-*.jar" -Recurse | Select-Object -First 1
    if ($jdbcJar) {
        Copy-Item -Path $jdbcJar.FullName -Destination $jdbcLibPath -Force
        Write-Host "[OK] SQL Server JDBC driver installed" -ForegroundColor Green
    }
    Remove-Item -Path "$env:TEMP\mssql-jdbc" -Recurse -Force
    Remove-Item -Path $mssqlZip -Force
} elseif ($DB_TYPE -eq "mysql") {
    Write-Host "Downloading MySQL Connector..." -ForegroundColor Yellow
    # Use MySQL Connector/J 8.0.33 from Maven Central (alternative: use 8.0.28 which is more stable)
    $mysqlVersion = "8.0.33"
    $mysqlUrl = "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/$mysqlVersion/mysql-connector-j-$mysqlVersion.jar"
    $mysqlJar = "$jdbcLibPath\mysql-connector-j-$mysqlVersion.jar"
    
    try {
        Invoke-WebRequest -Uri $mysqlUrl -OutFile $mysqlJar -UseBasicParsing -ErrorAction Stop
        Write-Host "[OK] MySQL Connector installed" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Failed to download MySQL Connector $mysqlVersion, trying alternative version..." -ForegroundColor Yellow
        # Try alternative version
        $mysqlVersion = "8.0.28"
        $mysqlUrl = "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/$mysqlVersion/mysql-connector-j-$mysqlVersion.jar"
        $mysqlJar = "$jdbcLibPath\mysql-connector-j-$mysqlVersion.jar"
        try {
            Invoke-WebRequest -Uri $mysqlUrl -OutFile $mysqlJar -UseBasicParsing -ErrorAction Stop
            Write-Host "[OK] MySQL Connector $mysqlVersion installed" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to download MySQL Connector: $_" -ForegroundColor Red
            Write-Host "[WARN] Continuing without MySQL Connector - you may need to install it manually" -ForegroundColor Yellow
        }
    }
}

# Step 2: Configure Database Connection
Write-Host ""
Write-Host "Configuring database connection in context.xml..." -ForegroundColor Yellow

if ($DB_TYPE -eq "sqlserver") {
    $DB_URL = "jdbc:sqlserver://${DB_HOST}:1433;databaseName=${DB_NAME};encrypt=false"
    $DB_DRIVER = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
} elseif ($DB_TYPE -eq "mysql") {
    # Escape & for XML
    $DB_URL = "jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=false&amp;serverTimezone=UTC"
    $DB_DRIVER = "com.mysql.cj.jdbc.Driver"
}

$contextXmlPath = "$TOMCAT_HOME\conf\context.xml"
$contextTemplate = "C:\Windows\Temp\context.xml.tpl"

if (Test-Path $contextTemplate) {
    Write-Host "Using context.xml template..." -ForegroundColor Yellow
    $contextContent = Get-Content $contextTemplate -Raw
    $contextContent = $contextContent -replace '\{\{DB_USER\}\}', $DB_USER
    $contextContent = $contextContent -replace '\{\{DB_PASSWORD\}\}', $DB_PASSWORD
    $contextContent = $contextContent -replace '\{\{DB_DRIVER\}\}', $DB_DRIVER
    $contextContent = $contextContent -replace '\{\{DB_URL\}\}', $DB_URL
    
    # Backup original
    Copy-Item -Path $contextXmlPath -Destination "$contextXmlPath.backup" -Force
    Set-Content -Path $contextXmlPath -Value $contextContent
    Write-Host "[OK] Database connection configured" -ForegroundColor Green
} else {
    Write-Host "[WARN] Template not found, using default configuration" -ForegroundColor Yellow
}

# Step 3: Configure Frontend appConfig.js
Write-Host ""
Write-Host "Configuring frontend appConfig.js..." -ForegroundColor Yellow

$appConfigPath = "$TOMCAT_HOME\webapps\spectrum\appConfig.js"
$appConfigTemplate = "C:\Windows\Temp\appConfig.js.tpl"

if (Test-Path $appConfigPath) {
    if (Test-Path $appConfigTemplate) {
        Write-Host "Using appConfig.js template..." -ForegroundColor Yellow
        $appConfigContent = Get-Content $appConfigTemplate -Raw
        $appConfigContent = $appConfigContent -replace '\{\{SERVER_IP\}\}', $SERVER_IP
        Set-Content -Path $appConfigPath -Value $appConfigContent
        Write-Host "[OK] Frontend configuration updated" -ForegroundColor Green
    } else {
        # Fallback: use sed-like replacement
        $appConfigContent = Get-Content $appConfigPath -Raw
        $appConfigContent = $appConfigContent -replace 'http://[^:]+:8080/spectrum-server', "http://${SERVER_IP}:8080/spectrum-server"
        Set-Content -Path $appConfigPath -Value $appConfigContent
        Write-Host "[OK] Frontend configuration updated" -ForegroundColor Green
    }
} else {
    Write-Host "[WARN] appConfig.js not found (frontend may not be deployed yet)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[OK] Spectrum configuration completed!" -ForegroundColor Green

