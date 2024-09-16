# Define the path to the SentinelOne agent EXE file or the download URL
$exePath = "https://github.com/dhomane/s1-agent-installer/releases/download/latest/s1-agent-latest.exe"  # URL to EXE file

# Get the SentinelOne site token from an environment variable
$siteToken = $env:SENTINEL_TOKEN

if (-not $siteToken) {
    Write-Host "ERROR: The environment variable 'SENTINEL_TOKEN' is not set." -ForegroundColor Red
    exit 1
}

# Install SentinelOne agent
if ($exePath -match "^https?://") {
    # Download the EXE file if it's from a URL
    $downloadPath = "$env:TEMP\SentinelOneAgent.exe"
    Write-Host "Downloading SentinelOne agent from $exePath..."
    Invoke-WebRequest -Uri $exePath -OutFile $downloadPath
    $exePath = $downloadPath
}

# Execute the installation
Write-Host "Installing SentinelOne agent..."
Start-Process -FilePath $exePath -ArgumentList "-q", "-t", $siteToken -Wait

# Check if the installation was successful
$installPath = "C:\Program Files\SentinelOne"
$sentinelCtlPath = Get-ChildItem -Path $installPath -Recurse -Filter "SentinelCtl.exe" -ErrorAction SilentlyContinue

if ($sentinelCtlPath) {
    Write-Host "SentinelOne agent installed successfully."
    & $sentinelCtlPath.FullName agent_id
} else {
    Write-Host "SentinelOne agent installation failed."
}
