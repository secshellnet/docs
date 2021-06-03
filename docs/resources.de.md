# Ressourcenverteilung

Jeder Proxmox VE Host erhält eine Identifikationsnummer (`0-9`), einen FQDN (`pveID.secshell.net`) und eine Interne IP Range (`10.ID.0.0/16`), die für diesen Host frei verwendet werden kann.
Durch das Vorgeben der IP Range werden spätere Probleme z. B. bei den IPsec Tunneln verhindert.  

Für den ersten Host entsteht somit der FQDN `pve0.secshell.net`, für den die Interne IP Range 10.0.0.0/16 verwendet wird.

Die verbleibenden Subnetze, die während der Planung nicht für die Hosts vorgesehen wurden, können beantragt und bei Zustimmung frei Verwendet werden.
Die Beantragung dient lediglich zur Prüfung ob das gewünschte Subnetz bereits verwendet wird.

## Hosts
Der Proxmox VE Host `pve0` dient zu Testzwecken und wird daher nicht weiter ausgeführt.  
`pve1` und `pve2` sind Dedicated Server aus der AX-Reihe der Hetzner Online GmbH.  


### pve1
Das IPv4 Netzwerk `10.1.0.0/16` wird in zwei 17er Netzwerke aufgeteilt.

- Das erste Netz (`10.1.0.0/17`) wird weiter (in 30er bzw 29er Netze) aufgeteilt, wodurch anschließend die Virtuellen Maschienen und LXC Container über VLAN's angebunden werden.
- Das zweite Netz (`10.1.128.0/17`) wird weiter in 29er Netze aufgeteilt und anschließend für OpenVPN Client Specfic Overrides verwendet. 


### pve2
Da der Host `pve2` von mehreren Partnern genutzt wird, wurden die Resourcen anders als bei `pve1` aufgeteilt.

!!! info ""
    Die aufgelisteten ID's gelten für Proxmox VM/LXC sowie VLAN ID's

| Verwendung / Partner              |     ID's    |         IPv4 Netzwerke        |     IPv6 Netzwerke        |
|:----------------------------------|:-----------:|:------------------------------|:--------------------------|
| Allgemeine Verwendung (z. B. VPN) | 100 bis 109 | 10.2.0.0/24                   |                           |
|                                   |             | 88.99.59.71                   | 2a01:4f8:10a:b88::/66     |
| A                                 | 110 bis 139 | 10.2.1.0/24                   |                           |
|                                   |             | 176.9.198.65 und 176.9.198.66 | 2a01:4f8:10a:b88::4000/66 |
| B                                 | 140 bis 169 | 10.2.2.0/24                   |                           |
|                                   |             | 176.9.198.67 und 176.9.198.68 | 2a01:4f8:10a:b88::8000/66 |
| C                                 | 170 bis 199 | 10.2.3.0/24                   |                           |
|                                   |             | 176.9.198.69 und 176.9.198.70 | 2a01:4f8:10a:b88::c000/66 |

Die IPv4 Adresse der OPNsense (`88.99.59.71`) steht mittels Port Forwarding jedem Partner zur Verfügung.
Für Web-Protokolle (`http`/`https`) kommt hierbei der Reverse Proxy HAProxy zum Einsatz.

Die Freenom-Domains `secshell.cf`, `secshell.ml`, `secshell.tk`, `secshell.gq` und `secshell.ga` können für Tests verwendet werden. Da über die ACME DNS-01 Challenge keine Zertifikate angefordert werden können, muss hierfür zwingend die TLS-01 Challenge verwendet werden.  
Die Domain `secshell.net` wird abgesehen, von den Subdomains `pve[0-9].secshell.net`, hauptsächlich Intern genutzt.
