# Steps - Set Host IP Address

### This tool imports network tools modules that sets and gets IPv4 and IPV6 settings of the host machine and runs them to make the Host Machine ready for HyperV VM networking including internet access.

There are 3 files associated in setting the Host Machine's IPv4 and IPv6 static IP addresses:

1. ipset.bat - executes ipset.ps1. You should run this as Administrator.
2. ipset.ps1 - imports the modules from ipset.psm1 file and runs them.
3. ipset.psm1 - contains the network modules that sets or gets the network properties of the host machine.

