# OPNsense
## Installation und Zuweisung der Netzwerkschnittstellen
!!! info ""  
    Die OPNsense erhält Ihre zugewiesene IPv4 Adresse über DHCP, dafür muss im Hetzner Robot eine MAC Adresse für die IP Adresse angefordert - und entsprechend in der VM konfiguriert - werden.<br>
    MAC Adressen können nur auf einzelnen IPv4 Adressen - nicht auf einer IPv4 Adresse eines Subnetzes - festgelegt werden!

Zuerst wird die OPNsense installiert, lediglich das Keymap sollte angepasst werden.  
Nachdem die OPNsense neugestartet hat, kann man die Interfaceszuweisungen entsprechend anpassen.
Hierbei muss lediglich das WAN Interface (`vmbr0`) zugewiesen werden, da auf dem LAN Interface im weiteren Verlauf VLAN's angelegt werden (über MAC Adresse korrektes Interface finden).
Anschließend kann man über die gebuchte IP Adresse auf die WebGUI der OPNsense zugreifen.

!!! warning ""  
    Falls ein LAN Interface konfiguriert wurde, greift die Anti-Lockout Rule nicht auf dem WAN Interface, daher muss in diesem Fall der Paketfilter temporär deaktiviert werden: CLI -> Option 8: Shell -> <code>pfctl -d</code>.

