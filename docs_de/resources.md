# Ressourcenverteilung

Jeder Proxmox VE Host erhält eine Identifikationsnummer (`0-9`), einen FQDN (`pveID.secshell.net`) und eine Interne IP Range (`10.ID.0.0/16`), die für diesen Host frei verwendet werden kann.
Durch das Vorgeben der IP Range werden spätere Probleme z. B. bei den IPsec Tunneln verhindert.  

Für den ersten Host entsteht somit der FQDN `pve0.secshell.net`, für den die Interne IP Range 10.0.0.0/16 verwendet wird.

Die verbleibenden Subnetze, die während der Planung nicht für die Hosts vorgesehen wurden, können beantragt und bei Zustimmung frei verwendet werden.
Die Beantragung dient lediglich zur Prüfung ob das gewünschte Subnetz bereits verwendet wird.

## Hosts
Der Proxmox VE Host `pve0` dient zu Testzwecken und wird daher nicht weiter ausgeführt.  
`pve1` und `pve2` sind Dedicated Server aus der AX-Reihe der Hetzner Online GmbH.  

Das IPv4 Netzwerk `10.1.0.0/16` wird auf beiden Hosts in zwei 17er Netzwerke aufgeteilt.  

- Das erste Netz (`10.1.0.0/17`) wird weiter (in 30er bzw 29er Netze) aufgeteilt, wodurch anschließend die Virtuellen Maschienen und LXC Container über VLAN's angebunden werden.
- Das zweite Netz (`10.1.128.0/17`) wird weiter in 29er Netze aufgeteilt und anschließend für OpenVPN Client Specfic Overrides verwendet.

### pve2
Da der Host `pve2` von mehreren Partnern genutzt wird, wurden die Netzresourcen aus dem ersten Netz sowie die öffentlichen Addressen gemäß der folgenden Tabelle verteilt.

!!! info ""
    Die aufgelisteten ID's gelten für Proxmox VM/LXC, VLAN ID's, sowie IPv6 Adressen: <code>2a01:4f8:10a:b88:ID::/80</code>

| Verwendung / Partner   |     ID's    | IPv4 Netzwerke                               |
|:-----------------------|:-----------:|:---------------------------------------------|
| DNS                    | 100         | 10.2.0.0/30                                  |
| Allgemeine Verwendung  | 101  -  109 | 10.2.0.4/30 - 10.2.0.252/30                  |
|                        |             | 88.99.59.69/32 + 88.99.59.71/32              |
| A                      | 110  -  139 | 10.2.1.0/24                                  |
| B                      | 140  -  169 | 10.2.2.0/24                                  |
| C                      | 170  -  199 | 10.2.3.0/24                                  |
| VPN                    |             | 10.2.128.0/17                                |

Die IPv4 Adresse der OPNsense (`88.99.59.71`) steht mittels Port Forwarding jedem Partner zur Verfügung.
Für Web-Protokolle (`http`/`https`) kommt hierbei der Reverse Proxy HAProxy zum Einsatz.

Die Freenom-Domains `secshell.cf`, `secshell.ml`, `secshell.tk`, `secshell.gq` und `secshell.ga` können für Tests verwendet werden. Da über die ACME DNS-01 Challenge keine Zertifikate angefordert werden können, muss hierfür zwingend die TLS-01 Challenge verwendet werden.  
Die Domain `secshell.net` wird abgesehen, von den Subdomains `pve[0-9].secshell.net`, hauptsächlich Intern genutzt.
