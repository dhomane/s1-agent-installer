# Define the path to the SentinelOne agent MSI file or the download URL
$msiPath = "https://github.com/dhomane/s1-agent-installer/releases/download/latest/s1-agent-latest.msi"  # URL to MSI file

# Get the SentinelOne site token from an environment variable
$siteToken = $env:SENTINEL_TOKEN

if (-not $siteToken) {
    Write-Host "ERROR: The environment variable 'SENTINEL_TOKEN' is not set." -ForegroundColor Red
    exit 1
}

# Install SentinelOne agent
if ($msiPath -match "^https?://") {
    # Download the MSI file if it's from a URL
    $downloadPath = "$env:TEMP\SentinelOneAgent.msi"
    Write-Host "Downloading SentinelOne agent from $msiPath..."
    try {
        Invoke-WebRequest -Uri $msiPath -OutFile $downloadPath -ErrorAction Stop
        $msiPath = $downloadPath
    } catch {
        Write-Host "ERROR: Failed to download the SentinelOne agent. $_" -ForegroundColor Red
        exit 1
    }
}

# Execute the installation
Write-Host "Installing SentinelOne agent..."
$installArguments = "/i `"$msiPath`" /quiet TOKEN=$siteToken"
Start-Process -FilePath "msiexec.exe" -ArgumentList $installArguments -Wait

# Check if the installation was successful
$installPath = "C:\Program Files\SentinelOne"
$sentinelCtlPath = Get-ChildItem -Path $installPath -Recurse -Filter "SentinelCtl.exe" -ErrorAction SilentlyContinue

if ($sentinelCtlPath) {
    Write-Host "SentinelOne agent installed successfully."
    & $sentinelCtlPath.FullName agent_id
} else {
    Write-Host "SentinelOne agent installation failed."
}
