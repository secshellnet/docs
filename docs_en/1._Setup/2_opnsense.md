# OPNsense
## Installation and assignment of the network interfaces
!!! info ""  
    The OPNsense receives its assigned IPv4 address via DHCP, for this a MAC address for the IP address must be requested in the Hetzner Robot - and configured accordingly in the VM.<br>
    MAC addresses can only be set on individual IPv4 addresses - not on an IPv4 address of a subnet!

First the OPNsense is installed, only the keymap should be adapted.  
After the OPNsense has restarted, you can adjust the interface assignments accordingly.
Only the WAN interface (`vmbr0`) has to be assigned, because VLANs will be created on the LAN interface later on (find the correct interface via MAC address).
Afterwards you can access the WebGUI of the OPNsense via the booked IP address.

!!! warning ""  
    If a LAN interface has been configured, the anti-lockout rule does not apply to the WAN interface, so the packet filter must be temporarily disabled in this case: CLI -> Option 8: Shell -> <code>pfctl -d</code>.

## Setup Assistents
In the web interface you should first run the setup wizard completely, then you should temporarily create an "Allow WebGUI from any" rule in the firewall rules of the WAN interface, so that you do not have to deactivate the packet filter again and again during the setup phase (see [Allow WebGUI from Internet](https://docs.secshell.net/setup/opnsense.de/#webgui-aus-internet-zulassen)).
It is also recommended to disable the password for the console (System -> Settings -> Administration -> Console -> Console menu).

### QEMU Guest Agent
Recently there is also an [OPNsense Plugin which serves as QEMU Guest Agent](https://github.com/opnsense/plugins/pull/2293). Since this plugin is not yet fully developed, it can only be installed via the CLI:
```bash
pkg install os-qemu-guest-agent-devel
```
After the installation the plugin has to be activated in the webinterface under Services -> QEMU Guest Agent with a click on "Save". 

### Allow WebGUI from Internet

!!! info ""  
    When setting up this rule, you should make sure to select <code>any</code> as source IP and not <code>WAN&nbsp;Net</code>.  
    <code>WAN&nbsp;Net</code> contains only the network from which the public IP address comes, not the whole internet!

![OPNsense_WebGUI_WAN_Rules.png](../img/setup/OPNsense_WebGUI_WAN_Rules.png?raw=true){: loading=lazy }

## Internal network setup
The internal network, in which the VMs are accessible, is mapped via VLANs. This way the OPNsense has only one interface (`vmbr1`), regardless of the number of networks, and the creation of new networks does not require a restart of the OPNsense.  

First the LAN interface is removed (Interfaces -> Assignments -> delete `vtnet1`). Then a VLAN is created on the physical interface (Interfaces -> Other Types -> VLAN).
![OPNsense_VLAN.png](../img/setup/OPNsense_VLAN.png?raw=true){: loading=lazy }

Afterwards a new interface is created on the just created "VLAN Port" (Interfaces -> Assignments -> `vtnet1_vlanX`).
![OPNsense_AssignVLAN.png](../img/setup/OPNsense_AssignVLAN.png?raw=true){: loading=lazy }

Finally the first interface has to be configured (Enabled, Description: `vlanX` and IPv4 configuration, if necessary IPv6 configuration)
![OPNsense_VLAN_Interface.png](../img/setup/OPNsense_VLAN_Interface.png?raw=true){: loading=lazy }

!!! info ""  
    Configure Firewall Rules!

## Map WAN IP via OPNsense to VM
Now it is possible to map an internal address to an external address. Requests to this address are routed through the OPNsense, pass the firewall, are "gated" (1:1 NAT) and go to the host.  
For this, the desired WAN IP address must be routed on the host (see server documentation of the dedicated server).

The WAN IP's which should be used internally are entered as Virtual IP address in the OPNsense (System -> Virtual IPs). As long as the 1:1 NAT for this IP has not been configured yet, this IP address should now point directly to the firewall.  
![OPNsense_VirtualIPs.png](../img/setup/OPNsense_VirtualIPs.png?raw=true){: loading=lazy }

Afterwards the IP address can be mapped (Firewall -> NAT -> One-to-One).  
![OPNsense_1-1_NAT.png](../img/setup/OPNsense_1-1_NAT.png?raw=true){: loading=lazy }
Finally the firewall rules have to be set for WAN. Please note that the internal IP is used as destination address.

!!! warning ""  
    The set firewall rule allows everything and should be adjusted accordingly.

![OPNsense_1-1_NAT_Rules.png](../img/setup/OPNsense_1-1_NAT_Rules.png?raw=true){: loading=lazy }

## OpenVPN
The OpenVPN server is set up using the wizard.

The local IPv4 networks to be reached by each participant are routed directly in the tunnel settings of the OpenVPN server. This is only the internal network to reach the DNS server. Also the DNS entry `opnsense.secshell.net` points to the IP address of the firewall in this network.
![OPNsense_OpenVPN_TunnelSettings.png](../img/setup/OPNsense_OpenVPN_TunnelSettings.png?raw=true){: loading=lazy }

In the client specific overwrites, other networks (e.g. the IP address of the host) can be routed through the tunnel.
The tunnel network can be used to allow the clients only their own networks.

!!! info ""  
    The tunnel network of the client must be a subnet of the OpenVPN server tunnel network.

![OPNsense_OpenVPN_CSO_Overview.png](../img/setup/OPNsense_OpenVPN_CSO_Overview.png?raw=true){: loading=lazy }

![OPNsense_OpenVPN_CSO_Edit.png](../img/setup/OPNsense_OpenVPN_CSO_Edit.png?raw=true){: loading=lazy }

![OPNsense_OpenVPN_Rules.png](../img/setup/OPNsense_OpenVPN_Rules.png?raw=true){: loading=lazy }

## IPsec
Setting up a site to site IPsec tunnel is straightforward, [this video](https://www.youtube.com/watch?v=KmoCfa0IxBk) can be used as a source of information, the only difference is the use of pfSense.

## DNS: Wildcard entries
DNS wildcard entries must be done according to the [advanced configuration of the DNS server (`dnsmasq`)](https://docs.opnsense.org/manual/dnsmasq.html#advanced-settings) via the shell. This is done every time a new host is added, as this is the only way to set the DNS entry `*.<vmhost>.secshell.net` ([see forum post](https://forum.opnsense.org/index.php?topic=5855.0)). The SSH server can be activated via `System -> General -> Administration`:
```shell
# /usr/local/etc/dnsmasq.conf.d/dns.conf
address=/hostname.secshell.net/10.2.1.2
```

## IPv6
The IPv6 setup is quiet simple, just follow the following [german guide](https://dominicpratt.de/hetzner-und-proxmox-ipv6-mit-router-vm-nutzen/).

First change the network configuration (`/etc/network/interfaces`) of the proxmox host (add a route to fe80::1 and enable  ipv6 forwarding):
```shell
auto lo
iface lo inet loopback

iface enp41s0 inet manual

auto vmbr0
iface vmbr0 inet static
	address X.X.X.X/27
	gateway X.X.X.X
	bridge-ports enp41s0
	bridge-stp off
	bridge-fd 0

    # ADD FROM HERE
    up ip -6 route add default via fe80::1 dev vmbr0
	up sysctl -w net.ipv6.conf.all.forwarding=1
    # TO HERE

allow-ovs vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge

```

Afterwards you may configure the wan interface of the opnsense using dhcpv6, you'll get a local link ipv6 address for this interface.  
![WAN Interface IPv6 Configuration](../img/setup/OPNsense_IPv6_Interfaces.png?raw=true){: loading=lazy }

The first four blocks of the ipv6 address are being assigned by your hoster, the fifth block is - at least in our setup - reserved for the id of the proxmox vm / lxc. The last three blocks can be used by the host. You have to configure the static ipv6 address `XXXX:XXXX:XXXX:XXXX:ID::1/80` for the vlan interfaces.

![VLAN Interface IPv6 Configuration](../img/setup/OPNsense_IPv6_Interfaces.png?raw=true){: loading=lazy }

Adjust the ipv6 gateway  
![IPv6 Default Gateway](../img/setup/OPNsense_IPv6_Gateway.png?raw=true){: loading=lazy }

Your interface overview on the dashboard should look like this:  
![IPv6 Interface Overview](../img/setup/OPNsense_IPv6_Overview.png?raw=true){: loading=lazy }

Due to the fact that the opnsense can't access the ipv6 network, you should set the following option:
![Prefer IPv4 over IPv6](../img/setup/OPNsense_PreferIPv4.png?raw=true){: loading=lazy}

# Knowledge Base
### DNS resolution does not work over OpenVPN
If you are connected to the VPN and internal DNS queries do not resolve correctly, you need to add the DNS search domain. On Linux this works with the Network Manager using the following command:
```shell
nmcli c modify "Secure Shell Networks" ipv4.dns-search secshell.net
```
Afterwards the VPN connection must be restarted.
