# Bookstack (LXC: Ubuntu 21.04)
Die Installation kann über das [install_bookstack.sh](./bookstack.sh) Script erfolgen, ganz oben muss die Konfiguration (cloudflare token, domain, email) angepasst werden.

Zuerst erfolgt die Installation von Bookstack über das Installationsscript:
```shell
apt-get install -y curl

# install bookstack using install script
curl -fsSL https://raw.githubusercontent.com/BookStackApp/devops/master/scripts/installation-ubuntu-20.04.sh | bash

# update app url variable
sed -i 's|APP_URL=.*|APP_URL=https://docs.secshell.net|g' /var/www/bookstack/.env
```

Anschließend werden die Zertifikate über die ACME DNS-01 Challenge angefordert:
```shell
# get certificate
apt install python3-certbot-apache python3-certbot-dns-cloudflare
echo "dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN" > /root/.cloudflare.ini
chmod 400 /root/.cloudflare.ini
certbot certonly \
  --non-interactive \
  --agree-tos \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d docs.secshell.net \
  -e certificates@secshell.net
  --preferred-challenges dns-01
```

Zuletzt wird der installierte apache2 Webserver für die Nutzung der angeforderten Zertifikate konfiguriert. Außerdem wird ein http to https redirect angelegt, sodass nur Verschlüsselte Verbindungen genutzt werden können:
```shell
# configure apache2 for https
sed -i '1 i\<IfModule mod_ssl.c>' /etc/apache2/sites-available/bookstack.conf
sed -i -e '$a</IfModule>' /etc/apache2/sites-available/bookstack.conf
sed -i 's|*:80|*:443|g' /etc/apache2/sites-available/bookstack.conf

# - adjust server name
sed -i '/ServerName/d' /etc/apache2/sites-available/bookstack.conf 
sed -i '/^<\/VirtualHost>/i \\tServerName docs.secshell.net' /etc/apache2/sites-available/bookstack.conf

# - add certificates
sed -i '/^<\/VirtualHost>/i \\tSSLCertificateFile /etc/letsencrypt/live/docs.secshell.net/fullchain.pem' /etc/apache2/sites-available/bookstack.conf
sed -i '/^<\/VirtualHost>/i \\tSSLCertificateKeyFile /etc/letsencrypt/live/docs.secshell.net/privkey.pem' /etc/apache2/sites-available/bookstack.conf

# - http to https redirect
mv /etc/apache2/sites-available/000-default.conf{,.bak}
cat <<EOF >> /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@secshell.net

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    Redirect permanent / https://docs.secshell.net
</VirtualHost>
EOF

# enable https
a2enmod ssl
```

