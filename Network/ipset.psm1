<#
    Author  : Solomio S. Sisante
    Creatod : October 19, 2024
    FileName: ipset.psm1
    Purpose : Network Tools module to set the IPv4 and IPv6 settings.

    Note    : There is a batch file import-ipset.bat that you can right click and run as admin from the Windows Explorer to run this script.

    .\ipset.ps1
    
    
    This is used to get and set the network adapter settings:

    Get-NetworkAdapterSettings

    Set-NetworkAdapterSettings -AdapterName "vEthernet (Bridged Network)" 
                               -IPv4Address "192.168.100.73" 
                               -SubnetMask 24 
                               -Gateway "192.168.100.1" 
                               -PreferredDNS "8.8.8.8" 
                               -AlternateDNS "8.8.4.4" 
                               -DnsOverHttpsIPv4 $true 
                               -IPv6Address "2001:db8::1" 
                               -DnsOverHttpsIPv6 $true


#>

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
            # Check for IPv4 gateway
            $gatewayInfo = Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
            
            $gateway = if ($gatewayInfo) { $gatewayInfo.NextHop } else { "No gateway set" }
            $dnsInfo = Get-DnsClientServerAddress -InterfaceAlias $adapterName -AddressFamily IPv4
            
            $preferredDns = if ($dnsInfo) { $dnsInfo.ServerAddresses -join ', ' } else { "No DNS set" }

            Write-Host "IPv4: On"
            Write-Host "IP Address: $($ipv4Info.IPAddress)"
            Write-Host "Subnet Mask: $($ipv4Info.PrefixLength)"
            Write-Host "Gateway: $gateway"
            Write-Host "Preferred DNS: $preferredDns"
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
            
            $preferredDns = if ($dnsInfo) { $dnsInfo.ServerAddresses -join ', ' } else { "No DNS set" }

            Write-Host "IPv6: On"
            Write-Host "IP Address: $($ipv6Info.IPAddress)"
            Write-Host "Subnet Prefix Length: $($ipv6Info.PrefixLength)"
            Write-Host "Gateway: $gateway"
            Write-Host "Preferred DNS: $preferredDns"
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
<#
# Example usage to get settings
Get-NetworkAdapterSettings

# Example usage to set settings (uncomment and modify the parameters accordingly)
Set-NetworkAdapterSettings -AdapterName "vEthernet (Bridged Network)" 
                           -IPv4Address "192.168.100.73" 
                           -SubnetMask 24 
                           -Gateway "192.168.100.1" 
                           -PreferredDNS "8.8.8.8" 
                           -AlternateDNS "8.8.4.4" 
                           -DnsOverHttpsIPv4 $true 
                           -IPv6Address "2001:db8::1" 
                           -DnsOverHttpsIPv6 $true


#>
