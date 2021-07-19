# SFTP Share (Alpine 3.13)
Die Installation kann über das [install_sftp_share.sh](./sftp_share.sh) Script erfolgen, ganz oben muss die Konfiguration (Nutzerliste) angepasst werden. Danach können neue Benutzer mithilfe des [sftp_share_adduser.sh](./sftp_share_adduser.sh) Scripts angelegt werden.

Zuerst wird `openssh-server` installiert:
```shell
echo > /etc/motd

apk add --update --no-cache openssh-server
mkdir -p /etc/ssh/authorized_keys
```

Nun fügen wir die Nutzer hinzu:
```shell
adduser --shell=/bin/false --disabled-password tom
passwd -u tom
echo "ssh-rsa ....." > /etc/ssh/authorized_keys/tom
chmod o-r /home/tom
```

Anschließend wird die SSH Konfiguration angepasst. Der zweite Teil der Anpassung muss für jeden Nutzer erfolgen (ganz am Ende 1x `Match all` genügt.)
```shell
# change location of authorized keys file (.ssh/authorized_keys is no longer required so it can be removed)
sed -i 's|AuthorizedKeysFile.*|AuthorizedKeysFile /etc/ssh/authorized_keys/%u|g' /etc/ssh/sshd_config
# add configuration for user tom (you need to do this for every user that should access the sftp share)
cat <<EOF >> /etc/ssh/sshd_config
Match User tom
   ChrootDirectory /home
   ForceCommand internal-sftp -d /tom
   AllowTTY no
   AllowTCPForwarding no
   X11Forwarding no

Match all
EOF
```

Zuletzt wird der Service gestartet und zum Autostart hinzugefügt:
```shell
rc-update add sshd
service sshd start
```

## Gruppe mit Schreibrechten auf alle Verzeichnisse
```shell
addgroup creator
adduser tom creator
chgrp -R creator /home/*
chmod -R g+w /home/*
```
