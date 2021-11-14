# IPv6
The IPv6 setup is quiet simple, just follow the following [german guide](https://dominicpratt.de/hetzner-und-proxmox-ipv6-mit-router-vm-nutzen/).

First change the network configuration (`/etc/network/interfaces`) of the proxmox host (add a route to fe80::1 and enable ipv6 forwarding):
```shell
auto lo
iface lo inet loopback

iface enp41s0 inet manual

auto vmbr0
iface vmbr0 inet static
	address 88.99.59.89/26
	gateway 88.99.59.65
	bridge-ports enp41s0
	bridge-stp off
	bridge-fd 0

    up ip route add 176.9.198.64/29 dev vmbr0
    up sysctl -w net.ipv4.ip_forward=1

	# ADD FROM HERE
	up ip -6 route add default via fe80::1 dev vmbr0
	up sysctl -w net.ipv6.conf.all.forwarding=1
	# TO HERE

allow-ovs vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
```

Afterwards you may configure the wan interface of the opnsense using dhcpv6, you'll get a local link ipv6 address for this interface.  
![WAN Interface IPv6 Configuration](../img/setup/ipv6/OPNsense_IPv6_WAN.png?raw=true){: loading=lazy }

The first four blocks of the ipv6 address are being assigned by your hoster, the fifth block is - at least in our setup - reserved for the id of the proxmox vm / lxc. The last three blocks can be used by the host. You have to configure the static ipv6 address `XXXX:XXXX:XXXX:XXXX:ID::1/80` for the vlan interfaces.

![VLAN Interface IPv6 Configuration](../img/setup/ipv6/OPNsense_IPv6_Interfaces.png?raw=true){: loading=lazy }

Adjust the ipv6 gateway  
![IPv6 Default Gateway](../img/setup/ipv6/OPNsense_IPv6_Gateway.png?raw=true){: loading=lazy }

Your interface overview on the dashboard should look like this:  
![IPv6 Interface Overview](../img/setup/ipv6/OPNsense_IPv6_Overview.png?raw=true){: loading=lazy }

Due to the fact that the opnsense can't access the ipv6 network, you should set the following option:
![Prefer IPv4 over IPv6](../img/setup/ipv6/OPNsense_PreferIPv4.png?raw=true){: loading=lazy}

The setup of IPv6 in the virtual machines / lxc can be found in the general information of the Services chapter.
