# Hetzner Firewall
Da der Host nur von Vertrauenswürdigen Adressen erreichbar sein soll, wird die Firewall im Hetzner Robot eingerichtet:
![Firewallregeln](../img/setup/firewall/firewall.png?raw=true){: loading=lazy }

Durch die gesetzten Firewallregeln können nur noch die bestellten IP Adressen auf den Host zugreifen. Zusätzlich wurden Pakete einer weitere IPv4 Adresse erlaubt, welche genutzt wird um mit dem Host zu interagieren, falls Probleme mit der OPNsense auftreten.

Regel 6, 7 und 8 sorgen dafür, das der Host Antworten aus dem Internet erhalten kann und DNS sowie NTP Anfragen senden darf. [Dies ist im Hetzner Wiki beschrieben.](https://docs.hetzner.com/de/robot/dedicated-server/firewall/#ausgehende-tcp-verbindungen)
