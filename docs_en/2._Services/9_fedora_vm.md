# Fedora Server VM

![Grub: Test this media & install Fedora 34](../img/services/fedora_vm_grub.png?raw=true){: loading=lazy }

![Language selection](../img/services/fedora_vm_language.png?raw=true){: loading=lazy }

![Installation Summary](../img/services/fedora_vm_overview.png?raw=true){: loading=lazy }

![Keyboard](../img/services/fedora_vm_keyboard.png?raw=true){: loading=lazy }

The automatic storage configuration is going to create a lvm with xfs as root filesystem.
Alternativly you can do the partitioning yourself (choose: Advanced Custom (Blivet-GUI))
![Disks](../img/services/fedora_vm_disks.png?raw=true){: loading=lazy }

![Software Selection](../img/services/fedora_vm_software.png?raw=true){: loading=lazy }

Configuration of the VM in the OPNsense network:
- TODO create this image...
![Network: OPNsense](../img/services/fedora_vm_network.png?raw=true){: loading=lazy }

Configuration of the VM with a public ipv4 address:
![Network: Direct connected Internet](../img/services/fedora_vm_network_direct.png?raw=true){: loading=lazy }

![Time & Date](../img/services/fedora_vm_timezone.png?raw=true){: loading=lazy }

![Root Password](../img/services/fedora_vm_root.png?raw=true){: loading=lazy }

![User Creation](../img/services/fedora_vm_user.png?raw=true){: loading=lazy }

![Installation Summary: Done](../img/services/fedora_vm_done.png?raw=true){: loading=lazy }

Start the installation.

![Reboot](../img/services/fedora_vm_reboot.png?raw=true){: loading=lazy }

![Booted](../img/services/fedora_vm_booted.png?raw=true){: loading=lazy }

## Webconsole

![Webconsole Login](../img/services/fedora_vm_webconsole_login.png?raw=true){: loading=lazy }

![Webconsole](../img/services/fedora_vm_webconsole.png?raw=true){: loading=lazy }

![Webconsole Updates](../img/services/fedora_vm_webconsole_updates.png?raw=true){: loading=lazy }

![Webconsole Updates](../img/services/fedora_vm_webconsole_updates_running.png?raw=true){: loading=lazy }

![Webconsole Storage](../img/services/fedora_vm_webconsole_storage.png?raw=true){: loading=lazy }

![Webconsole Networking](../img/services/fedora_vm_webconsole_networking.png?raw=true){: loading=lazy }

## Docker
```bash
# install docker
curl https://get.docker.com | sudo bash

# adjust selinux policies
sudo ausearch -c 'runc' --raw | audit2allow -M my-runc
sudo semodule -X 300 -i my-runc.pp

# enable autostart and start docker daemon
sudo systemctl enable --now docker
```
