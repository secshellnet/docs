# Setup
## LXC Einrichtung
![Netzwerkkonfiguration beim Erstellen eines LXC Containers](../img/faq/proxmox_lxc_network.png?raw=true){: loading=lazy }

Der LXC bekommt ein Netzwerkinterface auf der Internen Netzwerkbrücke (`vmbr1`), mit der vergebenen Proxmox ID als VLAN (hier 116).  
Die IPv4 Konfiguration erfolgt per DHCP, IPv6 wird statisch konfiguriert.

## VM Einrichtung
![Netzwerkkonfiguration beim Erstellen einer virtuellen Maschine](../img/faq/proxmox_vm_network.png?raw=true){: loading=lazy }

Die VM bekommt ein Netzwerkinterface auf der Internen Netzwerkbrücke (`vmbr1`), mit der vergebenen Proxmox ID als VLAN (hier 116).  
Die IP Konfiguration erfolgt im Gastsystem. Die meisten Installer, konfigurieren IPv4 via DHCP während dem Setup. Die IPv6 Konfiguration kann den [Allgemeinen Informationen](https://docs.secshell.net/de/2._Services/1_general/) in Services Tab entnommen werden.

## OPNsense
Unabhängig davon ob es sich um einen LXC oder eine virtuelle Maschine handelt wird die OPNsense eingerichtet:

Interfaces --> Other Types --> VLAN --> +  
* Description: vlanID (hier: vlan116)  
* Parent Interface: vtnet1  
* VLAN tag: Proxmox ID (hier: 116)  

Interfaces --> Assignments  
* `vlan 116 on vtnet1` auswählen, dann auf `+`  

Interfaces --> OPTx  
* Haken bei Enable interface setzen.  
* Haken bei Prevent interface removal setzen.  
* IPv4 Configuration Type auf `Static IPv4` setzen.  
* IPv6 Configuration Type auf `Static IPv6` setzen.  
* IPv4 Address: `10.2.0.1` `30` (erste IPv4 Adresse aus dem Subnetz)  
* IPv6 Address: `2a01:4f8:10a:b88:116::1` `80`  

Services --> DHCPv4 -> vlan116  
* Haken bei Enable setzen.  
* Range: Verfügbare Adressen eintragen (from: `10.2.0.2`, to `10.2.0.2`)  

Firewall --> Rules --> Floating  
* In jedem Eintrag unter Interface vlanID (hier vlan116) hinzufügen.  

Firewall --> Rules --> vlanID  
* Falls notwendig werden hier weitere Firewall Regeln angelegt.  
