# Define parameters
$SdkDownloadUrl = "https://go.microsoft.com/fwlink/?linkid=2120843"  # Official Microsoft link for Windows 10 SDK
$SdkInstallPath = "C:\Program Files (x86)\Windows Kits\10"
$WorkingDir = "C:\repo\PowerShell-Scripts\DigitalSign"
$ExcelFile = "C:\repo\PowerShell-Scripts\DigitalSign\NumberToWord.xlsm"
$CertificatePath = "C:\repo\PowerShell-Scripts\DigitalSign\NumberToWord.pfx"
$CertificatePassword = $env:NumberToWordCertPass
$SignToolExe = Join-Path -Path $WorkingDir -ChildPath "signtool.exe"

# Check if signtool.exe already exists in the working directory
if (-Not (Test-Path -Path $SignToolExe)) {
    # If signtool.exe doesn't exist, download and install Windows SDK
    Write-Host "signtool.exe not found. Downloading and installing SDK..."

    # Download and install Windows 10 SDK
    $SdkInstallerPath = "C:\WindowsSDKInstaller.exe"
    Invoke-WebRequest -Uri $SdkDownloadUrl -OutFile $SdkInstallerPath
    Start-Process -FilePath $SdkInstallerPath -ArgumentList "/quiet" -Wait

    # Wait for the SDK installation to complete (adjust the wait time as needed)
    Start-Sleep -Seconds 300

    # Locate signtool.exe explicitly for x64 platform
    $SignToolPath = Get-ChildItem -Path "$SdkInstallPath\bin" -Recurse -Filter signtool.exe | Where-Object {
        $_.FullName -like "*x64*"
    } | Select-Object -First 1

    if ($null -eq $SignToolPath) {
        Write-Error "Could not locate a compatible x64 signtool.exe. Verify SDK installation."
        exit 1
    } else {
        Write-Host "Compatible signtool.exe located at $($SignToolPath.FullName)"
    }

    # Copy signtool.exe to the working directory
    Copy-Item -Path $SignToolPath.FullName -Destination $WorkingDir
} else {
    Write-Host "signtool.exe already exists in the working directory. Proceeding with signing."
}

# Use the copied or already present signtool.exe for signing
Start-Process -FilePath $SignToolExe -ArgumentList "/a", "/f", $CertificatePath, "/p", $CertificatePassword, $ExcelFile -Wait
