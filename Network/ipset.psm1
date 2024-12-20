<#
    Author  : Solomio S. Sisante
    Created : October 19, 2024
    FileName: ipset.psm1
    Purpose : Network Tools module to get and set IPv4 and IPv6 settings.

    Usage   : 

    Get-NetworkAdapterSettings

    Set-NetworkAdapterSettings -AdapterName "vEthernet (Bridged Network)" `
                                -IPv4Address "192.168.100.73" `
                                -SubnetMask 24 `
                                -Gateway "192.168.100.1" `
                                -PreferredDNS "8.8.8.8" `
                                -AlternateDNS $null `
                                -DnsOverHttpsIPv4 $false `
                                -IPv6Address "fe80::c80a:d920:24dd:3f05" ` # Removed the zone index
                                -IPv6PrefixLength 64 `
                                -IPv6Gateway $null `
                                -IPv6PreferredDNS $null `
                                -IPv6AlternateDNS $null `
                                -DnsOverHttpsIPv6 $false

#>

# Function to convert prefix length to subnet mask
function ConvertTo-SubnetMask {
    param (
        [int]$prefixLength
    )

    if ($prefixLength -lt 0 -or $prefixLength -gt 32) {
        throw "Prefix length must be between 0 and 32."
    }

    # Generate a binary subnet mask
    $binaryMask = ('1' * [int]$prefixLength).PadRight(32, '0')

    # Split into octets, convert to decimal, and join as a string
    $octets = $binaryMask -split '(.{8})' | Where-Object { $_ -ne '' }
    return ($octets | ForEach-Object { [convert]::ToInt32($_, 2) }) -join '.'
}

# Function to get the current IPv4 and IPv6 settings for all network adapters
function Get-NetworkAdapterSettings {

    # Retrieve all network adapters
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        $adapterName = $adapter.InterfaceAlias
        Write-Host "Adapter: $adapterName"
        
        # Get IPv4 settings
        $ipv4Info = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ipv4Info) {
            # Ensure PrefixLength is valid and not an array
            if ($ipv4Info.PrefixLength -is [int]) {
                $prefixLength = [int]$ipv4Info.PrefixLength
            } elseif ($ipv4Info.PrefixLength -is [object[]]) {
                $prefixLength = [int]$ipv4Info.PrefixLength[0]
            } elseif ($ipv4Info.PrefixLength -is [object]) {
                $prefixLength = [int]$ipv4Info.PrefixLength
            } else {
                throw "Invalid PrefixLength format: $($ipv4Info.PrefixLength)"
            }

            #$prefixLength=24
            $subnetMask = ConvertTo-SubnetMask -prefixLength $prefixLength
                
            Write-Host "PrefixLength Raw: $($ipv4Info.PrefixLength)"
            Write-Host "PrefixLength Processed: $prefixLength"

            # Check for IPv4 gateway
            $gatewayInfo = Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
            $gateway = if ($gatewayInfo) { $gatewayInfo.NextHop } else { "No gateway set" }
            $dnsInfo = Get-DnsClientServerAddress -InterfaceAlias $adapterName -AddressFamily IPv4
            $preferredDns = if ($dnsInfo) { $dnsInfo.ServerAddresses[0] } else { "No DNS set" }
            $alternateDns = if ($dnsInfo -and $dnsInfo.ServerAddresses.Count -gt 1) { $dnsInfo.ServerAddresses[1] } else { "No alternate DNS set" }
            
            # Check DNS over HTTPS for IPv4
            $dnsClientSettings = Get-DnsClient -InterfaceAlias $adapterName
            $dnsOverHttpsIPv4 = if ($dnsClientSettings.UseDnsOverHttps -eq $true) { "On" } else { "Off" }

            Write-Host "IPv4: On"
            Write-Host "IP Address: $($ipv4Info.IPAddress)"
            Write-Host "Subnet Mask: $subnetMask (Prefix Length: $($ipv4Info.PrefixLength))"
            Write-Host "Gateway: $gateway"
            Write-Host "Preferred DNS: $preferredDns"
            Write-Host "Alternate DNS: $alternateDns"
            Write-Host "DNS over HTTPS (IPv4): $dnsOverHttpsIPv4"
        } else {
            Write-Host "IPv4: Off"
        }
        
        # Get IPv6 settings
        $ipv6Info = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv6 -ErrorAction SilentlyContinue
        if ($ipv6Info) {
            # Check for IPv6 gateway
            $gatewayInfo = Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix '::/0' -ErrorAction SilentlyContinue
            $gateway = if ($gatewayInfo) { $gatewayInfo.NextHop } else { "No gateway set" }
            $dnsInfo = Get-DnsClientServerAddress -InterfaceAlias $adapterName -AddressFamily IPv6
            $preferredDns = if ($dnsInfo) { $dnsInfo.ServerAddresses[0] } else { "No DNS set" }
            $alternateDns = if ($dnsInfo -and $dnsInfo.ServerAddresses.Count -gt 1) { $dnsInfo.ServerAddresses[1] } else { "No alternate DNS set" }

            # Check DNS over HTTPS for IPv6
            $dnsOverHttpsIPv6 = if ($dnsClientSettings.UseDnsOverHttps -eq $true) { "On" } else { "Off" }

            Write-Host "IPv6: On"
            Write-Host "IP Address: $($ipv6Info.IPAddress)"
            Write-Host "Subnet Prefix Length: $($ipv6Info.PrefixLength)"
            Write-Host "Gateway: $gateway"
            Write-Host "Preferred DNS: $preferredDns"
            Write-Host "Alternate DNS: $alternateDns"
            Write-Host "DNS over HTTPS (IPv6): $dnsOverHttpsIPv6"
        } else {
            Write-Host "IPv6: Off"
        }

        Write-Host "-----------------------------------"
    }
}

