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

echo > /etc/motd

# install keycloak
apk add --update --no-cache openjdk11-jre nginx acme.sh socat xmlstarlet
wget -O- https://github.com/keycloak/keycloak/releases/download/15.0.1/keycloak-15.0.1.tar.gz | tar xzC /opt/
cd /opt/keycloak-15.0.1

# get certificate
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --dns dns_cf -d ${DOMAIN}

# configure nginx
cat << EOF > /etc/nginx/conf.d/default.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /root/.acme.sh/${DOMAIN}/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/${DOMAIN}/${DOMAIN}.key;
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
            proxy_pass http://127.0.0.1:8080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# adjust config - TODO not working
xmlstarlet ed --inplace --subnode "/server/profile/subsystem[@default-server='default-server']/server/http-listener" --type attr --name proxy-address-forwarding --value true /opt/keycloak-15.0.1/standalone/configuration/standalone.xml

# fix UnknownHostException
echo -e "127.0.0.1\t$(hostname)" >> /etc/hosts

# create keycloak service and configure autostart
cat <<EOF > /etc/init.d/keycloak
#!/sbin/openrc-run

function start {
    sh /opt/keycloak-15.0.1/bin/standalone.sh & 2>&1 >/dev/null
}

function stop {
    killall -9 java
}

EOF
chmod +x /etc/init.d/keycloak

rc-update add nginx
rc-service nginx restart
rc-update add keycloak
rc-service keycloak start