## Setup Assistenten
Im Webinterface sollte zuerst der Setup Assistent vollständig durchlaufen werden, anschließend sollte man temporär eine "Allow WebGUI from any" Rule in den Firewall Rules des WAN Interfaces erstellen, sodass man während der Einrichtungsphase nicht immer wieder den Paketfilter deaktivieren muss (siehe [WebGUI aus Internet zulassen](https://docs.secshell.net/setup/opnsense.de/#webgui-aus-internet-zulassen)).
Außerdem empfielt es sich das Passwort für die Konsole zu deaktivieren (System -> Settings -> Administration -> Console -> Console menu).

### QEMU Guest Agent
Seit kurzem gibt es auch ein [OPNsense Plugin das als QEMU Guest Agent](https://github.com/opnsense/plugins/pull/2293) dient. Da dieses Plugin noch nicht fertig entwickelt ist, kann man es nur über die CLI installieren:
```bash
pkg install os-qemu-guest-agent-devel
```
Nach der Installation muss das Plugin im Webinterface unter Services -> QEMU Guest Agent mit einem klick auf "Save" aktiviert werden. 

### WebGUI aus Internet zulassen

!!! info ""  
    Bei der Einrichtung dieser Regel, sollte man umbedingt darauf Achten, als Source IP <code>any</code> und nicht <code>WAN&nbsp;Net</code> zu wählen.  
    <code>WAN&nbsp;Net</code> beinhaltet lediglich das Netzwerk aus dem die Öffentliche IP Adresse kommt, nicht das gesamte Internet!

![OPNsense_WebGUI_WAN_Rules.png](../img/setup/OPNsense_WebGUI_WAN_Rules.png?raw=true){: loading=lazy }

## Einrichtung des Internen Netzwerkes
Das Interne Netzwerk, in welchem die VM's erreichbar sind, wird über VLAN's abgebildet. Dadurch besitzt die OPNsense unabhängig von der Anzahl an Netzwerken nur das eine Interface (`vmbr1`), und das Anlegen von neuen Netzwerken erfordert keinen Neustart der OPNsense.  

Zuerst wird das LAN Interface entfernt (Interfaces -> Assignments -> `vtnet1` löschen). Anschließend wird auf das Physikalische Interface ein VLAN angelegt (Interfaces -> Other Types -> VLAN).
![OPNsense_VLAN.png](../img/setup/OPNsense_VLAN.png?raw=true){: loading=lazy }

Im Anschluss wird ein neues Interfaces auf dem soeben erstellten "VLAN Port" erstellt (Interfaces -> Assignments -> `vtnet1_vlanX`).
![OPNsense_AssignVLAN.png](../img/setup/OPNsense_AssignVLAN.png?raw=true){: loading=lazy }

Zuletzt muss das erste Interface konfiguriert werden (Enabled, Description: `vlanX` und IPv4 Konfiguration, ggf IPv6 Konfiguration)
![OPNsense_VLAN_Interface.png](../img/setup/OPNsense_VLAN_Interface.png?raw=true){: loading=lazy }

!!! info ""  
    Firewall Rules konfigurieren!

## WAN IP über OPNsense auf VM mappen
Nun ist es möglich eine Interne Adresse auf eine Externe Adresse zu mappen. Anfragen an diese Adresse, werden über die OPNsense geleitet, durchlaufen die Firewall, werden "genatted" (1:1 NAT) und gehen zum Host.  
Dazu muss die gewünschte WAN IP Adresse auf dem Host gerouted werden (siehe Serverdokumentation des Dedizierten Servers).

Die WAN IP's welche Intern verwendet werden sollen, werden als Virtuelle IP Adresse in der OPNsense eingetragen (System -> Virtual IPs). Solange das 1:1 NAT für diese IP noch nicht konfiguriert wurde, sollte diese IP Adresse jetzt direkt auf die Firewall zeigen.  
![OPNsense_VirtualIPs.png](../img/setup/OPNsense_VirtualIPs.png?raw=true){: loading=lazy }

Anschließend kann die IP Adresse gemapped werden (Firewall -> NAT -> One-to-One).  
![OPNsense_1-1_NAT.png](../img/setup/OPNsense_1-1_NAT.png?raw=true){: loading=lazy }
Zuletzt müssen die Firewall Rules bei WAN gesetzt werden. Hierbei ist zu beachten, dass als Zieladresse die Interne IP verwendet wird.

!!! warning ""  
    Die gesetzte Firewall Regel erlaubt alles und sollte entsprechend angepasst werden.

![OPNsense_1-1_NAT_Rules.png](../img/setup/OPNsense_1-1_NAT_Rules.png?raw=true){: loading=lazy }

## OpenVPN
Der OpenVPN Server wird über den Wizard eingerichtet.

Die lokalen IPv4 Netze, die von jedem Teilnehmer erreicht werden sollen, werden direkt in den Tunnel Settings des OpenVPN Server gerouted. Dies ist lediglich das Interne Netzwerk, über das man den DNS Server erreicht. Auch der DNS Eintrag `opnsense.secshell.net` verweist auf die IP Adresse der Firewall in diesem Netzwerk.
![OPNsense_OpenVPN_TunnelSettings.png](../img/setup/OPNsense_OpenVPN_TunnelSettings.png?raw=true){: loading=lazy }

In den Client Specific Overwrites, können weitere Netzwerke (z.B. die IP Adresse des Hosts) über den Tunnel gerouted werden gerouted werden.
Das Tunnel Netzwerk kann verwendet werden um den Clients nur ihre eigenen Netze zu erlauben.

!!! info ""  
    Das Tunnel Netzwerk des Clients muss ein Subnetz des OpenVPN Server Tunnel Netzwerks sein.

![OPNsense_OpenVPN_CSO_Overview.png](../img/setup/OPNsense_OpenVPN_CSO_Overview.png?raw=true){: loading=lazy }

![OPNsense_OpenVPN_CSO_Edit.png](../img/setup/OPNsense_OpenVPN_CSO_Edit.png?raw=true){: loading=lazy }

![OPNsense_OpenVPN_Rules.png](../img/setup/OPNsense_OpenVPN_Rules.png?raw=true){: loading=lazy }

## IPsec
Die Einrichtung eines Site to Site IPsec Tunnels gestaltet sich unkompliziert, als Informationquelle kann [dieses Video](https://www.youtube.com/watch?v=KmoCfa0IxBk) genutzt werden, der einzige Unterschied besteht in der Verwendung von pfSense.

## DNS: Wildcard Einträge
DNS Wildcard Einträge müssen gemäß der [erweiterten Konfiguration des DNS Servers (`dnsmasq`)](https://docs.opnsense.org/manual/dnsmasq.html#advanced-settings) über die Shell erfolgen. Dies erfolgt jedes mal, wenn ein neuer Host hinzugefügt wird, da der DNS Eintrag `*.<vmhost>.secshell.net` nur so gesetzt werden kann ([siehe Forum Post](https://forum.opnsense.org/index.php?topic=5855.0)). Der SSH Server kann über `System -> General -> Administration` aktiviert werden:
```shell
# /usr/local/etc/dnsmasq.conf.d/dns.conf
address=/hostname.secshell.net/10.2.1.2
```

# Knowledge Base
### DNS Auflösung funktioniert über OpenVPN nicht
Wenn man mit dem VPN verbunden ist, und interne DNS Anfragen nicht korrekt aufgelöst werden, muss die DNS Search Domain hinzugefügt werden. Unter Linux funktioniert das mit dem Network Manager mithilfe des folgenden Kommandos:
```
nmcli c modify "Secure Shell Networks" ipv4.dns-search secshell.net
```
Anschließend muss die VPN Verbindung neu gestartet werden.