# Function to set the IPv4 and IPv6 settings for a specified adapter
function Set-NetworkAdapterSettings {
    param (
        [string]$AdapterName,
        [string]$IPv4Address,
        [int]$SubnetMask,
        [string]$Gateway,
        [string]$PreferredDNS,
        [string]$AlternateDNS = $null,
        [string]$IPv6Address,
        [int]$IPv6PrefixLength = 64,
        [string]$IPv6Gateway = $null,
        [string]$IPv6PreferredDNS = $null,
        [string]$IPv6AlternateDNS = $null
    )

    # Setting IPv4
    if ($IPv4Address -and $SubnetMask -and $Gateway) {
        try {
            $existingIPv4 = Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($existingIPv4) {
                Write-Host "IPv4Address: $($existingIPv4.IPv4Address)"
                Write-Host "AdapterName: $($existingIPv4.InterfaceAlias)"

                Remove-NetIPAddress -InterfaceAlias $existingIPv4.InterfaceAlias -IPAddress $existingIPv4.IPv4Address -Confirm:$false 
            }
            $existingGateway = Get-NetRoute -InterfaceAlias $AdapterName -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
            if ($existingGateway) {
                Remove-NetRoute -InterfaceAlias $existingGateway.InterfaceAlias -DestinationPrefix '0.0.0.0/0' -Confirm:$false
            }
            New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPv4Address -PrefixLength $SubnetMask -DefaultGateway $Gateway -ErrorAction Stop
            $dnsAddresses = @($PreferredDNS)
            if ($AlternateDNS) {
                $dnsAddresses += $AlternateDNS
            }
            Set-DnsClientServerAddress -InterfaceAlias $AdapterName -ServerAddresses $dnsAddresses
        } catch {
            Write-Host "Error setting IPv4 settings: $_"
        }
    }

    # Setting IPv6
    if ($IPv6Address -and $IPv6PrefixLength -ne $null) {
        try {
           # Check if the IPv6 address exists and remove it before adding the new one
            Write-Host "Removing existing IPv6 addresses for adapter $AdapterName :"

            # Remove any existing IPv6 addresses
            Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv6 -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "Removing IP Address: $($_.IPAddress)"
                Remove-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
            }

            # Remove IPv6 addresses from PersistentStore
            Write-Host "Removing IPv6 addresses from PersistentStore for adapter $AdapterName :"
            Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv6 -PolicyStore PersistentStore -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "Removing IP Address from PersistentStore: $($_.IPAddress)"
                Remove-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $_.IPAddress -PolicyStore PersistentStore -Confirm:$false -ErrorAction SilentlyContinue
            }

            # Reset IPv6 configuration using netsh
            Write-Host "Resetting IPv6 configuration using netsh:"
            netsh interface ipv6 reset
            Write-Host "Please restart the computer to complete the reset if prompted."

            # Check for duplicate IP addresses
            Write-Host "Checking for duplicate IP addresses (this may return no results if the address is correctly removed):"
            try {
                $duplicateIPs = Get-NetIPAddress -IPAddress $IPv6Address -ErrorAction Stop
                if ($duplicateIPs) {
                    $duplicateIPs | Format-Table
                }
            } catch {
                Write-Host "No duplicate IP addresses found."
            }

            # Ensure network adapter is active
            Write-Host "Ensuring network adapter $AdapterName is active:"
            Get-NetAdapter -Name $AdapterName | Enable-NetAdapter

            # Retry setting the IPv6 address
            Write-Host "Retrying to set the IPv6 address $IPv6Address on adapter $AdapterName :"
            try {
                New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPv6Address -PrefixLength $IPv6PrefixLength -ErrorAction Stop
                Write-Host "Successfully set IPv6 address $IPv6Address on adapter $AdapterName."
            } catch {
                Write-Host "Error setting IPv6 settings: $_"
                $errorRecord = $_
                Write-Host "Exception Type: $($errorRecord.Exception.GetType().FullName)"
                Write-Host "Error Message: $($errorRecord.Exception.Message)"
                Write-Host "Stack Trace: $($errorRecord.Exception.StackTrace)"
                Write-Host "Fully Qualified Error ID: $($errorRecord.FullyQualifiedErrorId)"
                Write-Host "Error Category: $($errorRecord.CategoryInfo.Category)"
                Write-Host "Target Object: $($errorRecord.TargetObject)"
                Write-Host "Invocation Info: $($errorRecord.InvocationInfo)"
            }


            # Set new IPv6 route if specified
            if ($IPv6Gateway) {
                New-NetRoute -InterfaceAlias $AdapterName -DestinationPrefix "::/0" -NextHop $IPv6Gateway -ErrorAction Stop
            }

            # Set DNS servers for IPv6 only if non-null
            if ($IPv6PreferredDNS -or $IPv6AlternateDNS) {
                $ipv6DnsAddresses = @($IPv6PreferredDNS)
                if ($IPv6AlternateDNS) {
                    $ipv6DnsAddresses += $IPv6AlternateDNS
                }
                Set-DnsClientServerAddress -InterfaceAlias $AdapterName -ServerAddresses $ipv6DnsAddresses
            }
        } catch {
            Write-Host "Error setting IPv6 settings: $_"
            Write-Host "Detailed error information:"
            $errorRecord = $_
            Write-Host "Exception Type: $($errorRecord.Exception.GetType().FullName)"
            Write-Host "Error Message: $($errorRecord.Exception.Message)"
            Write-Host "Stack Trace: $($errorRecord.Exception.StackTrace)"
            Write-Host "Fully Qualified Error ID: $($errorRecord.FullyQualifiedErrorId)"
            Write-Host "Error Category: $($errorRecord.CategoryInfo.Category)"
            Write-Host "Target Object: $($errorRecord.TargetObject)"
            Write-Host "Invocation Info: $($errorRecord.InvocationInfo)"
        }
    }

    Write-Host "Settings updated for adapter: $AdapterName"
}

