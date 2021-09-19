# Proxmox VE
Virtual machines and LXC containers are run on the dedicated server using Proxmox.

## Installation of the Proxmox Virtual Environment
The installation of Proxmox can be done via the Proxmox Installer, or by [installing the Proxmox packages on a Debian system](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_Buster).
Usually the operating system is installed at Hetzner via [InstallImage](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/) in the rescue system. Since ZFS is not supported by the InstallImage, we decided to install via a remote console with the Proxmox Installer.

![Proxmox_Setup_Mount_ISO.png](../img/setup/proxmox/Proxmox_Setup_Mount_ISO.png?raw=true){: loading=lazy }
![Proxmox_Setup_Disks.png](../img/setup/proxmox/Proxmox_Setup_Disks.png?raw=true){: loading=lazy }

After the installation, the correct APT repositories were set, the warning about the non-existent subscription at login was disabled, and more packages were installed:
```bash
# disable enterprise repositories
sed -i -e 's/^/#/g' /etc/apt/sources.list.d/pve-enterprise.list

# enable no-subscription repositories
echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" >> /etc/apt/sources.list.d/pve-no-subscription.list

# disable 'no valid subscription' warning on login
# https://github.com/rickycodes/pve-no-subscription
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/rickycodes/pve-no-subscription/main/no-subscription-warning.sh | sh

# install ovs (required for internal vlans)
apt update
apt upgrade -y
apt install -y openvswitch-switch
```

After that you can use the Proxmox WebGUI to create the OVS bridge for the internal network (leave default values).
![Proxmox_Networks.png](../img/setup/proxmox/Proxmox_Networks.png?raw=true){: loading=lazy }

Then the virtual machines are created. Virtual machines and containers that should be behind the OPNsense are configured to the network interface vmbr1 with a corresponding VLAN ID.
![Proxmox_VM_Network.png](../img/setup/proxmox/Proxmox_VM_Network.png?raw=true){: loading=lazy }
![Proxmox_LXC_Network.png](../img/setup/proxmox/Proxmox_LXC_Network.png?raw=true){: loading=lazy }

### Create OPNsense VM
For the OPNsense network interface that is to be used for the internal network, a multiplier of 8 should be used. The VLAN trunk is then configured via the console (in the file `/etc/pve/qemu-server/100.conf`):
```bash
# ...
net0: virtio=AA:BB:CC:DD:EE:FF,bridge=vmbr0,firewall=1
net1: virtio=FF:EE:DD:CC:BB:AA,bridge=vmbr1,firewall=1,queues=8,trunks=1-4095
# ...
```
