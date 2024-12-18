# .\create-internal-switch.ps1
# Check if the internal switch exists
$SwitchName = "Internal"
$existingSwitch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if (-not $existingSwitch) {
    Write-Host "Creating Internal Switch: $SwitchName"
    New-VMSwitch -Name $SwitchName -SwitchType Internal
} else {
    Write-Host "Internal Switch $SwitchName already exists."
}
