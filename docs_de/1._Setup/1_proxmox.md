# Proxmox VE
Auf dem dedizierten Server werden Virtuelle Maschienen und LXC Container mittels Proxmox betrieben.

## Installation des Proxmox Virtual Environments
Die Installation von Proxmox kann über den Proxmox Installer, oder durch die [Installation der Proxmox Pakete auf einem Debian System](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_Buster) erfolgen.
Für gewöhnlich wird das Betriebsystem bei Hetzner über [InstallImage](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/) im Rescue System installiert. Da ZFS vom InstallImage nicht unterstützt wird, haben wir uns für die Installation über eine Remote Konsole mit dem Proxmox Installer entschieden.

![Proxmox_Setup_Mount_ISO.png](../img/setup/Proxmox_Setup_Mount_ISO.png?raw=true){: loading=lazy }
![Proxmox_Setup_Disks.png](../img/setup/Proxmox_Setup_Disks.png?raw=true){: loading=lazy }

Nach der Installation wurde die korrekten APT Repositories gesetzt, die Warnung über das nicht existierende Abonnement beim Login deaktiviert und weitere Pakete installiert:
```bash
# disable enterprise repositories
sed -i -e 's/^/#/g' /etc/apt/sources.list.d/pve-enterprise.list

# enable no-subscription repositories
echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" >> /etc/apt/sources.list.d/pve-no-subscription.list

# disable 'no valid subscription' warning on login
#sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
sed -i.backup -z "s/res === null || res === undefined || \!res || res\n\t\t\t.data.status.toLowerCase() \!== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service

# install ovs (required for internal vlans)
apt update
apt upgrade -y
apt install -y openvswitch-switch

# install dark theme
wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh
bash PVEDiscordDark.sh install
```

Falls nach einem Update das Dark Theme weg sein sollte, wird `bash PVEDiscordDark.sh install` erneut ausgeführt, möglicherweise muss es zuvor entfernt werden: `bash PVEDiscordDark.sh uninstall`.

Im Anschluss kann man über die Proxmox WebGUI, die OVS Bridge für das Interne Netzwerk anlegen (Standartwerte belassen).
![Proxmox_Networks.png](../img/setup/Proxmox_Networks.png?raw=true){: loading=lazy }

Anschließend werden die Virtuellen Maschienen anlegen. Virtuelle Maschienen und Container die hinter der OPNsense liegen sollen, werden auf das Netzwerkinterface vmbr1 mit einer entsprechenden VLAN ID konfiguriert.
![Proxmox_LXC_Network.png](../img/setup/Proxmox_LXC_Network.png?raw=true){: loading=lazy }

### OPNsense VM anlegen
Bei der OPNsense Netzwerkschnittstelle, die für das Interne Netzwerk verwendet werden soll, sollte einen Multiplier von 8 verwendet werden. Über die Konsole wird anschließend (in der Datei `/etc/pve/qemu-server/100.conf`) der VLAN Trunk konfiguriert:
```bash
# ...
net0: virtio=AA:BB:CC:DD:EE:FF,bridge=vmbr0,firewall=1
net1: virtio=FF:EE:DD:CC:BB:AA,bridge=vmbr1,firewall=1,queues=8,trunks=1-4095
# ...
```

Die Konfiguration der OPNsense wird in einem eigenen Kapitel erläutert.  
Die zusätzliche gebuchten IPv4 Adressen / Subnetze - die sich außerhalb des Netzwerkes der Haupt IPv4 Adressen befinden - müssen über den Host Adapter geroutet werden, dafür wird die WAN Bridge in `/etc/network/interfaces` wie folgt erweitert. Außerdem wird die default Route für das IPv6 Gateway (`fe80::1`) über `vmbr0` hinzugefügt, da Pakete zum Gateway sonst über `vmbr1` gerouted wird:
```bash
# ...
	up ip route add 176.9.198.64/29 dev vmbr0

        up ip -6 route add default via fe80::1 dev vmbr0

	up sysctl -w net.ipv4.ip_forward=1
	up sysctl -w net.ipv6.conf.all.forwarding=1
# ...
```
Da sich die zusätzlich gebuchte IPv4 Adresse für die Firewall im gleichen Subnetz wie die Haupt IPv4-Adresse befindet, muss hier nur das Subnetz gerouted werden.

## Kostenlose Stroagebox BX10
Im Hetzner Robot kann man zu einem dedicated Server eine kostenlose BX10 Storage Box bestellen.
Um die Storage Box in Proxmox einzubinden, muss der Samba-Support aktiviert werden:
![Hetzner_BX10.png](../img/setup/Hetzner_BX10.png?raw=true){: loading=lazy }

Anschließend kann die Storagebox in Proxmox unter Datacenter -> Storage eingebunden werden:
![Proxmox_BX10.png](../img/setup/Proxmox_BX10.png?raw=true){: loading=lazy }

## Firewallregeln des Hosts
Da der Host nur von Vertrauenswürdigen Adressen erreichbar sein soll, wird die Firewall im Hetzner Robot eingerichtet:
![Hetzner_Host_Firewall.png](../img/setup/Hetzner_Host_Firewall.png?raw=true){: loading=lazy }

Durch die gesetzten Firewallregeln können nur noch die bestellten IP Adressen auf das Webinterface und den SSH Daemon zugreifen. Zusätzlich wurden Pakete einer weitere IPv4 Adresse erlaubt, welche genutzt wird um mit dem Host zu interagieren, falls Probleme mit der OPNsense auftreten.

Regel 9 und 10 sorgen dafür, das der Host Antworten aus dem Internet erhalten kann und DNS Anfragen senden darf. [Dies ist im Hetzner Wiki beschrieben.](https://docs.hetzner.com/de/robot/dedicated-server/firewall/#ausgehende-tcp-verbindungen)
