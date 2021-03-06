#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
fi

# stop execution on failure
set -e

# require environment variables
if [[ -z ${DOMAIN} ]] || [[ -z ${ADMIN_DOMAIN} ]] || [[ -z ${CF_Token} ]] || \
   [[ -z ${CHECK_DNS} ]] || [[ -z ${UPDATE_DNS} ]] || [[ -z ${CF_PROXIED} ]]; then
    echo "Missing environemnt variables, check docs!"
    exit 1
fi

# optional environment variables
if [[ -z ${VERSION} ]]; then
    VERSION="15.0.1"
fi
if [[ -z ${CONFIGURATOR_VERSION} ]]; then
    CONFIGURATOR_VERSION="1.0.3"
fi

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
apk add --update --no-cache openjdk11-jre nginx acme.sh socat
wget -O- https://github.com/keycloak/keycloak/releases/download/${VERSION}/keycloak-${VERSION}.tar.gz | tar xzC /opt/
cd /opt/keycloak-${VERSION}

# get certificate
mkdir /root/.acme.sh
ln -s /usr/bin/acme.sh /root/.acme.sh/acme.sh
acme.sh --install-cronjob
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --dns dns_cf -d ${DOMAIN}
acme.sh --issue --dns dns_cf -d ${ADMIN_DOMAIN}

# configure nginx
cat << EOF > /etc/nginx/conf.d/${DOMAIN}.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name ${DOMAIN};
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
            proxy_set_header X-Real-IP \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
    }

    # redirect to account login
    location ~* ^(\/|\/auth\/)$ {
        return 301 https://id.the-morpheus.de/auth/realms/themorpheustutorials/account/;
    }

    # do not allow keycloak admin from this domain
    location ~* (\/auth\/admin\/|\/auth\/realms\/master\/) {
        return 403;
    }
}
EOF

cat << EOF > /etc/nginx/conf.d/${ADMIN_DOMAIN}.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name ${ADMIN_DOMAIN};
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /root/.acme.sh/${ADMIN_DOMAIN}/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/${ADMIN_DOMAIN}/${ADMIN_DOMAIN}.key;
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

    # ACL
    allow 10.0.0.0/8;
    allow 192.168.0.0/16;
    allow 172.16.0.0/12;
    deny all;

    location / {
            proxy_pass http://127.0.0.1:8080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
    }

    # redirect to admin console
    location ~* ^(\/|\/auth\/)$ {
        return 301 https://keycloak.the-morpheus.org/auth/realms/master/console/;
    }
}
EOF

# adjust config using keycloak-configurator
wget https://github.com/secshellnet/keycloak-configurator/releases/download/v${CONFIGURATOR_VERSION}/keycloak-configurator-1.0-SNAPSHOT-all.jar -O /root/keycloak-configurator.jar

# enable reverse proxy
java -jar /root/keycloak-configurator.jar /opt/keycloak-${VERSION}/standalone/configuration/standalone.xml

# fix UnknownHostException
echo -e "127.0.0.1\t$(hostname)" >> /etc/hosts

# create keycloak service and configure autostart
cat <<EOF > /etc/init.d/keycloak
#!/sbin/openrc-run

function start {
    sh /opt/keycloak-${VERSION}/bin/standalone.sh & 2>&1 >/dev/null
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

# check dns
if [ ${CHECK_DNS} -eq 1 ]; then
    curl -fsSL https://docs.secshell.net/scripts/dns-api.sh | sh
fi
