#!/bin/sh

## configuration section

users=('tom' 'mike')

## end of configuration


echo > /etc/motd

# install openssh-server
apk add --update --no-cache openssh-server
mkdir -p /etc/ssh/authorized_keys

# change location of authorized keys file (.ssh/authorized_keys is no longer required so it can be removed)
sed -i 's|AuthorizedKeysFile.*|AuthorizedKeysFile /etc/ssh/authorized_keys/%u|g' /etc/ssh/sshd_config

# get adduser script if not already there
if [ ! -f sftp_share_adduser.sh ]; then
  wget https://github.com/secshellnet/docs/blob/main/service_scripts/sftp_share_adduser.sh
fi

for user in ${users[@]}; do
  sh ./sftp_share_adduser.sh $user  
done

# create Match all entry
cat <<EOF >> /etc/ssh/sshd_config
Match all
EOF

# enable autostart and start the sshd service
rc-update add sshd
service sshd start