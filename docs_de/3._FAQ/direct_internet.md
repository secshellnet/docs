# Direkte Internetverbindung

Es gibt zwei Wege LXC Container und Virtuelle Maschienen (im weiteren VM genannt) direkt mit dem Internet zu verbinden (Public IP).  
1. [Verbindung über OPNsense (1:1 NAT)](../setup/opnsense.md)  
2. Direktes Anbinden der VM an das Internet über das Netzwerkinterface vmbr0.  

!!! warning ""
    Wenn die VM direkt an vmbr0 angebunden wird, müssen sämtliche Firewall Rules auf der VM erfolgen.  

## IPv4 Beispielkonfiguration

- IPv4 Adresse: 176.9.198.70/32  
- (Netzfremdes-) Gateway: 88.99.59.89  
- DNS Server: 1.1.1.1

![Beispielkonfiguration eines LXC](../img/faq/direct_internet_lxc.png?raw=true){: loading=lazy }

## IPv6 Beispielkonfiguration

- IPv6 Adresse: 2a01:4f8:10a:b88::5/128  
- Gateway: fe80::1  
- DNS Server: 2606:4700:4700::1111  

![Beispielkonfiguration eines LXC](../img/faq/direct_internet_lxc_v6.png?raw=true){: loading=lazy }
