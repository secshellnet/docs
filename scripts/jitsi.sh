#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

# enable hetzner apt repositories
sed -i '1 i\deb http://mirror.hetzner.de/debian/packages buster main contrib non-free' /etc/apt/sources.list
sed -i '2 i\deb http://mirror.hetzner.de/debian/security buster/updates main contrib non-free' /etc/apt/sources.list
sed -i '3 i\deb http://mirror.hetzner.de/debian/packages buster-updates main contrib non-free' /etc/apt/sources.list

# configure timezone
ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

apt-get update
apt-get install -y nginx-full gnupg apt-transport-https curl lsb-release

# adjust package sources
curl https://download.jitsi.org/jitsi-key.gpg.key | sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
apt-get update

# install certbot to get tls certificate using acme dns-01 challenge
apt-get install -y python3-pip certbot-dns-cloudflare

echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" > /root/.cloudflare.ini
chmod 400 /root/.cloudflare.ini
/usr/local/bin/certbot certonly \
  --non-interactive \
  --agree-tos \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d ${DOMAIN} \
  -m ${EMAIL} \
  --preferred-challenges dns-01

# add cronjob for certificate renewal
cat <<EOF /var/spool/cron/crontabs/root
# regenerate lets encrypt certificates every 15 days
0 3 */15 * * /usr/bin/certbot renew >/dev/null 2>&1
EOF

# predefine certificate paths
debconf-set-selections <<< "jitsi-meet-web-config	jitsi-meet/cert-choice	            select	I want to use my own certificate"
debconf-set-selections <<< "jitsi-meet-web-config	jitsi-meet/cert-path-key	    string	/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
debconf-set-selections <<< "jitsi-meet-web-config	jitsi-meet/cert-path-crt	    string	/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
debconf-set-selections <<< "jitsi-meet-web-config	jitsi-videobridge/jvb-hostname	    string	${DOMAIN}"

apt-get install -y jitsi-meet

