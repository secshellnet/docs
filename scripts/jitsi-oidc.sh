#!/bin/sh

# setup jitsi openid connect authentication: https://github.com/marcelcoding/jitsi-openid

if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

# install nodejs and jitsi-openid
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
curl -Lo /opt/jitsi-oidc/index.js --create-dirs https://github.com/MarcelCoding/jitsi-openid/releases/download/v1.0.6/index.js

# generate secret
jitsi_secret=$(node -e "console.log(require('crypto').randomBytes(24).toString('base64'));")

# create systemd service
cat <<EOF > /etc/systemd/system/jitsi-oidc.service
[Unit]
Description=Jitsi OpenID is an authentication adapter that allows Jitsi to authorize users with OpenID Connect.
After=network.target

[Service]
Type=simple
Restart=always
ExecStart=/usr/bin/node /opt/jitsi-oidc/index.js
Environment="JITSI_SECRET=${jitsi_secret}"
Environment="JITSI_URL=https://${DOMAIN}"
Environment="JITSI_SUB=${DOMAIN}"
Environment="ISSUER_BASE_URL=${ISSUER_BASE_URL}"
Environment="BASE_URL=https://${AUTH_DOMAIN}"
Environment="CLIENT_ID=${AUTH_DOMAIN}"
Environment="SECRET=${CLIENT_SECRET}"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now jitsi-oidc


# install certbot to get tls certificate using acme dns-01 challenge
apt-get install -y python3-pip
python3 -m pip install certbot certbot-dns-cloudflare

echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" > /root/.cloudflare.ini
chmod 400 /root/.cloudflare.ini
/usr/local/bin/certbot certonly \
  --non-interactive \
  --agree-tos \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d ${AUTH_DOMAIN} \
  -m ${EMAIL} \
  --preferred-challenges dns-01

cat <<EOF > /etc/nginx/sites-available/${AUTH_DOMAIN}.conf
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /etc/letsencrypt/live/${AUTH_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${AUTH_DOMAIN}/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    # intermediate configuration
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    location / {
        proxy_pass http://127.0.0.1:3000/;
    }
}
EOF
ln -s /etc/nginx/sites-available/${AUTH_DOMAIN}.conf /etc/nginx/sites-enabled/${AUTH_DOMAIN}.conf

# set tokenAuthUrl in jitsi config
sed -ie "s|tokenAuthUrl|*/\n     tokenAuthUrl: \"https://${AUTH_DOMAIN}/room/{room}\",\n     /*|g" /etc/jitsi/meet/jitsi.the-morpheus.de-config.js

# enable token authentication in prosody
debconf-set-selections <<< "jitsi-meet-tokens  jitsi-meet-tokens/appid	    string    ${DOMAIN}"
debconf-set-selections <<< "jitsi-meet-tokens  jitsi-meet-tokens/appsecret  password  ${jitsi_secret}"
apt-get install -y liblua5.2-dev jitsi-meet-tokens

