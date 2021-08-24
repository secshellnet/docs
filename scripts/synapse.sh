#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

# require environment variables
if [[ -z ${SYNAPSE_DOMAIN} || -z ${MATRIX_DOMAIN} || -z ${ELEMENT_DOMAIN} || -z ${CF_Token} || -z ${CF_Account_ID} || -z ${CF_Zone_ID} ]]; then
  echo "Missing environemnt variables, check docs!"
  exit 1
fi

echo > /etc/motd

# stop execution on failure
set -e

apt-get install -y lsb-release wget apt-transport-https nginx python3-certbot-dns-cloudflare
wget -O /usr/share/keyrings/matrix-org-archive-keyring.gpg https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main" >> /etc/apt/sources.list.d/matrix-org.list
apt-get update

# install synapse
debconf-set-selection <<< "matrix-synapse-py3 matrix-synapse/report-stats booolean false"
debconf-set-selection <<< "matrix-synapse-py3 matrix-synapse/server-name string ${MATRIX_DOMAIN}"
apt-get install matrix-synapse-py3

# get tls certificate using acme dns-01 challenge
echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" > /root/.cloudflare.ini
chmod 400 /root/.cloudflare.ini
certbot certonly \
  --non-interactive \
  --agree-tos \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d ${MATRIX_DOMAIN} \
  -m ${EMAIL} \
  --preferred-challenges dns-01

certbot certonly \
  --non-interactive \
  --agree-tos \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d ${SYNAPSE_DOMAIN} \
  -m ${EMAIL} \
  --preferred-challenges dns-01

# add cronjob for certificate renewal
cat <<EOF > /var/spool/cron/crontabs/root
# regenerate lets encrypt certificates every 15 days
0 3 */15 * * /usr/bin/certbot renew >/dev/null 2>&1
EOF

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
        add_header access-control-allow-headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
        add_header access-control-allow-methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header access-control-allow-origin *;
        return 200 '{"m.server":"${SYNAPSE_DOMAIN}:443"}';
    }

    location /.well-known/matrix/client {
        add_header content-type application/json;
        add_header access-control-allow-headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
        add_header access-control-allow-methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header access-control-allow-origin *;
        return 200 '{"m.homeserver":{"base_url":"https://${SYNAPSE_DOMAIN}"},"m.identity_server":{"base_url":"https://vector.im"}}';
    }
}
EOF

cat <<EOF > /etc/nginx/sites-available/${SYNAPSE_DOMAIN}.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name ${SYNAPSE_DOMAIN};
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /etc/letsencrypt/live/${SYNAPSE_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${SYNAPSE_DOMAIN}/privkey.pem;
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

    location ~* ^(\/_matrix|\/_synapse\/client) {
        proxy_pass http://localhost:8008;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;

        # Nginx by default only allows file uploads up to 1M in size
        # Increase client_max_body_size to match max_upload_size defined in homeserver.yaml
        client_max_body_size 50M;
    }
}
EOF

# enable created sites
ln -s /etc/nginx/sites-{available,enabled}/${MATRIX_DOMAIN}.conf
ln -s /etc/nginx/sites-{available,enabled}/${SYNAPSE_DOMAIN}.conf

systemctl enable --now nginx
systemctl enable --now matrix-synapse
