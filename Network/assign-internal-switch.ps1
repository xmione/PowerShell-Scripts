# .\assign-internal-switch.ps1

# Assign a Static IP to the VM's Internal Adapter
$VMAdapterName = "vEthernet (Internal)"  # VM's internal switch name
$VMIPAddress = "192.168.100.74"          # Static IP for VM
$VMSubnetMask = 24                       # Subnet mask for VM

# Check if the IP address exists for the VM
$existingVMIP = Get-NetIPAddress -InterfaceAlias $VMAdapterName -IPAddress $VMIPAddress -ErrorAction SilentlyContinue
if (-not $existingVMIP) {
    Write-Host "Assigning IP address $VMIPAddress to $VMAdapterName"
    New-NetIPAddress -InterfaceAlias $VMAdapterName -IPAddress $VMIPAddress -PrefixLength $VMSubnetMask
} else {
    Write-Host "VM adapter $VMAdapterName already has IP address $VMIPAddress."
}

# Enable ICS on the Host adapter for sharing internet (Host's Wi-Fi or Ethernet adapter)
$HostAdapterName = "vEthernet (Bridged Network)"  # Change to the name of your host adapter (Wi-Fi or Ethernet)
$HostAdapterIndex = (Get-NetAdapter -Name $HostAdapterName).ifIndex

# Enable ICS (Internet Connection Sharing) on the Host
$EnableICSCommand = "netsh interface ip set interface $HostAdapterIndex forwarding=enabled store=persistent"
Invoke-Expression $EnableICSCommand

Write-Host "ICS enabled on Host adapter ($HostAdapterName)."

Write-Host "VM adapter ($VMAdapterName) is configured with static IP and connected to the Internal Switch."
