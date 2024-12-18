# .\usehostnet.ps1
# Description: This script enables Internet Connection Sharing (ICS) on the host machine.
# It shares the internet connection from the network adapter with internet access (vEthernet (Bridged Network))
# to the internal network adapter (vEthernet (Internal)).

# Steps:
# 1. First, select the network adapter that has internet connection and share it.
# 2. Use the script to enable Internet Connection Sharing (ICS) for the chosen network adapters.

# Variables
$internetAdapterName = "vEthernet (Bridged Network)"  # Name of the network adapter with internet access
$internalAdapterName = "vEthernet (Internal)"         # Name of the internal network adapter

# Enable ICS using netsh commands
Start-Process -FilePath "netsh" -ArgumentList "interface set interface name=`"$internetAdapterName`" admin=enable"
Start-Process -FilePath "netsh" -ArgumentList "interface set interface name=`"$internalAdapterName`" admin=enable"
Start-Process -FilePath "netsh" -ArgumentList "interface ip set address name=`"$internalAdapterName`" source=dhcp"
Start-Process -FilePath "netsh" -ArgumentList "interface ip set dns name=`"$internalAdapterName`" source=dhcp"
