#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
fi

# stop execution on failure
set -e

# require environment variables
if [[ -z ${DOMAIN} ]] || [[ -z ${CF_Token} ]] || \
   [[ -z ${CHECK_DNS} ]] || [[ -z ${UPDATE_DNS} ]] || [[ -z ${CF_PROXIED} ]]; then
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
apk add --no-cache --update acme.sh socat nginx
mkdir /root/.acme.sh
ln -s /usr/bin/acme.sh /root/.acme.sh/acme.sh
acme.sh --install-cronjob
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --keylength ec-384 --dns dns_cf -d ${DOMAIN}

# create vaultwarden environment file
cat <<EOF > /opt/vaultwarden/.env
DOMAIN=https://${DOMAIN}
ROCKET_ADDRESS=127.0.0.1
WEB_VAULT_FOLDER=web-vault/
WEB_VAULT_ENABLED=true
# LOG_LEVEL=debug
EOF

mkdir ./data

# adjust nginx config
cat <<EOF > /etc/nginx/conf.d/default.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /root/.acme.sh/${DOMAIN}_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    # modern configuration
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
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
rc-update add nginx
rc-update add vaultwarden
rc-service nginx start
rc-service vaultwarden start

# check dns
if [ ${CHECK_DNS} -eq 1 ]; then
    curl -fsSL https://docs.secshell.net/scripts/dns-api.sh | sh
fi
