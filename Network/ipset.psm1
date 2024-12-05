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

# Function to get the current IPv4 and IPv6 settings for all network adapters
function Get-NetworkAdapterSettings {
    # Function to convert prefix length to subnet mask
    function ConvertTo-SubnetMask($prefixLength) {
        return [string]::Join('.', ([Convert]::ToString(([math]::Pow(2, 32) - [math]::Pow(2, 32 - $prefixLength)), 2) -split '(?<=\G.{8})(?!$)' | % {[Convert]::ToInt32($_, 2)}))
    }

    # Retrieve all network adapters
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        $adapterName = $adapter.InterfaceAlias
        Write-Host "Adapter: $adapterName"
        
        # Get IPv4 settings
        $ipv4Info = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ipv4Info) {
            # Check for IPv4 gateway
            $gatewayInfo = Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
            $gateway = if ($gatewayInfo) { $gatewayInfo.NextHop } else { "No gateway set" }
            $dnsInfo = Get-DnsClientServerAddress -InterfaceAlias $adapterName -AddressFamily IPv4
            $preferredDns = if ($dnsInfo) { $dnsInfo.ServerAddresses[0] } else { "No DNS set" }
            $alternateDns = if ($dnsInfo -and $dnsInfo.ServerAddresses.Count -gt 1) { $dnsInfo.ServerAddresses[1] } else { "No alternate DNS set" }
            $subnetMask = ConvertTo-SubnetMask $ipv4Info.PrefixLength

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
                Remove-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPv4Address -Confirm:$false 
            }
            $existingGateway = Get-NetRoute -InterfaceAlias $AdapterName -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
            if ($existingGateway) {
                Remove-NetRoute -InterfaceAlias $AdapterName -DestinationPrefix '0.0.0.0/0' -Confirm:$false
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

Export-ModuleMember -Function Get-NetworkAdapterSettings, Set-NetworkAdapterSettings
