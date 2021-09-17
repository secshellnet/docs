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

# install redis and netbox
apk add --no-cache --update nginx acme.sh socat python3 py3-pip python3-dev build-base libxml2-dev libxslt-dev libffi-dev postgresql-dev libressl-dev zlib-dev jpeg-dev git redis openssl
mkdir -p /opt/netbox/
git clone -b master https://github.com/netbox-community/netbox.git /opt/netbox/
pip3 install -r /opt/netbox/requirements.txt
cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py

# configure netbox
cp /opt/netbox/netbox/netbox/configuration.example.py /opt/netbox/netbox/netbox/configuration.py
SECRET_KEY=$(openssl rand -hex 64)
sed -i "/^ALLOWED_HOSTS.* /s/\[\]/\['*'\]/" /opt/netbox/netbox/netbox/configuration.py
sed -i "/^SECRET_KEY.* /s/''/'${SECRET_KEY}'/" /opt/netbox/netbox/netbox/configuration.py

# TODO configure database (sed block search and replace)
sed -i "/'USER':.* /s/''/'postgres'/" /opt/netbox/netbox/netbox/configuration.py

# run database migrations
python3 /opt/netbox/netbox/manage.py migrate

# get static files to be served using nginx
python3 /opt/netbox/netbox/manage.py collectstatic

# get certificate using acme dns-01 challenge
mkdir /root/.acme.sh
ln -s /usr/bin/acme.sh /root/.acme.sh/acme.sh
acme.sh --install-cronjob
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --keylength ec-384 --dns dns_cf -d ${DOMAIN}

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
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static/ {
        alias /opt/netbox/netbox/static/;
    }
}
EOF

# create netbox service
cat <<EOF > /etc/init.d/netbox
#!/sbin/openrc-run

function start {
    gunicorn --pid /var/tmp/netbox.pid --pythonpath /opt/netbox/netbox --config /opt/netbox/gunicorn.py netbox.wsgi --daemon > /dev/null 2>&1
}

function stop {
    killall -9 gunicorn
}

EOF
chmod +x /etc/init.d/netbox

# configure autostart
rc-update add nginx
rc-update add redis
rc-update add netbox
rc-service nginx start
rc-service redis start
rc-service netbox start

# check dns
if [ ${CHECK_DNS} -eq 1 ]; then
    curl -fsSL https://docs.secshell.net/scripts/dns-api.sh | sh
fi
