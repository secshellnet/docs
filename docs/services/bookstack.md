# Bookstack (LXC: Ubuntu 21.04)
```bash
# install bookstack using install script
curl -fsSL https://raw.githubusercontent.com/BookStackApp/devops/master/scripts/installation-ubuntu-20.04.sh | bash

# get certificate
apt install python3-certbot-apache python3-certbot-dns-cloudflare
echo "dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN" > /root/.cloudflare.ini
chmod 400 /root/.cloudflare.ini
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d docs.secshell.net \
  --preferred-challenges dns-01

# TODO reconfigure apache2 (including http to https redirect)

# enable https
a2enmod ssl

# TODO Update APP_URL in /var/www/bookstack/.env
```
