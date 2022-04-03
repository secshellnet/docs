# Storagebox
Im Hetzner Robot kann man zu einem dedicated Server eine kostenlose BX10 Storage Box bestellen.

## CIFS Mount
Um die Storage Box in Proxmox einzubinden, muss der Samba-Support aktiviert werden:  
![Kostenlose Storagebox buchen](../img/setup/storagebox/hetzner_robot.png?raw=true){: loading=lazy }

Anschließend kann die Storagebox entweder in Proxmox unter Datacenter -> Storage als CIFS eingebunden werden:  
![Storagebox in Proxmox VE einrichten](../img/setup/storagebox/proxmox_setup.png?raw=true){: loading=lazy }

## Directory Mount

Alternativ kann man die einrichtung Manuell vornehmen:
```
echo "password=<SECRET_PASSWORD>" > /etc/pve/priv/storage/bx10.pw

cat <<_EOF >> /etc/fstab
//u265162.your-storagebox.de/backup   /media/bx10     cifs     username=u265162,credentials=/etc/pve/priv/storage/bx10.pw    0      0
_EOF

mkdir /media/bx10

mount /media/bx10
```

Anschließend wird der folgende cronjob hinzugefügt:
```shell
# mount backup storage if mountpoint state is invalid
0 0 * * * /bin/bash -c '[[ ! -d /media/bx10 ]] && /usr/bin/mount /media/bx10'
``` 