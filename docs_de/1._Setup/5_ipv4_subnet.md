# IPv4 Subnetz

!!! info ""  
    Da die [Setupgebühren für IPv4 Subnetze bei der Hetzner Online GmbH](https://docs.hetzner.com/de/general/others/ipv4-pricing/#dedicated-server) seit 2021 erhöht wurden, empfehlen wir die Verwendung von IPv6.


Grundlegend gibt es zwei Möglichkeiten das IPv4 Subnetz zu verwenden, in dieser Anleitung wird lediglich auf die Verwendung in der OPNsense eingegangen.
Dafür werden die Adressen des Subnetzes unter Verwendung der Virtual IP's auf der OPNsense eingetragen, anschließend wird 1:1 NAT Verwendet um die virtuellen Maschinen und LXC direkt darüber erreichbar zu machen.
Dies hat den Vorteil, dass die Firewall nicht auf der virtuellen Maschine selbst sondern auf der OPNsense konfiguriert werden kann.

Da das zusätzliche gebuchte IPv4 Subnetz außerhalb des Netzwerkes der Host IP liegt, muss eine Route auf dem Host (in `/etc/network/interfaces`) hinzugefügt werden:
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

   	# AB HIER
    up ip route add 176.9.198.64/29 dev vmbr0
    up sysctl -w net.ipv4.ip_forward=1
	# BIS HIER

allow-ovs vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
```

Die WAN IP's welche Intern verwendet werden sollen, werden als Virtuelle IP Adresse in der OPNsense eingetragen (System -> Virtual IPs). Solange das 1:1 NAT für diese IP noch nicht konfiguriert wurde, sollte diese IP Adresse jetzt direkt auf die Firewall zeigen.  
![OPNsense_VirtualIPs.png](../img/setup/opnsense/OPNsense_VirtualIPs.png?raw=true){: loading=lazy }

Anschließend kann die IP Adresse gemapped werden (Firewall -> NAT -> One-to-One).  
![OPNsense_1-1_NAT.png](../img/setup/opnsense/OPNsense_1-1_NAT.png?raw=true){: loading=lazy }
Zuletzt müssen die Firewall Rules bei WAN gesetzt werden. Hierbei ist zu beachten, dass als Zieladresse die Interne IP verwendet wird.

!!! warning ""  
    Die gesetzte Firewall Regel erlaubt alles und sollte entsprechend angepasst werden.

![OPNsense_1-1_NAT_Rules.png](../img/setup/opnsense/OPNsense_1-1_NAT_Rules.png?raw=true){: loading=lazy }

