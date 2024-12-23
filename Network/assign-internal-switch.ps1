# ./assign-internal-switch.ps1
Clear-Host

# Define variables
$VMName = "Windows 11 dev environment"
$InternalSwitchName = "Internal"
$HostBridgedAdapterName = "vEthernet (Bridged Network)"
$HostInternalAdapterName = "vEthernet (Internal)"
$HostInternalIP = "192.168.100.74"
$VMIPAddress = "192.168.100.75"
$VMSubnetMask = 24
$DNS = "8.8.8.8"
$DefaultGateway = "192.168.100.1"

# Define username and password
$VMAdminUserName = $env:VMAdminUserName
$VMPassword = $env:VMPassword

# Check if username and password are set
if (-not $VMAdminUserName -or -not $VMPassword) {
    Write-Error "Environment variables for VM admin username or password are not set. Please set them and rerun the script."
    exit 1
}

# Create a PSCredential object
$SecurePassword = ConvertTo-SecureString $VMPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($VMAdminUserName, $SecurePassword)

Write-Host "VMAdminUserName: $VMAdminUserName"

# Create an Internal Switch if it doesn't exist
if (-not (Get-VMSwitch -Name $InternalSwitchName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating an internal virtual switch named '$InternalSwitchName'..."
    New-VMSwitch -Name $InternalSwitchName -SwitchType Internal
}

# Set a static IP address for the Host's internal adapter
Write-Output "Assigning static IP address to the host's internal adapter..."
$HostInternalAdapter = Get-NetAdapter | Where-Object { $_.Name -eq $HostInternalAdapterName }
if ($HostInternalAdapter) {
    # Check if the IP address is already configured
    $existingIP = Get-NetIPAddress -InterfaceAlias $HostInternalAdapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($existingIP) {
        Write-Output "Existing IP configuration found: $($existingIP.IPAddress). Removing it..."
        Remove-NetIPAddress -InterfaceAlias $HostInternalAdapter.Name -IPAddress $existingIP.IPAddress -Confirm:$false
    }

    # Assign new static IP
    New-NetIPAddress -InterfaceAlias $HostInternalAdapter.Name -IPAddress $HostInternalIP -PrefixLength $VMSubnetMask -DefaultGateway $DefaultGateway -AddressFamily IPv4 -ErrorAction SilentlyContinue
    Set-DnsClientServerAddress -InterfaceAlias $HostInternalAdapter.Name -ServerAddresses $DNS
} else {
    Write-Error "Host internal adapter '$HostInternalAdapterName' not found."
    exit 1
}

# Attach the VM to the Internal Switch
Write-Output "Attaching the VM '$VMName' to the internal switch..."
Connect-VMNetworkAdapter -VMName $VMName -SwitchName $InternalSwitchName

# Start the VM
Write-Output "Starting the VM '$VMName'..."
Start-VM -Name $VMName

# Wait for the VM to fully boot and become responsive
Write-Output "Waiting for VM to become responsive (idle check)..."
$VMState = (Get-VM -Name $VMName).State
$IsResponsive = $false

# Loop until the VM is responsive
while ($VMState -eq 'Running' -and !$IsResponsive) {
    Write-Output "VM is still starting. Checking responsiveness..."
    Start-Sleep -Seconds 10

    # Attempt to run a simple command (e.g., Get-Date) using PowerShell Direct
    try {
        $result = Invoke-Command -VMName $VMName -ScriptBlock { Get-Date } -Credential $Credential -ErrorAction Stop
        if ($result) {
            $IsResponsive = $true
            Write-Output "VM is now responsive and idle."
        }
    } catch {
        Write-Output "VM is not yet responsive. Retrying in 10 seconds..."
    }

    # Update VM state
    $VMState = (Get-VM -Name $VMName).State
}

Write-Output "VM is now responsive. Proceeding with static IP assignment."

# Assign a static IP to the VM's network adapter using PowerShell Direct
Write-Output "Assigning static IP to the VM's network adapter..."

Invoke-Command -VMName $VMName -ScriptBlock {
    param (
        $VMIPAddress,
        $VMSubnetMask,
        $DefaultGateway,
        $DNS
    )
    $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*Ethernet*" }
    if ($adapter) {
        Write-Output "Adapter found: $($adapter.Name)"
        
        # Remove existing IP configuration
        $existingIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($existingIP) {
            Remove-NetIPAddress -InterfaceAlias $adapter.Name -Confirm:$false
        }
        
        # Remove existing Default Gateway
        $existingGW = Get-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
        if ($existingGW) {
            Remove-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -Confirm:$false
        }
        
        # Assign the new static IP
        New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $VMIPAddress -PrefixLength $VMSubnetMask -DefaultGateway $DefaultGateway
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $DNS
        Write-Output "Static IP assigned to $($adapter.Name)."
    } else {
        Write-Error "Network adapter matching 'Ethernet*' not found."
    }
} -Credential $Credential -ArgumentList $VMIPAddress, $VMSubnetMask, $DefaultGateway, $DNS

Write-Output "Static IP assignment complete."

# Enable ICS on the host adapter (Bridged Network)
Write-Output "Enabling ICS on $HostBridgedAdapterName..."
$hostBridgedAdapter = Get-NetAdapter -Name $HostBridgedAdapterName -ErrorAction SilentlyContinue
$hostInternalAdapter = Get-NetAdapter -Name $HostInternalAdapterName -ErrorAction SilentlyContinue

if ($hostBridgedAdapter -and $hostInternalAdapter) {
    if ($hostBridgedAdapter.Status -eq 'Up') {
        Write-Output "Host adapter is up, enabling ICS..."
        # Enable ICS using netsh
        $shareCommand = "netsh interface set interface name=`"$HostBridgedAdapterName`" interface name=`"$HostInternalAdapterName`""
        Invoke-Expression $shareCommand
        Write-Output "ICS enabled on $HostBridgedAdapterName."
    } else {
        Write-Error "Host adapter is not up: $HostBridgedAdapterName."
    }
} else {
    Write-Error "Bridged Network adapter or Internal adapter not found."
}

Write-Output "VM adapter ($VMAdapterName) is configured with static IP and connected to the Internal Switch."
Write-Output "ICS configuration completed."
