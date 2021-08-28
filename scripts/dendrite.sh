#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
fi

# stop execution on failure
set -e

# require environment variables
if [[ -z ${DENDRITE_DOMAIN} ]] || [[ -z ${MATRIX_DOMAIN} ]] || [[ -z ${CF_Token} ]] || \
   [[ -z ${PG_USER} ]] || [[ -z ${PG_PASSWD} ]] || [[ -z ${PG_HOST} ]] || \
   [[ -z ${CHECK_DNS} ]] || [[ -z ${UPDATE_DNS} ]] || [[ -z ${CF_PROXIED} ]]; then
    echo "Missing environemnt variables, check docs!"
    exit 1
fi

# optional environment variables
if [[ -z ${VERSION} ]]; then
    VERSION="v0.5.0"
fi

if [[ -z ${CF_Account_ID} ]] || [[ -z ${CF_Zone_ID} ]]; then
    apk add --no-cache --update curl jq

    zone_name=${DENDRITE_DOMAIN}
    while [[ $(echo ${zone_name} | grep -o "\." | wc -l) -gt 1 ]]; do
        zone_name=${zone_name#*.}
    done

    # get CF_Account_ID and CF_Zone_ID using CF_Token
    data=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zone_name}&status=active" \
        -H "Authorization: Bearer ${CF_Token}" -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0]')

    export CF_Zone_ID=$(echo ${data} | jq -r '.id')
    export CF_Account_ID=$(echo ${data} | jq -r '.account.id')
fi

echo > /etc/motd

# download dendrite
apk add --update --no-cache go git acme.sh socat
git clone https://github.com/matrix-org/dendrite.git

# build dendrite
cd dendrite
git checkout ${VERSION}
./build.sh
cp dendrite-config.yaml ../dendrite.yaml
cd ..

# generate matrix key
./dendrite/bin/generate-keys --private-key matrix_key.pem


# get certificate
mkdir /root/.acme.sh
ln -s /usr/bin/acme.sh /root/.acme.sh/acme.sh
acme.sh --install-cronjob
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --dns dns_cf -d ${DENDRITE_DOMAIN}
acme.sh --issue --dns dns_cf -d ${MATRIX_DOMAIN}

# adjust configuration
sed -i "/server_name.* /{
    s|localhost|${MATRIX_DOMAIN}|
}" /root/dendrite.yaml

sed -i "/connection_string.* /{
    s|file:|postgresql://${PG_USER}:${PG_PASSWD}@${PG_HOST}/|
    s|.db|?sslmode=disable|
}" /root/dendrite.yaml

#sed -i "/real_ip_header.* /{
#    s|# ||
#    s|X-Real-IP|Cf-Connecting-Ip|
#}" /root/dendrite.yaml

sed -i "/private_key.* /{
    s|false|true|
}" /root/dendrite.yaml

sed -i "/registration_disabled.* /{
    s|matrix_key.pem|/root/matrix_key.pem|
}" /root/dendrite.yaml

# configure nginx
cat <<EOF > /etc/nginx/sites-available/${MATRIX_DOMAIN}.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name ${MATRIX_DOMAIN}
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /etc/letsencrypt/live/${MATRIX_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${MATRIX_DOMAIN}/privkey.pem;
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
        return 301 https://${ELEMENT_DOMAIN}\$request_uri;
    }

    location /.well-known/matrix/server {
        add_header content-type application/json;
        return 200 '{"m.server":"${DENDRITE_DOMAIN}:443"}';
    }

    location /.well-known/matrix/client {
        add_header content-type application/json;
        add_header access-control-allow-origin *;
        return 200 '{"m.homeserver":{"base_url":"https://${DENDRITE_DOMAIN}"},"m.identity_server":{"base_url":"https://vector.im"},"im.vector.riot.jitsi": {"preferredDomain": "${JITSI_DOMAIN}"}}';
    }
}
EOF

cat <<EOF > /etc/nginx/sites-available/${DENDRITE_DOMAIN}.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name ${DENDRITE_DOMAIN};
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /etc/letsencrypt/live/${DENDRITE_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DENDRITE_DOMAIN}/privkey.pem;
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
        return 301 https://${ELEMENT_DOMAIN}\$request_uri;
    }

    location /_matrix {
        proxy_pass http://localhost:8008;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;

        # Nginx by default only allows file uploads up to 1M in size
        # Increase client_max_body_size to match max_upload_size defined in homeserver.yaml
        client_max_body_size 50M;
    }
}
EOF

# create dendrite service and configure autostart
cat <<EOF > /etc/init.d/dendrite
#!/sbin/openrc-run

function start {
    /root/dendrite/bin/dendrite-monolith-server \
        --config /root/dendrite.yaml \
        --http-bind-address 127.0.0.1:8080 & 2>&1 >/dev/null
}

function stop {
    killall -9 java
}

EOF
chmod +x /etc/init.d/dendrite

rc-update add dendrite
rc-service dendrite start

# check dns
if [ ${CHECK_DNS} -eq 1 ]; then
    export DOMAIN=${MATRIX_DOMAIN}
    curl -fsSL https://docs.secshell.net/scripts/dns-api.sh | sh
    export DOMAIN=${DENDRITE_DOMAIN}
    curl -fsSL https://docs.secshell.net/scripts/dns-api.sh | sh
fi
