# IPv4 Subnet

!!! info ""  
    Due to the fact that the [setup fee's for ipv4 subnets](https://docs.hetzner.com/de/general/others/ipv4-pricing/#dedicated-server) has been increased since 2021, we recommend the usage of IPv6.


Basically there are two possibilities to use the IPv4 subnet, in this manual only the use in the OPNsense is described.
For this the addresses of the subnet are entered using the Virtual IP's on the OPNsense, then 1:1 NAT is used to make the virtual machines and LXC directly accessible over it.
This has the advantage that the firewall can be configured on the OPNsense instead of on the virtual machine itself.

Since the additional booked IPv4 subnet is outside the network of the host IP, a route must be added on the host (in `/etc/network/interfaces`):

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

	# ADD FROM HERE
    up ip route add 176.9.198.64/29 dev vmbr0
    up sysctl -w net.ipv4.ip_forward=1
	# TO HERE

allow-ovs vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
```

The WAN IP's which should be used internally are entered as Virtual IP address in the OPNsense (System -> Virtual IPs). As long as the 1:1 NAT for this IP has not been configured yet, this IP address should now point directly to the firewall.  
![OPNsense_VirtualIPs.png](../img/setup/opnsense/OPNsense_VirtualIPs.png?raw=true){: loading=lazy }

Afterwards the IP address can be mapped (Firewall -> NAT -> One-to-One).  
![OPNsense_1-1_NAT.png](../img/setup/opnsense/OPNsense_1-1_NAT.png?raw=true){: loading=lazy }
Finally the firewall rules have to be set for WAN. Please note that the internal IP is used as destination address.

!!! warning ""  
    The set firewall rule allows everything and should be adjusted accordingly.

![OPNsense_1-1_NAT_Rules.png](../img/setup/opnsense/OPNsense_1-1_NAT_Rules.png?raw=true){: loading=lazy }

