# Direct connected Internet

There are two options to connect lxc containers and virtual machines (called vm in the further articel) to the internet (using a public ip address).  
1. [over OPNsense using a 1:1 NAT](../setup/opnsense.md)  
2. connect directly to the vmbr0 interface.  

!!! warning ""
    Make sure to create some firewall rules on the vm if you prefer the second option.

Example configuration:

- IP Address: 176.9.198.70  
- Netmask: 255.255.255.255 (/32 network)  
- Gateway: 88.99.59.89  

![Example configuration of a lxc](../img/faq/direct_internet.png?raw=true){: loading=lazy }
