param (
    [Parameter(Mandatory=$true, HelpMessage="Enter the version number (e.g., 2.0.0)")]
    [string]$Version
)

$ErrorActionPreference = "Stop"

# Setup Paths
$RepoDir = $PSScriptRoot
$UTSystemDir = (Resolve-Path "$RepoDir\..\System").Path
$ZipName = "WSUTComp_LGI_v$Version.zip"
$ZipPath = "$RepoDir\$ZipName"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Building WSUTComp LGI v$Version" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Clean old files
Write-Host "`n[1/5] Cleaning old build files..."
Remove-Item -Path "$UTSystemDir\WSUTComp.u" -ErrorAction SilentlyContinue
Remove-Item -Path "$UTSystemDir\WSUTComp.ucl" -ErrorAction SilentlyContinue
Remove-Item -Path "$UTSystemDir\WSUTComp.u.uz2" -ErrorAction SilentlyContinue

# 2. Compile Code
Write-Host "[2/5] Compiling source code..."
Set-Location -Path $UTSystemDir
.\ucc.exe make

if (-not (Test-Path "$UTSystemDir\WSUTComp.u")) {
    Write-Error "Compilation failed! WSUTComp.u was not created."
    exit 1
}

# 3. Compress & Generate Cache
Write-Host "`n[3/5] Compressing .u and generating cache (.ucl)..."
.\ucc.exe compress WSUTComp.u
.\ucc.exe exportcache WSUTComp.u

# 4. Create ZIP Archive
Write-Host "`n[4/5] Zipping files for distribution..."
if (Test-Path $ZipPath) { Remove-Item $ZipPath }
Compress-Archive -Path "$UTSystemDir\WSUTComp.u", "$UTSystemDir\WSUTComp.u.uz2", "$UTSystemDir\WSUTComp.ini", "$UTSystemDir\WSUTComp.ucl" -DestinationPath $ZipPath -Force
Write-Host "      Created: $ZipName" -ForegroundColor Green

# 5. Push to GitHub Releases
Write-Host "`n[5/5] Publishing release to GitHub..."
Set-Location -Path $RepoDir
gh release create "v$Version" $ZipPath --title "Wicked Sick UTComp LGI v$Version" --generate-notes

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host " Success! Release v$Version is live on GitHub." -ForegroundColor Green
Write-Host " Link: https://github.com/ruben-chapa/WSUTComp/releases" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
