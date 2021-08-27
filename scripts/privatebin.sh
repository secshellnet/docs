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

# install nginx, php8 fpm and acme.sh
apk add --no-cache --update nginx php8-fpm acme.sh socat
addgroup -S appgroup
adduser -S appuser -G appgroup

# configure php fpm
cat <<EOF > /etc/php8/php-fpm.d/privatebin.conf
[wordpress_site]
user = appuser
group = appgroup
listen = /var/run/php8-privatebin.sock
listen.owner = nginx
listen.group = nginx
php_admin_value[disable_functions] = exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen] = off
; Choose how the process manager will control the number of child processes.
pm = dynamic
pm.max_children = 75
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.process_idle_timeout = 10s
EOF

# get certificate
mkdir /root/.acme.sh
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --dns dns_cf -d ${DOMAIN}

# configure nginx
cat <<EOF > /etc/nginx/conf.d/default.conf
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

    root /var/www/privatebin;
    index index index.html index.htm index.php;
    location / {
        try_files \$uri \$uri/ /index.php$is_args\$args;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php8-privatebin.sock;
        fastcgi_index index.php;
        include fastcgi.conf;
    }
}
EOF

mkdir /var/www/privatebin
wget -O- https://github.com/PrivateBin/PrivateBin/archive/refs/tags/1.3.5.tar.gz | tar -xzC /var/www/privatebin/ --strip 1
cp /var/www/privatebin/cfg/conf.sample.php /var/www/privatebin/cfg/conf.php
chown -R appuser:appgroup /var/www/privatebin/

rc-update add nginx
rc-update add php-fpm8
rc-service nginx start
rc-service php-fpm8 start
