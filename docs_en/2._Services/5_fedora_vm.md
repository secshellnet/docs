# Fedora Server VM

The automatic storage configuration is going to create a lvm with xfs as root filesystem.
Alternativly you can do the partitioning yourself (choose: Advanced Custom (Blivet-GUI))

<video width="100%" height="240" controls>
  <source src="../../video/services/debian11_vm.mp4" type="video/mp4">
</video>

![Booted](../img/services/fedora_vm_booted.png?raw=true){: loading=lazy }

## Webconsole

![Webconsole Login](../img/services/fedora_vm_webconsole_login.png?raw=true){: loading=lazy }

![Webconsole](../img/services/fedora_vm_webconsole.png?raw=true){: loading=lazy }

![Webconsole Updates](../img/services/fedora_vm_webconsole_updates.png?raw=true){: loading=lazy }

![Webconsole Updates](../img/services/fedora_vm_webconsole_updates_running.png?raw=true){: loading=lazy }

![Webconsole Storage](../img/services/fedora_vm_webconsole_storage.png?raw=true){: loading=lazy }

![Webconsole Networking](../img/services/fedora_vm_webconsole_networking.png?raw=true){: loading=lazy }

### Podman Plugin
```shell
sudo dnf install -y cockpit-podman
sudo systemctl start --user podman
```

![Webconsole Podman](../img/services/fedora_vm_webconsole_podman.png?raw=true){: loading=lazy }

### QEMU Plugin
```shell
sudo dnf install -y cockpit-machines
```

![Webconsole Machines](../img/services/fedora_vm_webconsole_machines.png?raw=true){: loading=lazy }

## Docker
If you prefere docker over podman you can install it:
```bash
# install docker
curl https://get.docker.com | sudo bash

# adjust selinux policies
sudo ausearch -c 'runc' --raw | audit2allow -M my-runc
sudo semodule -X 300 -i my-runc.pp

# enable autostart and start docker daemon
sudo systemctl enable --now docker
```
