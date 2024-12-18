# Step - How to use Host's Internet Connection

## 1. Manually set it.

### 1.1. Right-click on vEthernet (Bridged Network):

### 1.2. Go to Properties.

### 1.3. Enable Internet Connection Sharing:

### 1.4. Go to the Sharing tab.

### 1.5. Check the box Allow other network users to connect through this computer's Internet connection.

### 1.6. From the dropdown menu, select vEthernet (Internal) as the network adapter to share with.

### 1.7. Configure Your VM:

#### 1.7.1. Ensure your VM is connected to the internal switch.

#### 1.7.2. Set the network adapter in the VM to obtain an IP address automatically (DHCP).

This setup should allow your VM to access the internet through your host machine's connection.

## 2. Create and run a PowerShell Script.

```
# .\usehostnet.ps1
# Variables
$internetAdapterName = "vEthernet (Bridged Network)"
$internalAdapterName = "vEthernet (Internal)"

# Get the network adapters
$internetAdapter = Get-NetAdapter -Name $internetAdapterName
$internalAdapter = Get-NetAdapter -Name $internalAdapterName

# Enable ICS
Set-NetConnectionSharing -ConnectionProfileName $internetAdapter.Name -ConnectionSharingType Shared
Set-NetConnectionSharing -ConnectionProfileName $internalAdapter.Name -ConnectionSharingType Private

```