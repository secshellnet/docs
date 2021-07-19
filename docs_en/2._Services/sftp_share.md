# SFTP Share (Alpine 3.13)
You can simply execute the [install_sftp_share.sh](./sftp_share.sh) script. Make sure to adjust the configuration section (list of users). Afterwards you can add new users using the [sftp_share_adduser.sh](./sftp_share_adduser.sh) script.

Install `openssh-server`:
```shell
echo > /etc/motd

apk add --update --no-cache openssh-server
mkdir -p /etc/ssh/authorized_keys
```

Add your sftp users:
```shell
adduser --shell=/bin/false --disabled-password tom
passwd -u tom
echo "ssh-rsa ....." > /etc/ssh/authorized_keys/tom
chmod o-r /home/tom
```

Adjust the ssh configuration, you need to do the second step for every single user. You only need one `Match all` at the end of the file (you actually don't need it if you don't add something after your `Match User` blocks)
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

Add your service to autostart and start it.
```shell
rc-update add sshd
service sshd start
```

## Group with write permission to all shares
```shell
addgroup creator
adduser tom creator
chgrp -R creator /home/*
chmod -R g+w /home/*
```
