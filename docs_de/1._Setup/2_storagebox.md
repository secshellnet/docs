# Storagebox
Im Hetzner Robot kann man zu einem dedicated Server eine kostenlose BX10 Storage Box bestellen.
Um die Storage Box in Proxmox einzubinden, muss der Samba-Support aktiviert werden:  
![Kostenlose Storagebox buchen](../img/setup/storagebox/hetzner_robot.png?raw=true){: loading=lazy }

Anschließend kann die Storagebox entweder in Proxmox unter Datacenter -> Storage als CIFS eingebunden werden:  
![Storagebox in Proxmox VE einrichten](../img/setup/storagebox/proxmox_setup.png?raw=true){: loading=lazy }

Alternativ kann man die einrichtung Manuell vornehmen (unserer Erfahrung funktioniert dies etwas stabiler):
```
echo "password=<SECRET_PASSWORD>" > /etc/pve/priv/storage/bx10.pw

cat <<_EOF >> /etc/fstab
//u265162.your-storagebox.de/backup   /media/bx10     cifs     username=u265162,credentials=/etc/pve/priv/storage/bx10.pw    0      0
_EOF

mkdir /media/bx10

mount /media/bx10
```