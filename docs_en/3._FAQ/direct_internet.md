# Direct connected Internet

There are two options to connect lxc containers and virtual machines (called vm in the further articel) to the internet (using a public ip address).  
1. [over OPNsense using a 1:1 NAT](../setup/opnsense.md)  
2. connect directly to the vmbr0 interface.  

!!! warning ""
    Make sure to create some firewall rules on the vm if you prefer the second option.

## IPv4 example configuration:

- IP Address: 176.9.198.70/32  
- Gateway: 88.99.59.89  
- DNS server: 1.1.1.1  

![Example configuration of a lxc](../img/faq/direct_internet_lxc.png?raw=true){: loading=lazy }

## IPv6 example configuration:

- IP Address: 2a01:4f8:10a:b88::5/128  
- Gateway: fe80::1  
- DNS server: 2606:4700:4700::1111  

![Example configuration of a lxc](../img/faq/direct_internet_lxc_v6.png?raw=true){: loading=lazy }
