#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

echo >/etc/motd

# install hedgedoc
apk add --no-cache --update nodejs npm sqlite git nginx acme.sh socat
npm i -g node-gyp yarn
wget -O- https://github.com/hedgedoc/hedgedoc/releases/download/1.8.2/hedgedoc-1.8.2.tar.gz | tar xzC /opt/
cd /opt/hedgedoc
sh bin/setup
yarn install
yarn build
cat <<EOF >config.json
{
  "production": {
    "db": {
      "dialect": "sqlite",
      "storage": "./db.hedgedoc.sqlite"
    },
    "host": "127.0.0.1",
    "domain": "${DOMAIN}"
    "protocolUseSSL": true,                                                                                            
    "sessionSecret": "$(cat /dev/urandom | tr -dcA-Za-z0-9 | fold -w32 | head -n1)",                                            
    "allowAnonymous": false,
    "allowAnonymousEdits": true,
    "email": false,              
    "allowEmailRegister": false, 
    "defaultPermission": "locked"
  }
}
EOF

# get certificate
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --dns dns_cf -d ${DOMAIN}

# adjust nginx config
cat <<EOF >/etc/nginx/conf.d/default.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ''      close;
}

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
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /socket.io/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
    }
}
EOF

# create hedgedoc service
cat <<EOF > /etc/init.d/hedgedoc
#!/sbin/openrc-run

function start {
  cd /opt/hedgedoc
  NODE_ENV=production yarn start & 2>&1 >/dev/null
}
EOF
chmod +x /etc/init.d/hedgedoc

# configure autostart
rc-update add nginx
rc-update add hedgedoc
rc-service nginx start
rc-service hedgedoc start
