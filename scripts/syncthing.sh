#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
fi

# require environment variables
if [[ -z ${PASSWORD} ]]; then
    echo "Missing environemnt variables, check docs!"
    exit 1
fi

echo > /etc/motd

# stop execution on failure
set -e

apk add --update --no-cache syncthing xmlstarlet apache2-utils

# generate password hash
hash=$(htpasswd -bnBC 10 "" ${PASSWORD})

# configure syncthing
syncthing_cfg="/var/lib/syncthing/.config/syncthing/config.xml"
su -l syncthing -s /bin/ash -c "syncthing -generate $(dirname ${syncthing_cfg})"
xmlstarlet ed --inplace --update "/configuration/gui/address" --value "0.0.0.0:8384" ${syncthing_cfg}
xmlstarlet ed --inplace --subnode "/configuration/gui" --type "elem" --name "user" --value "admin" ${syncthing_cfg}
xmlstarlet ed --inplace --subnode "/configuration/gui" --type "elem" --name "password" --value "${hash:1}" ${syncthing_cfg}
xmlstarlet ed --inplace --update "/configuration/gui/@tls" --value true ${syncthing_cfg}

rc-update add syncthing
service syncthing start
