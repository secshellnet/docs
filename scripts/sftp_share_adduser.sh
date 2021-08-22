#!/bin/sh

# $1 is the username [, $2 is the optional path to the ssh public key]

if [ -z $1 ]; then
  echo "Usage: ./$0 <username>"
  exit
fi

# create user without password and shell
adduser --shell=/bin/false --disabled-password $1

# unlock user
passwd -u $1

# ssh keys
if [ ! -z $2 && -f $2 ]; then
  cat $2 >> /etc/ssh/authorized_keys/$1
else
  touch /etc/ssh/authorized_keys/$1
  echo "Make sure to add the ssh key of $1 to /etc/ssh/authorized_keys/$1"
fi

# remove read permissions from others (to prevent unauthorized read access)
chmod o-r /home/$1

# configure sftp jail
cat <<EOF >> /etc/ssh/sshd_config
Match User $1
   ChrootDirectory /home
   ForceCommand internal-sftp -d /$1
   AllowTTY no
   AllowTCPForwarding no
   X11Forwarding no
EOF
