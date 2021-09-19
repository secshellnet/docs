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

![OPNsense_WebGUI_WAN_Rules.png](../img/setup/opnsense/OPNsense_WebGUI_WAN_Rules.png?raw=true){: loading=lazy }

## Internal network setup
The internal network, in which the VMs are accessible, is mapped via VLANs. This way the OPNsense has only one interface (`vmbr1`), regardless of the number of networks, and the creation of new networks does not require a restart of the OPNsense.  

First the LAN interface is removed (Interfaces -> Assignments -> delete `vtnet1`). Then a VLAN is created on the physical interface (Interfaces -> Other Types -> VLAN).
![OPNsense_VLAN.png](../img/setup/opnsense/OPNsense_VLAN.png?raw=true){: loading=lazy }

Afterwards a new interface is created on the just created "VLAN Port" (Interfaces -> Assignments -> `vtnet1_vlanX`).
![OPNsense_AssignVLAN.png](../img/setup/opnsense/OPNsense_AssignVLAN.png?raw=true){: loading=lazy }

Finally the first interface has to be configured (Enabled, Description: `vlanX` and IPv4 configuration, if necessary IPv6 configuration)
![OPNsense_VLAN_Interface.png](../img/setup/opnsense/OPNsense_VLAN_Interface.png?raw=true){: loading=lazy }

!!! info ""  
    Configure Firewall Rules!

## OpenVPN
The OpenVPN server is set up using the wizard.

The local IPv4 networks to be reached by each participant are routed directly in the tunnel settings of the OpenVPN server. This is only the internal network to reach the DNS server. Also the DNS entry `opnsense.secshell.net` points to the IP address of the firewall in this network.
![OPNsense_OpenVPN_TunnelSettings.png](../img/setup/opnsense/OPNsense_OpenVPN_TunnelSettings.png?raw=true){: loading=lazy }

In the client specific overwrites, other networks (e.g. the IP address of the host) can be routed through the tunnel.
The tunnel network can be used to allow the clients only their own networks.

!!! info ""  
    The tunnel network of the client must be a subnet of the OpenVPN server tunnel network.

![OPNsense_OpenVPN_CSO_Overview.png](../img/setup/opnsense/OPNsense_OpenVPN_CSO_Overview.png?raw=true){: loading=lazy }

![OPNsense_OpenVPN_CSO_Edit.png](../img/setup/opnsense/OPNsense_OpenVPN_CSO_Edit.png?raw=true){: loading=lazy }

![OPNsense_OpenVPN_Rules.png](../img/setup/opnsense/OPNsense_OpenVPN_Rules.png?raw=true){: loading=lazy }

## IPsec
Setting up a site to site IPsec tunnel is straightforward, [this video](https://www.youtube.com/watch?v=KmoCfa0IxBk) can be used as a source of information, the only difference is the use of pfSense.

## DNS: Wildcard entries
DNS wildcard entries must be done according to the [advanced configuration of the DNS server (`dnsmasq`)](https://docs.opnsense.org/manual/dnsmasq.html#advanced-settings) via the shell. This is done every time a new host is added, as this is the only way to set the DNS entry `*.<vmhost>.secshell.net` ([see forum post](https://forum.opnsense.org/index.php?topic=5855.0)). The SSH server can be activated via `System -> General -> Administration`:
```shell
# /usr/local/etc/dnsmasq.conf.d/dns.conf
address=/hostname.secshell.net/10.2.1.2
```

# Knowledge Base
### DNS resolution does not work over OpenVPN
If you are connected to the VPN and internal DNS queries do not resolve correctly, you need to add the DNS search domain. On Linux this works with the Network Manager using the following command:
```shell
nmcli c modify "Secure Shell Networks" ipv4.dns-search secshell.net
```
Afterwards the VPN connection must be restarted.
