#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
fi

# stop execution on failure
set -e

# require environment variables
if [[ -z ${DOMAIN} ]] || [[ -z ${CF_Token} ]]; then
    echo "Missing environemnt variables, check docs!"
    exit 1
fi

# optional environment variables
if [[ -z ${CF_Account_ID} ]] || [[ -z ${CF_Zone_ID} ]]; then
    apk add --no-cache --update curl jq

    zone_name=${DOMAIN}
    while [[ $(echo ${zone_name} | grep -o "\." | wc -l) -gt 1 ]]; do
        zone_name=${zone_name#*.}
    done

    # get CF_Account_ID and CF_Zone_ID using CF_Token
    data=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zone_name}&status=active" \
        -H "Authorization: Bearer ${CF_Token}" -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0]')

    export CF_Zone_ID=$(echo ${data} | jq -r '.id')
    export CF_Account_ID=$(echo ${data} | jq -r '.account.id')
fi

echo >/etc/motd

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

mkdir ./data

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
