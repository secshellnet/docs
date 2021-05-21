# Ressourcenverteilung

Jeder Proxmox VE Host erhält eine Identifikationsnummer (`0-9`), einen FQDN (`pveID.secshell.net`) und eine Interne IP Range (`10.ID.0.0/16`), die für diesen Host frei verwendet werden kann.
Durch das Vorgeben der IP Range werden spätere Probleme z. B. bei den IPsec Tunneln verhindert.  

Für den ersten Host entsteht somit der FQDN `pve0.secshell.net`, für den die Interne IP Range 10.0.0.0/16 verwendet wird.

Die verbleibenden Subnetze, die während der Planung nicht für die Hosts vorgesehen wurden, können beantragt und bei Zustimmung frei Verwendet werden.
Die Beantragung dient lediglich zur Prüfung ob das gewünschte Subnetz bereits verwendet wird.

## Hosts
Der Proxmox VE Host `pve0` dient zu Testzwecken und wird daher nicht weiter ausgeführt.  
`pve1` und `pve2` sind Dedicated Server aus der AX-Reihe der Hetzner Online GmbH.  

Die Verwendung der Netzwerkressourcen wird nun am Beispiel von `pve1` erläutert:  
Das IPv4 Netzwerk `10.1.0.0/16` wird in zwei 17er Netzwerke aufgeteilt.

- Das erste Netz (`10.1.0.0/17`) wird weiter (in 30er bzw 29er Netze) aufgeteilt, wodurch anschließend die Virtuellen Maschienen und LXC Container über VLAN's angebunden werden.
- Das zweite Netz (`10.1.128.0/17`) wird weiter in 29er Netze aufgeteilt und anschließend für OpenVPN Client Specfic Overrides verwendet. 
