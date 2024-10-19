<#
    Author  : Solomio S. Sisante
    Created : October 19, 2024
    FileName: ipset.psm1
    Purpose : Network Tools module to get and set IPv4 and IPv6 settings.

    Usage   : 

    Get-NetworkAdapterSettings

    Set-NetworkAdapterSettings -AdapterName "vEthernet (Bridged Network)" 
                               -IPv4Address "192.168.100.73" 
                               -SubnetMask "255.255.255.0" 
                               -Gateway "192.168.100.1" 
                               -PreferredDNS "192.168.100.1" 
                               -AlternateDNS "8.8.4.4" 
                               -DnsOverHttpsIPv4 $false 
                               -IPv6Address "fe80::c80a:d920:24dd:3f05%4" 
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
        [string]$AlternateDNS,
        [bool]$DnsOverHttpsIPv4,
        [string]$IPv6Address,
        [bool]$DnsOverHttpsIPv6
    )

    # Setting IPv4
    if ($IPv4Address -and $SubnetMask -and $Gateway) {
        # Remove existing IP configuration
        Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        # Add new IP configuration
        New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPv4Address -PrefixLength $SubnetMask -DefaultGateway $Gateway
        # Set DNS
        Set-DnsClientServerAddress -InterfaceAlias $AdapterName -ServerAddresses $PreferredDNS, $AlternateDNS
        # Set DNS over HTTPS
        Set-DnsClient -InterfaceAlias $AdapterName -UseDnsOverHttps $DnsOverHttpsIPv4
    }

    # Setting IPv6
    if ($IPv6Address) {
        # Remove existing IPv6 configuration
        Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv6 | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        # Add new IPv6 configuration
        New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPv6Address -PrefixLength 64
        # Set DNS for IPv6
        Set-DnsClientServerAddress -InterfaceAlias $AdapterName -AddressFamily IPv6 -ServerAddresses $PreferredDNS, $AlternateDNS
        # Set DNS over HTTPS
        Set-DnsClient -InterfaceAlias $AdapterName -UseDnsOverHttps $DnsOverHttpsIPv6
    }

    Write-Host "Settings updated for adapter: $AdapterName"
}

Export-ModuleMember -Function Get-NetworkAdapterSettings, Set-NetworkAdapterSettings
