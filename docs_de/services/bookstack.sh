#!/bin/bash

### config
CF_API_TOKEN=""
domain="docs.secshell.net"
email="certificates@secshell.net"
### end of config

apt-get install -y curl

# install bookstack using install script
curl -fsSL https://raw.githubusercontent.com/BookStackApp/devops/master/scripts/installation-ubuntu-20.04.sh | bash

# update app url variable
sed -i "s|APP_URL=.*|APP_URL=https://${domain}|g" /var/www/bookstack/.env

# get certificate
apt install python3-certbot-apache python3-certbot-dns-cloudflare
echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" > /root/.cloudflare.ini
chmod 400 /root/.cloudflare.ini
certbot certonly \
  --non-interactive \
  --agree-tos \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d ${domain} \
  -e ${email}
  --preferred-challenges dns-01

# configure apache2 for https
sed -i '1 i\<IfModule mod_ssl.c>' /etc/apache2/sites-available/bookstack.conf
sed -i -e '$a</IfModule>' /etc/apache2/sites-available/bookstack.conf
sed -i 's|*:80|*:443|g' /etc/apache2/sites-available/bookstack.conf

# - adjust server name
sed -i '/ServerName/d' /etc/apache2/sites-available/bookstack.conf
sed -i "/^<\/VirtualHost>/i \\tServerName ${domain}" /etc/apache2/sites-available/bookstack.conf

# - add certificates
sed -i "/^<\/VirtualHost>/i \\tSSLCertificateFile /etc/letsencrypt/live/${domain}/fullchain.pem" /etc/apache2/sites-available/bookstack.conf
sed -i "/^<\/VirtualHost>/i \\tSSLCertificateKeyFile /etc/letsencrypt/live/${domain}/privkey.pem" /etc/apache2/sites-available/bookstack.conf

# - http to https redirect
mv /etc/apache2/sites-available/000-default.conf{,.bak}
cat <<EOF >> /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin ${email}

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    Redirect permanent / https://${domain}
</VirtualHost>
EOF

# enable https
a2enmod ssl
