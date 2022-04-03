# Storagebox
You can order a free bx10 storage box for every dedicated server in the Hetzner Robot.  

## CIFS mount
To integrate the storage box in Proxmox, the Samba support must be activated:
![Get a free bx10 storagebox](../img/setup/hetzner_robot.png?raw=true){: loading=lazy }

Afterwards the storage box can be integrated in Proxmox under Datacenter -> Storage:
![Setup storagebox in Proxmox VE](../img/setup/storagebox/proxmox_setup.png?raw=true){: loading=lazy }

## Directory mount
You can also set this manuelle:
```
echo "password=<SECRET_PASSWORD>" > /etc/pve/priv/storage/bx10.pw

cat <<_EOF >> /etc/fstab
//u265162.your-storagebox.de/backup   /media/bx10     cifs     username=u265162,credentials=/etc/pve/priv/storage/bx10.pw    0      0
_EOF

mkdir /media/bx10

mount /media/bx10
```

Afterwards add the following cronjob:
```shell
# mount backup storage if mountpoint state is invalid
0 0 * * * [[ ! -d /media/bx10 ]] && /usr/bin/mount /media/bx10
``` 