<#
    Author  : Solomio S. Sisante
    Created : October 19, 2024
    FileName: ipset.ps1
    Purpose : To import modules from ipset.psm1 and run them to set Host Machine's IPv4 and IPv6 Settings.

    Note    : There is a batch file ipset.bat that you can right click and run as admin from the Windows Explorer to run this script.
            : Replace the settings at the bottom of this file to specify your desired settings.
    .\ipset.ps1
#>

Clear-Host

# Set module version
$requiredModuleVersion = '1.0.0.0'  # <-- Major.Minor.Patch.Revision

# Set variables for network adapter and IP settings 
$AdapterName = "vEthernet (Bridged Network)" 
$IPAddress = "192.168.100.73" 
$SubnetMask = 24 
$Gateway = "192.168.100.1" 
$PreferredDNS = "8.8.8.8" 
$IPv6Address = "fe80::c80a:d920:24dd:3f05" 
$IPv6PrefixLength = 64

# Get the current script root directory
$scriptRoot = $PSScriptRoot
$scriptFileFullPath = "$scriptRoot\ipset.psm1"
$moduleName = [System.IO.Path]::GetFileNameWithoutExtension($scriptFileFullPath)

# Check if the module is loaded
$loadedModule = Get-Module -Name $moduleName
if ($loadedModule) {
    if ($loadedModule.Version -ne $requiredModuleVersion) {
        Write-Host "Loaded module version ($($loadedModule.Version)) does not match the required version ($requiredModuleVersion). Removing module."
        try {
            Remove-Module -Name $moduleName -Force
        } catch {
            Write-Host "Failed to remove module: $moduleName - $_"
        }
    } else {
        Write-Host "Module $moduleName is already loaded with the correct version ($requiredModuleVersion)."
    }
} else {
    Write-Host "Module $moduleName is not loaded."
}

# Optional: Confirm the module has been removed
Write-Host "============================================================"
Write-Host "Modules after removal:"
Get-Module

# Import the specified module
Write-Host "Importing module from $scriptFileFullPath with version $requiredModuleVersion"
Import-Module -Name $scriptFileFullPath

Write-Host "============================================================"
Write-Host "Modules after importing:"
Get-Module

# Check if the module is imported with the correct version
$importedModule = Get-Module -Name $moduleName
if ($importedModule.Version -eq $requiredModuleVersion) {
    Write-Host "$moduleName imported successfully with version $requiredModuleVersion."
} else {
    Write-Host "Warning: $moduleName imported, but version ($($importedModule.Version)) does not match the required version ($requiredModuleVersion)."
}

# Check if the IP address exists 
$existingIP = Get-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPAddress -ErrorAction SilentlyContinue 

# If the IP address exists, remove it 
if ($existingIP) { 
    Write-Host "Remove-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPAddress -Confirm:$false"
    Remove-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPAddress -Confirm:$false 
}

# Get and Set Network Adapter Settings
Write-Host "=================================================================================================================="
Write-Host "Get-NetworkAdapterSettings"
Write-Host "=================================================================================================================="
Get-NetworkAdapterSettings

Write-Host "=================================================================================================================="
Write-Host "Set-NetworkAdapterSettings"
Write-Host "=================================================================================================================="
Set-NetworkAdapterSettings -AdapterName $AdapterName `
                            -IPv4Address $IPAddress `
                            -SubnetMask $SubnetMask `
                            -Gateway $Gateway `
                            -PreferredDNS $PreferredDNS `
                            -AlternateDNS $null `
                            -DnsOverHttpsIPv4 $false `
                            -IPv6Address $IPv6Address `
                            -IPv6PrefixLength $IPv6PrefixLength `
                            -IPv6Gateway $null `
                            -IPv6PreferredDNS $null `
                            -IPv6AlternateDNS $null `
                            -DnsOverHttpsIPv6 $false


Set-VM-Network-Adapter
Add-VMFirewallRule                            