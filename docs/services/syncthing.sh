#!/bin/sh
echo > /etc/motd

apk add --update --no-cache syncthing xmlstarlet apache2-utils

# enable shell
sed -i '/syncthing/s|sbin/nologin|bin/ash|g' /etc/passwd

# generate password: if this step takes longer than a second, simply set a password manually
password=$(cat /dev/urandom | tr -dc A-Za-z0-9 | fold -w 24 | head -n 1)
hash=$(htpasswd -bnBC 10 "" ${password})
echo "Syncthing Credentials: admin / ${password}"

# configure syncthing
syncthing_cfg="/var/lib/syncthing/.config/syncthing/config.xml"
su -l syncthing -c "syncthing -generate $(dirname ${syncthing_cfg})"
xmlstarlet ed --inplace --update "/configuration/gui/address" --value "0.0.0.0:8384" ${syncthing_cfg}
xmlstarlet ed --inplace --subnode "/configuration/gui" --type "elem" --name "user" --value "admin" ${syncthing_cfg}
xmlstarlet ed --inplace --subnode "/configuration/gui" --type "elem" --name "password" --value "${hash:1}" ${syncthing_cfg}
xmlstarlet ed --inplace --update "/configuration/gui/@tls" --value true ${syncthing_cfg}

rc-update add syncthing
service syncthing start
