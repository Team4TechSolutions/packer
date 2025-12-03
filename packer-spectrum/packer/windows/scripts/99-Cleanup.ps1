# Cleanup Script for Windows
# Removes temporary files and prepares AMI for finalization

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Cleaning Up" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Clear temporary files
Write-Host "Clearing temporary files..." -ForegroundColor Yellow
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear Chocolatey cache
Write-Host "Clearing Chocolatey cache..." -ForegroundColor Yellow
choco cache remove --all -y 2>$null

# Clear Windows update cache (optional)
Write-Host "Clearing Windows update cache..." -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue

# Clear event logs
Write-Host "Clearing event logs..." -ForegroundColor Yellow
wevtutil el | ForEach-Object { wevtutil cl "$_" } 2>$null

# Defragment and optimize (optional - can be slow)
# Write-Host "Optimizing disk..." -ForegroundColor Yellow
# Optimize-Volume -DriveLetter C -Defrag -ReTrim -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[OK] Cleanup completed!" -ForegroundColor Green

