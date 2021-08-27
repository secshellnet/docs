#!/bin/sh

# TODO web-vault doesn't get served yet but you may use the browser extensions:
# - https://addons.mozilla.org/en-US/firefox/addon/bitwarden-password-manager/
# - https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb?hl=de

if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

# require environment variables
if [[ -z ${DOMAIN} || -z ${CF_Token} || -z ${CF_Account_ID} || -z ${CF_Zone_ID} ]]; then
  echo "Missing environemnt variables, check docs!"
  exit 1
fi

echo >/etc/motd

# stop execution on failure
set -e

# extract vaultwarden from latest docker image
mkdir -p /opt/vaultwarden
cd /opt/vaultwarden
wget https://raw.githubusercontent.com/jjlin/docker-image-extract/main/docker-image-extract
chmod +x docker-image-extract
./docker-image-extract vaultwarden/server:alpine
mv ./output/vaultwarden .
mv ./output/web-vault .
rm -r output docker-image-extract

# get certificate using acme dns-01 challenge
apk add --no-cache --update acme.sh socat
mkdir /root/.acme.sh
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --dns dns_cf -d ${DOMAIN}

# create vaultwarden environment file
cat <<EOF > /opt/vaultwarden/.env
DOMAIN=https://${DOMAIN}

ROCKET_ADDRESS=::
ROCKET_PORT=443
ROCKET_TLS={certs="/root/.acme.sh/${DOMAIN}/fullchain.cer",key="/root/.acme.sh/${DOMAIN}/${DOMAIN}.key"}
IP_HEADER=CF-Connecting-IP

WEB_VAULT_FOLDER=web-vault/
WEB_VAULT_ENABLED=true

# LOG_LEVEL=debug
EOF

# create vaultwarden service
cat <<EOF > /etc/init.d/vaultwarden
#!/sbin/openrc-run

function start {
    # change directory to load .env file
    cd /opt/vaultwarden/
    ./vaultwarden & 2>&1 > /dev/null
}

function stop {
    killall -9 vaultwarden
}
EOF
chmod +x /etc/init.d/vaultwarden

# configure autostart
rc-update add vaultwarden
rc-service vaultwarden start
