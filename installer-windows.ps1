# Define the path to the SentinelOne agent EXE file or the download URL
$exePath = "https://github.com/dhomane/s1-agent-installer/releases/download/latest/s1-agent-latest.exe"  # Local path to EXE file


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
$exePath -q -t $siteToken


# Check if the installation was successful
$installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "SentinelOne*" }
if ($installed) {
    Write-Host "SentinelOne agent installed successfully."
    Get-ChildItem -Path "C:/Program Files/SentinelOne/" -Recurse -Filter "SentinelCtl.exe" | ForEach-Object { & $_.FullName agent_id }

} else {
    Write-Host "SentinelOne agent installation failed."
}