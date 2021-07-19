# Direkte Internetverbindung

Es gibt zwei Wege LXC Container und Virtuelle Maschienen (Im Weiteren Vm Genannt) Direkt Mit Dem Internet Zu Verbinden (Public Ip).  
1. [Verbindung über OPNsense (1:1 NAT)](../setup/opnsense.md)  
2. Direktes Anbinden der VM an das Internet über das Netzwerkinterface vmbr0.  

!!! warning ""
    Wenn die VM direkt an vmbr0 angebunden wird, müssen sämtliche Firewall Rules auf der VM erfolgen.  

Beispielkonfiguration:

- IP Adresse: 176.9.198.70  
- Netzmaske: 255.255.255.255 (32er Netz)  
- (Netzfremdes-) Gateway: 88.99.59.89  

![Beispielkonfiguration eines LXC](../img/faq/direct_internet_lxc.png?raw=true){: loading=lazy }
