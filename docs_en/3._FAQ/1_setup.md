# Setup

## LXC Setup
![Network configuration while lxc creation](../img/faq/proxmox_lxc_network.png?raw=true){: loading=lazy }

The network interface of the lxc is connected the the internal bridge `vmbr1`, using the proxmox id as vlan id (in this case 116).  
DHCP take care about the ipv4 configuration, ipv6 is going to receive a static configuration.

## VM Setup
![Network configuration while vm creation](../img/faq/proxmox_vm_network.png?raw=true){: loading=lazy }

The network interface of the lxc is connected the the internal bridge `vmbr1`, using the proxmox id as vlan id (in this case 116).  
The ip configuration is done in the guest system. Most installer configure ipv4 via dhcp while setup.  
You can get information about the ipv6 configuration in [General Information](https://docs.secshell.net/en/2._Services/1_general/)

## OPNsense
Regardless of what you set up (lxc or a virtual machine) the OPNsense will be set up:

Interfaces --> Other Types --> VLAN --> +

* Description: vlanID (in this case: vlan116)
* Parent Interface: vtnet1
* VLAN tag: Proxmox ID (in this case: 116)

Interfaces --> Assignments

* choose `vlan 116 on vtnet1`, and add using `+`

Interfaces --> OPTx

* Check Enable interface
* Check Prevent interface removal.
* Set IPv4 Configuration Type to `Static IPv4`.
* Set IPv6 Configuration Type to `Static IPv6`.
* IPv4 Address: `10.2.0.1` `30` (first address from the ipv4 subnet)
* IPv6 Address: `2a01:4f8:10a:b88:116::1` `80`

Services --> DHCPv4 -> vlan116

* Check Enable.
* Range: Set addresses (from: `10.2.0.2`, to `10.2.0.2`)

Firewall --> Rules --> Floating

* add the interface vlanID for each entry in this list.

Firewall --> Rules --> vlanID

* If nessesary, create more firewall rules for this network.
