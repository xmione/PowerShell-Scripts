# Steps - Removing Network Adapter

## 1. Get Network Adapters first.

In Host machine:
```
Get-NetAdapter | Format-Table -Autosize
```

In VM:

```
# Example: Get network adapters for a VM named "Windows 11 dev environment"
$vmNetworkAdapters = Get-VMNetworkAdapter -VMName "Windows 11 dev environment"
$vmNetworkAdapters | Format-Table -Property Name, IsEnabled, MacAddress, SwitchName
```

## 2. Remove the adapter using the network tool functions from ipset module.

### Remove Host Adapter
```
 Remove-HostNetworkAdapter -AdapterName "vEthernet (InternalSwitch)"
```

### Remove VM Adapter
```
Remove-VMNetworkAdapter -VMName "Windows 11 dev environment" -AdapterName "vEthernet (Default Switch)"
```

## Other tricks:
 # Check IP configuration on the host
Get-NetIPAddress -InterfaceAlias "vEthernet (Internal)"
Get-NetIPAddress -InterfaceAlias "vEthernet (Bridged Network)"

# Check IP configuration on the VM
Invoke-Command -VMName $VMName -ScriptBlock {
    ipconfig
} -Credential $Credential

# Validate ICS settings on the host
Get-NetAdapter | Format-Table -Autosize
  
