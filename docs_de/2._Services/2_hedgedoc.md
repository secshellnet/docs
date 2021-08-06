# HedgeDoc (Alpine 3.13)

![](../img/services/hedgedoc.png?raw=true){: loading=lazy }

Die Installation kann über das [install_hedgedoc.sh](./hedgedoc.sh) Script erfolgen. Diese nutzt die ACME HTTP Challenge, ganz oben muss die Konfiguration (domain, email) angepasst werden.

```shell
echo >/etc/motd

# install hedgedoc
apk add nodejs npm sqlite git nginx
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
    "domain": "md.secshell.net"
  }
}
EOF
```

Anschließend werden die Zertifikate von Let's Encrypt angefordert:
```shell
# install requirements for python-cryptography (requirement for certbot)
apk add --update --no-cache \
  g++ make python3 python3-dev py3-pip \
  libffi-dev libressl-dev libxslt-dev \
  rust cargo

domain="md.secshell.net"
```
* ACME HTTP-01 Challenge:
  ```shell
  pip3 install certbot-nginx
  /usr/bin/certbot --nginx --non-interactive --agree-tos -d ${domain} -m certificates@secshell.net
  ```
* ACME DNS-01 Challenge
  ```shell
  pip3 install certbot certbot-dns-cloudflare
  echo "dns_cloudflare_api_token = CF_API_TOKEN" > /root/.cloudflare.ini
  chmod 400 /root/.cloudflare.ini
  /usr/bin/certbot certonly \
    --non-interactive \
    --agree-tos \
    --dns-cloudflare \
    --dns-cloudflare-credentials /root/.cloudflare.ini \
    -d ${domain} \
    -m certificates@secshell.net \
    --preferred-challenges dns-01
  ```

Danach wird die Konfiguration des nginx Servers angepasst:
```shell
# adjust nginx config
cat <<EOF >/etc/nginx/conf.d/default.conf
map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
   
    server_name md.secshell.net;

    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

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

server {
    listen 80;
    listen [::]:80;
    return 301 https://\$host\$request_uri;
}
EOF
```

Automatische Zertifikaterneuerung:
```
# regenerate lets encrypt certificates every 15 days
0 3 */15 * * /usr/bin/certbot renew >/dev/null 2>&1
EOF cat <<EOF >> /etc/crontabs/root
```

Zuletzt wird der Service gestartet und zum Autostart hinzugefügt:
```shell
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
```
