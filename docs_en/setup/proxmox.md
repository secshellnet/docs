# Proxmox VE
Virtual machines and LXC containers are run on the dedicated server using Proxmox.

## Installation of the Proxmox Virtual Environment
The installation of Proxmox can be done via the Proxmox Installer, or by [installing the Proxmox packages on a Debian system](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_Buster).
Usually the operating system is installed at Hetzner via [InstallImage](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/) in the rescue system. Since ZFS is not supported by the InstallImage, we decided to install via a remote console with the Proxmox Installer.

![Proxmox_Setup_Mount_ISO.png](../img/setup/Proxmox_Setup_Mount_ISO.png?raw=true){: loading=lazy }
![Proxmox_Setup_Disks.png](../img/setup/Proxmox_Setup_Disks.png?raw=true){: loading=lazy }

After the installation, the correct APT repositories were set, the warning about the non-existent subscription at login was disabled, and more packages were installed:
```bash
# disable enterprise repositories
sed -i -e 's/^/#/g' /etc/apt/sources.list.d/pve-enterprise.list

# enable no-subscription repositories
echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" >> /etc/apt/sources.list.d/pve-no-subscription.list

# disable 'no valid subscription' warning on login
#sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
sed -i.backup -z "s/res === null || res === undefined || \!res || res\n\t\t.data.status.toLowerCase() \!== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service

# install ovs (required for internal vlans)
apt update
apt upgrade -y
apt install -y openvswitch-switch

# install dark theme
wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh
bash PVEDiscordDark.sh install
```

If the dark theme is gone after an update, `bash PVEDiscordDark.sh install` is executed again, it might be necessary to remove it first: `bash PVEDiscordDark.sh uninstall`.

After that you can use the Proxmox WebGUI to create the OVS bridge for the internal network (leave default values).
![Proxmox_Networks.png](../img/setup/Proxmox_Networks.png?raw=true){: loading=lazy }

Then the virtual machines are created. Virtual machines and containers that should be behind the OPNsense are configured to the network interface vmbr1 with a corresponding VLAN ID.
![Proxmox_LXC_Network.png](../img/setup/Proxmox_LXC_Network.png?raw=true){: loading=lazy }

### Create OPNsense VM
For the OPNsense network interface that is to be used for the internal network, a multiplier of 8 should be used. The VLAN trunk is then configured via the console (in the file `/etc/pve/qemu-server/100.conf`):
```bash
# ...
net0: virtio=AA:BB:CC:DD:EE:FF,bridge=vmbr0,firewall=1
net1: virtio=FF:EE:DD:CC:BB:AA,bridge=vmbr1,firewall=1,queues=8,trunks=1-4095
# ...
```

The configuration of the OPNsense is explained in a separate chapter.  
The additional booked IPv4 addresses / subnets - which are outside the network of the main IPv4 addresses - must be routed via the host adapter, for this the WAN bridge in `/etc/network/interfaces` is extended as follows:
```bash
# ...
	up ip route add 176.9.198.64/29 dev vmbr0

	up sysctl -w net.ipv4.ip_forward=1
	up sysctl -w net.ipv6.conf.all.forwarding=1
# ...
```
Since the additionally booked IPv4 address for the firewall is in the same subnet as the main IPv4 address, only the subnet must be routed here.

## Free Stroagebox BX10
In Hetzner Robot you can order a free BX10 storage box for a dedicated server.
To integrate the storage box in Proxmox, the Samba support must be activated:
![Hetzner_BX10.png](../img/setup/Hetzner_BX10.png?raw=true){: loading=lazy }

Afterwards the storage box can be integrated in Proxmox under Datacenter -> Storage:
![Proxmox_BX10.png](../img/setup/Proxmox_BX10.png?raw=true){: loading=lazy }

## Firewall rules of the host
Since the host should only be accessible from trusted addresses, the firewall is set up in Hetzner Robot:
![Hetzner_Host_Firewall.png](../img/setup/Hetzner_Host_Firewall.png?raw=true){: loading=lazy }

Due to the set firewall rules only the ordered IP addresses can access the web interface and the SSH daemon. Additionally, packets of another IPv4 address were allowed, which is used to interact with the host in case of problems with the OPNsense.

Rules 9 and 10 ensure that the host can receive responses from the Internet and send DNS queries. [This is described in the Hetzner Wiki.](https://docs.hetzner.com/robot/dedicated-server/firewall/#out-going-tcp-connections)

