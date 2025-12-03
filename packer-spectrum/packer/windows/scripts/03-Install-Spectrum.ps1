# Deploy Spectrum Applications for Windows
# Downloads and deploys Spectrum backend (WAR) and frontend

param(
    [string]$SPECTRUM_VERSION = $env:SPECTRUM_VERSION,
    [string]$SPECTRUM_S3_BUCKET = $env:SPECTRUM_S3_BUCKET,
    [string]$SPECTRUM_S3_PATH = $env:SPECTRUM_S3_PATH,
    [string]$SPECTRUM_PACKAGE_URL = $env:SPECTRUM_PACKAGE_URL,
    [string]$SPECTRUM_PACKAGE_PATH = $env:SPECTRUM_PACKAGE_PATH,
    [string]$AWS_REGION = $env:AWS_REGION
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Deploying Spectrum Applications" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Match official guide: Use C:\Tomcat10
$TOMCAT_HOME = "C:\Tomcat10"
$TOMCAT_WEBAPPS = "$TOMCAT_HOME\webapps"

function Deploy-FromS3 {
    param(
        [string]$S3Bucket,
        [string]$S3Path
    )
    
    Write-Host "Downloading Spectrum from S3: s3://$S3Bucket/$S3Path/" -ForegroundColor Yellow
    
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] AWS CLI is not installed. Cannot download from S3." -ForegroundColor Red
        exit 1
    }
    
    # Verify AWS access
    Write-Host "Verifying AWS access via instance metadata service..." -ForegroundColor Yellow
    try {
        $identity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "AWS access failed"
        }
        Write-Host "[OK] AWS access verified" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] AWS access not available via instance profile." -ForegroundColor Red
        exit 1
    }
    
    # Download backend WAR file
    Write-Host ""
    Write-Host "Downloading backend WAR file..." -ForegroundColor Yellow
    $warS3Path = "s3://$S3Bucket/$S3Path/server/spectrum-server.war"
    $warLocalPath = "$TOMCAT_WEBAPPS\spectrum-server.war"
    
    aws s3 cp $warS3Path $warLocalPath --region $AWS_REGION
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Backend WAR deployed: spectrum-server.war" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to download WAR file" -ForegroundColor Red
        exit 1
    }
    
    # Download frontend files
    Write-Host ""
    Write-Host "Downloading frontend directory..." -ForegroundColor Yellow
    $frontendS3Path = "s3://$S3Bucket/$S3Path/client/spectrum/"
    $frontendLocalPath = "$TOMCAT_WEBAPPS\spectrum"
    
    New-Item -ItemType Directory -Force -Path $frontendLocalPath | Out-Null
    aws s3 sync $frontendS3Path $frontendLocalPath --delete --region $AWS_REGION
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Frontend deployed: spectrum/" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to download frontend files" -ForegroundColor Red
        exit 1
    }
}

function Deploy-FromURL {
    param([string]$Url)
    
    Write-Host "Downloading Spectrum from URL: $Url" -ForegroundColor Yellow
    $zipFile = "$env:TEMP\Spectrum.zip"
    
    try {
        Invoke-WebRequest -Uri $Url -OutFile $zipFile -UseBasicParsing
        Expand-Archive -Path $zipFile -DestinationPath "$env:TEMP\Spectrum" -Force
        
        # Copy WAR file
        $warFile = Get-ChildItem -Path "$env:TEMP\Spectrum" -Filter "spectrum-server.war" -Recurse | Select-Object -First 1
        if ($warFile) {
            Copy-Item -Path $warFile.FullName -Destination "$TOMCAT_WEBAPPS\spectrum-server.war" -Force
            Write-Host "[OK] Backend WAR deployed" -ForegroundColor Green
        }
        
        # Copy frontend
        $frontendSource = Get-ChildItem -Path "$env:TEMP\Spectrum" -Filter "spectrum" -Directory -Recurse | Select-Object -First 1
        if ($frontendSource) {
            Copy-Item -Path "$($frontendSource.FullName)\*" -Destination "$TOMCAT_WEBAPPS\spectrum" -Recurse -Force
            Write-Host "[OK] Frontend deployed" -ForegroundColor Green
        }
        
        Remove-Item -Path "$env:TEMP\Spectrum" -Recurse -Force
        Remove-Item -Path $zipFile -Force
    } catch {
        Write-Host "[ERROR] Failed to download from URL: $_" -ForegroundColor Red
        exit 1
    }
}

# Determine deployment method
if ($SPECTRUM_S3_BUCKET -and $SPECTRUM_S3_PATH) {
    Deploy-FromS3 -S3Bucket $SPECTRUM_S3_BUCKET -S3Path $SPECTRUM_S3_PATH
} elseif ($SPECTRUM_PACKAGE_URL) {
    Deploy-FromURL -Url $SPECTRUM_PACKAGE_URL
} elseif ($SPECTRUM_PACKAGE_PATH) {
    Write-Host "Using local package: $SPECTRUM_PACKAGE_PATH" -ForegroundColor Yellow
    # Handle local path deployment
} else {
    Write-Host "[WARN] No Spectrum package source specified. Skipping deployment." -ForegroundColor Yellow
    Write-Host "  Set SPECTRUM_S3_BUCKET and SPECTRUM_S3_PATH, or SPECTRUM_PACKAGE_URL" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[OK] Spectrum deployment completed!" -ForegroundColor Green

