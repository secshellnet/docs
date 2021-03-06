# Proxmox VE
Auf dem dedizierten Server werden Virtuelle Maschienen und LXC Container mittels Proxmox betrieben.

## Installation des Proxmox Virtual Environments
Die Installation von Proxmox kann über den Proxmox Installer, oder durch die [Installation der Proxmox Pakete auf einem Debian System](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_Buster) erfolgen.
Für gewöhnlich wird das Betriebsystem bei Hetzner über [InstallImage](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/) im Rescue System installiert. Da ZFS vom InstallImage nicht unterstützt wird, haben wir uns für die Installation über eine Remote Konsole mit dem Proxmox Installer entschieden.

![Proxmox_Setup_Mount_ISO.png](../img/setup/proxmox/Proxmox_Setup_Mount_ISO.png?raw=true){: loading=lazy }
![Proxmox_Setup_Disks.png](../img/setup/proxmox/Proxmox_Setup_Disks.png?raw=true){: loading=lazy }

Nach der Installation wurde die korrekten APT Repositories gesetzt, die Warnung über das nicht existierende Abonnement beim Login deaktiviert und weitere Pakete installiert:
```bash
# disable enterprise repositories
sed -i -e 's/^/#/g' /etc/apt/sources.list.d/pve-enterprise.list

# enable no-subscription repositories
echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" >> /etc/apt/sources.list.d/pve-no-subscription.list

# disable 'no valid subscription' warning on login
# https://johnscs.com/remove-proxmox51-subscription-notice/
#sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service

# install ovs (required for internal vlans)
apt update
apt upgrade -y
apt install -y openvswitch-switch
```

Die Konfiguration von ZFS kann [diesem englischen Blogeintrag](https://www.dlford.io/memory-tuning-proxmox-zfs/) entnommen werden.

Im Anschluss kann man über die Proxmox WebGUI, die OVS Bridge für das Interne Netzwerk anlegen (Standartwerte belassen).
![Proxmox_Networks.png](../img/setup/proxmox/Proxmox_Networks.png?raw=true){: loading=lazy }

Anschließend werden die Virtuellen Maschienen angelegt. Virtuelle Maschienen und Container, welche im Internen Netzwerk sein sollen, werden auf das Netzwerkinterface `vmbr1` mit einer entsprechenden VLAN ID konfiguriert.
![Proxmox_VM_Network.png](../img/setup/proxmox/Proxmox_VM_Network.png?raw=true){: loading=lazy }
![Proxmox_LXC_Network.png](../img/setup/proxmox/Proxmox_LXC_Network.png?raw=true){: loading=lazy }

### OPNsense VM anlegen
Bei der OPNsense Netzwerkschnittstelle, welche für das Interne Netzwerk verwendet werden soll, sollte einen Multiplier von 8 verwendet werden. Über die Konsole wird anschließend (in der Datei `/etc/pve/qemu-server/100.conf`) der VLAN Trunk konfiguriert:
```bash
# ...
net0: virtio=AA:BB:CC:DD:EE:FF,bridge=vmbr0,firewall=1
net1: virtio=FF:EE:DD:CC:BB:AA,bridge=vmbr1,firewall=1,queues=8,trunks=1-4095
# ...
```
