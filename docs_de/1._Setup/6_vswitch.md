# vSwitch
Die von Hetzner angebotenen vSwitches können zum Verbinden von mehreren Servern verwendet werden. Die Einrichtung eines vSwitches welcher nur für Dedicated Server gedacht ist kann der [Hetzner Dokumentation](https://docs.hetzner.com/de/robot/dedicated-server/network/vswitch/) entnommen werden. Im folgenden erläutern wir die Einrichtung eines vSwitch mit einem Hetzner Cloud Netzwerk. Wir verwenden ein 24er Netzwerk, außerhalb des Netzwerkes 10.0.0.0/8 um keine Konflikte mit den Internen Netzwerken zu erhalten.

## Einrichtung des Cloudnetzwerkes, vSwitches und Cloudservers
![Hetzner Cloud: Netzwerke](../img/setup/vswitch/vswitch_create1.png?raw=true){: loading=lazy }
![Hetzner Cloud: Netzwerk erstellen](../img/setup/vswitch/vswitch_create2.png?raw=true){: loading=lazy }
![Hetzner Robot: vSwitch Menü](../img/setup/vswitch/vswitch_create3.png?raw=true){: loading=lazy }
![Hetzner Robot: vSwitch erstellen](../img/setup/vswitch/vswitch_create4.png?raw=true){: loading=lazy }
![Hetzner Robot: Dedicated Server zu vSwitch hinzufügen](../img/setup/vswitch/vswitch_create5.png?raw=true){: loading=lazy }
![Hetzner Cloud: Subnetz hinzufügen](../img/setup/vswitch/vswitch_create6.png?raw=true){: loading=lazy }
![Hetzner Cloud: Subnetz Konfigurationshinweis](../img/setup/vswitch/vswitch_create7.png?raw=true){: loading=lazy }

Der Cloudserver kann schließlich im 28er Subnetz für Cloudserver hinzugefügt werden, die Konfiguration erfolgt automatisch:
![Hetzner Cloud: Cloudserver hinzufügen](../img/setup/vswitch/vswitch_create8.png?raw=true){: loading=lazy }
![Hetzner Cloud: Subnetzübersicht](../img/setup/vswitch/vswitch_create9.png?raw=true){: loading=lazy }
![Hetzner Cloud: Netzwerkkonfiguration Cloudserver](../img/setup/vswitch/vswitch_cloudserver.png?raw=true){: loading=lazy }

Falls die Firewall des Dedicated Servers aktiviert wurde, muss eine Firewall Regel erstellt werden, die Pakete in das erstellte Subnetz erlaubt. In diesem Fall wurde eine Firewall Regel erstellt, die das gesamte Private 16er Netzwerk abdeckt, sodass bei weiteren vSwitches in diesem Netzsegment (192.160.0.0/16) keine weitere Anpassung erforderlich ist: 
![Hetzner Robot: Firewall](../img/setup/vswitch/vswitch_firewall.png?raw=true){: loading=lazy }

## Einrichtung des Dedicated Servers
Zuerst muss das Netzwerkinterface `vmbr0` VLAN Fähig gemacht werden:
![VLAN Awareness in `vmbr0`](../img/setup/vswitch/vswitch_pve_vlan_aware.png?raw=true){: loading=lazy }


### Einrichtung der OPNsense
Nachdem der Host neugestartet wurde, kann das Interface in der OPNsense angelegt werden.
![VLAN anlegen](../img/setup/vswitch/vswitch_opnsense_interface1.png?raw=true){: loading=lazy }
![Interface erstellen](../img/setup/vswitch/vswitch_opnsense_interface2.png?raw=true){: loading=lazy }
![Interface konfigurieren](../img/setup/vswitch/vswitch_opnsense_interface3.png?raw=true){: loading=lazy }

Nachdem man die Firewall für dieses Interface konfiguriert hat, muss noch das Gateway erstellt hatten. Das Gateway erhält die erste verwendbare Adresse des verwendeten Netzwerkes:
![Gateway: Konfiguration](../img/setup/vswitch/vswitch_opnsense_gateway1.png?raw=true){: loading=lazy }
![Gateway: Übersicht](../img/setup/vswitch/vswitch_opnsense_gateway2.png?raw=true){: loading=lazy }

Schlussendlich muss das erstellte 24er Netzwerk noch über das Gateway des 28er Netzwerkes des vSwitch gerouted werden, dazu wird eine Statische Route in der OPNsense angelegt:
![Route: Konfiguration](../img/setup/vswitch/vswitch_opnsense_route.png?raw=true){: loading=lazy }

### Einrichtung in einem LXC oder einer VM
Desweiteren können LXC oder virtulle Maschinen direkt in das vSwitch Netzwerk hinzugefügt werden. Dazu muss beim erstellen lediglich das VLAN 4000 auf dem `vmbr0` Interface gewählt werden 
und eine IPv4 Adresse aus dem entsprechenden Netzwerk vergeben werden (z.B. 192.168.30.19).
