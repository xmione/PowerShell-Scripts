# checkip.ps1
# Set variables for network adapter and IP settings 
$AdapterName = "vEthernet (Bridged Network)" 
$IPv6Address = "fe80::c80a:d920:24dd:3f05" 
$IPv6PrefixLength = 64

Clear-Host 

# Step 1: List Current IP Addresses
Write-Host "Listing current IP addresses for adapter $AdapterName :"
Get-NetIPAddress -InterfaceAlias $AdapterName | Format-Table -ErrorAction SilentlyContinue

# Step 2: Remove Any Existing IPv6 Addresses
Write-Host "Removing existing IPv6 addresses for adapter $AdapterName :"
Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv6 | ForEach-Object {
    Remove-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
}

# Step 2.1: Remove IPv6 Addresses from PersistentStore
Write-Host "Removing IPv6 addresses from PersistentStore for adapter $AdapterName :"
Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv6 -PolicyStore PersistentStore | ForEach-Object {
    Remove-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $_.IPAddress -PolicyStore PersistentStore -Confirm:$false -ErrorAction SilentlyContinue
}

# Step 2.2: Reset IPv6 configuration using netsh
Write-Host "Resetting IPv6 configuration using netsh:"
netsh interface ipv6 reset
Write-Host "Please restart the computer to complete the reset if prompted."

# Step 3: Check for Duplicate IP Addresses
Write-Host "Checking for duplicate IP addresses (this may return no results if the address is correctly removed):"

try {
    $duplicateIPs = Get-NetIPAddress -IPAddress $IPv6Address -ErrorAction Stop
    if ($duplicateIPs) {
        $duplicateIPs | Format-Table
    }
} catch {
    Write-Host "No duplicate IP addresses found."
}


# Step 4: Ensure Network Adapter is Active
Write-Host "Ensuring network adapter $AdapterName is active:"
Get-NetAdapter -Name $AdapterName | Enable-NetAdapter

# Step 5: Retry Setting the IPv6 Address
Write-Host "Retrying to set the IPv6 address $IPv6Address on adapter $AdapterName :"
try {
    New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPv6Address -PrefixLength $IPv6PrefixLength -ErrorAction Stop
    Write-Host "Successfully set IPv6 address $IPv6Address on adapter $AdapterName ."
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
