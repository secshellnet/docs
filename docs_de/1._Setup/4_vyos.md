# VyOS

Alternativ zu OPNsense kann als Router VyOS verwendet werden.
VyOS bietet mehr Optionen als die OPNsense, die jedoch für die meisten Anwender nicht notwendig sind. Im Gegensatz zu OPNsense ist VyOS vollständig Konsolenorientiert - es gibt keine WebGUI wie bei OPNsense!
Das FRR Plugin der OPNsense mit dem OSPF und BGP umgesetzt werden kann ist nicht das stabilste, VyOS kann dies ohne Plugin "out of the box" recht stabil (derzeit mit der limitierung das local link ipv6 adressen nicht funktionieren).
Des Weiteren unterstützt OPNsense nur eine Routing Tabelle, mit der Option über die Firewall pakete anhand einer firewall regel auf ein anderes gateway umzuleiten. Für IPv4 funktionierte dies bei uns auch Problemlos. IPv6 macht hierbei jedoch leider große Probleme. 

## Installation
Nachdem man VyOS von der ISO gestartet hat und sich mit den Zugangsdaten `vyos`/`vyos` eingeloggt hat, kann es mit `install image` installiert werden.

## Firewall Rules Convention
Da einem Interface nur ein Ruleset zugewiesen werden kann, müssen für die meisten Interfaces eigene Ruleset's angelegt werden.  
`local` bezeichnet Pakete die als `destination` den VyOS Router gesetzt haben.  
`in` benzeichnet Pakete die lediglich durch das Interface kommen, aber nicht zum Router selbst wollen.

### LOCAL (used as local ipv4 ruleset for vlans and wireguard non bgp peers (road warrior vpn))
* 5: accept `VYOS_IPV4_INTERN`
* 6: accept related, established

### LOCAL-6 (used as local ipv6 ruleset for vlans and wireguard non bgp peers (road warrior vpn))
* 5: accept `VYOS_IPV6_GUA`
* 6: accept related, established
* 8: accept icmpv6

### BGP-LOCAL (used as local ipv4 ruleset for wireguard bgp peers)
* 5: accept `VYOS_IPV4_INTERN`
* 6: accept related, established
* 7: accept bgp
* 9: accept snmp

### BGP-LOCAL-6 (used as local ipv6 ruleset for wireguard bgp peers)
* 5: accept `VYOS_IPV6_GUA`
* 6: accept related, established
* 7: accept bgp
* 8: accept icmpv6
* 9: accept snmp

### XXX-IN
* 5: accept !NET-PRIVATE
* 6: accept related, established

* 10: keycloak.pve2.secshell.net for oidc auth
* 11: pushgateway.monitoring.pve2.secshell.net
* 12: general.pve2.secshell.net:80 (debian pressed)
* 13: general.pve2.secshell.net:443 (debian pressed)

* host specific firewall rules start at: rule 100

### XXX-IN-6
* 5: accept !NET-PRIVATE
* 6: accept related, established
* 7: accept icmpv6

* 10: keycloak.pve2.secshell.net for oidc auth (NOT EXPOSED YET!)
* 11: pushgateway.monitoring.pve2.secshell.net
* 12: general.pve2.secshell.net:80 (debian pressed) (NOT EXPOSED YET!)
* 13: general.pve2.secshell.net:443 (debian pressed) (NOT EXPOSED YET!)

* host specific firewall rules start at: rule 100