# Example usage
# Remove-HostNetworkAdapter -AdapterName "vEthernet (InternalSwitch)"
function Remove-HostNetworkAdapter {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AdapterName
    )

    try {
        # Get the network adapter device
        $adapter = Get-NetAdapter -Name $AdapterName

        if ($adapter) {
            $pnpDevice =  Get-PnpDevice -FriendlyName $adapter.InterfaceDescription 
            # Uninstall the network adapter using pnputil
            $cmd = "pnputil /remove-device `"$($pnpDevice.InstanceId)`""
            Invoke-Expression $cmd

            Write-Output "Network adapter '$AdapterName' removed successfully."
        } else {
            Write-Error "Network adapter '$AdapterName' not found or already removed."
        }
    } catch {
        Write-Error "Failed to remove network adapter '$AdapterName'. Error: $_"
    }
}
  
# Example usage
# Disable-HostNetworkAdapter -AdapterName "vEthernet (InternalSwitch)"
function Disable-HostNetworkAdapter {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AdapterName
    )

    try {
        # Get the network adapter device
        $adapter = Get-PnpDevice -FriendlyName "*$AdapterName*" | Where-Object { $_.Status -eq "OK" }

        if ($adapter) {
            # Disable the network adapter
            Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false

            Write-Output "Network adapter '$AdapterName' disabled successfully."
        } else {
            Write-Error "Network adapter '$AdapterName' not found or already disabled."
        }
    } catch {
        Write-Error "Failed to disable network adapter '$AdapterName'. Error: $_"
    }
}

# Example usage
# Remove-VMNetworkAdapter -VMName "Windows 11 dev environment" -AdapterName "vEthernet (Default Switch)"
function Remove-VMNetworkAdapter {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VMName,
        [Parameter(Mandatory = $true)]
        [string]$AdapterName
    )

    try {
        # Remove the network adapter from the VM
        Remove-VMNetworkAdapter -VMName $VMName -Name $AdapterName -Confirm:$false

        Write-Output "Network adapter '$AdapterName' removed from VM '$VMName' successfully."
    } catch {
        Write-Error "Failed to remove network adapter '$AdapterName' from VM '$VMName'. Error: $_"
    }
}

# Example usage
# Get-VMNetworkAdapters -VMName "Windows 11 dev environment"
function Get-VMNetworkAdapters {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VMName
    )

    try {
        # Get the list of network adapters in the VM
        $vmNetworkAdapters = Get-VMNetworkAdapter -VMName $VMName

        # Display the network adapters
        $vmNetworkAdapters | Format-Table -Property Name, IsEnabled, MacAddress, SwitchName

        return $vmNetworkAdapters
    } catch {
        Write-Error "Failed to get network adapters for VM '$VMName'. Error: $_"
    }
}

Export-ModuleMember -Function Get-NetworkAdapterSettings, Set-NetworkAdapterSettings, Remove-HostNetworkAdapter, Remove-VMNetworkAdapter, Disable-HostNetworkAdapter, Get-VMNetworkAdapters 
