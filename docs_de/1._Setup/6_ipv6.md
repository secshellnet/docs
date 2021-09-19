# IPv6
Die Einrichtung von IPv6 erfolgt anhand dieses [Blogeintrags](https://dominicpratt.de/hetzner-und-proxmox-ipv6-mit-router-vm-nutzen/).

Zuerst muss die Route für fe80::1 erstellt und IPv6 Forwarding aktiviert werden, dies erfolgt zum Beispiel in der Datei `/etc/network/interfaces` auf dem Proxmox Host:
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
    
	# AB HIER
	up ip -6 route add default via fe80::1 dev vmbr0
	up sysctl -w net.ipv6.conf.all.forwarding=1
	# BIS HIER

allow-ovs vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge

```

Anschließend wird das WAN Interface der OPNsense per DHCPv6 konfiguriert, dadurch erhält man eine Local Link Adresse auf diesem Interface.  
![WAN Interface IPv6 Configuration](../img/setup/ipv6/OPNsense_IPv6_Interfaces.png?raw=true){: loading=lazy }

Die ersten vier Blöcke der IPv6 Adresse werden bei einem 64er IPv6 Netzwerk durch den Hoster vorgegeben, in den fünften Block wird die ID der Proxmox VM bzw des LXC Containers eingetragen, die letzten drei Block der IPv6 Adresse werden dem Host zugewiesen. In den vlan Interfaces der OPNsense wird die Static IPv6 `XXXX:XXXX:XXXX:XXXX:ID::1/80` eingetragen.

![VLAN Interface IPv6 Configuration](../img/setup/ipv6/OPNsense_IPv6_Interfaces.png?raw=true){: loading=lazy }

Zuletzt muss das IPv6 Gateway als Default Gateway eingetragen werden:  
![IPv6 Default Gateway](../img/setup/ipv6/OPNsense_IPv6_Gateway.png?raw=true){: loading=lazy }

Auf dem Dashboard sollte es dann so aussehen:  
![IPv6 Interface Overview](../img/setup/ipv6/OPNsense_IPv6_Overview.png?raw=true){: loading=lazy }

Die OPNsense selbst kommt derzeit weder über das Default, noch über das WAN Interface ins IPv6 Netz, daher sollte umbedingt folgende Einstellung getroffen werden:
![Prefer IPv4 over IPv6](../img/setup/ipv6/OPNsense_PreferIPv4.png?raw=true){: loading=lazy}

Die Einrichtung von IPv6 in den virtuellen Maschinene / LXC kann den Allgemeinen Informationen des Services Kapitels entnommen werden.
