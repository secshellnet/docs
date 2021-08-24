#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

# require environment variables
if [[ -z ${DOMAIN} || -z ${EMAIL} || -z ${CF_API_TOKEN} || -z ${PUBLIC_IPv4} ]]; then
  echo "Missing environemnt variables, check docs!"
  exit 1
fi

echo >/etc/motd

# stop execution on failure
set -e

# reconfigure timezone
ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# comment out cdrom apt repositories
sed -i -e '/deb cdrom.*/ s/^#*/#/' /etc/apt/sources.list

apt-get update
apt-get install -y nginx-full gnupg apt-transport-https curl lsb-release python3-certbot-dns-cloudflare

# adjust package sources
curl https://download.jitsi.org/jitsi-key.gpg.key | sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
apt-get update

# get tls certificate using acme dns-01 challenge
echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" > /root/.cloudflare.ini
chmod 400 /root/.cloudflare.ini
certbot certonly \
  --non-interactive \
  --agree-tos \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d ${DOMAIN} \
  -m ${EMAIL} \
  --preferred-challenges dns-01

# add cronjob for certificate renewal
cat <<EOF >> /var/spool/cron/crontabs/root
# regenerate lets encrypt certificates every 15 days
0 3 */15 * * /usr/bin/certbot renew >/dev/null 2>&1
EOF

# predefine certificate paths
debconf-set-selections <<< "jitsi-meet-web-config jitsi-meet/cert-choice select I want to use my own certificate"
debconf-set-selections <<< "jitsi-meet-web-config jitsi-meet/cert-path-key string /etc/letsencrypt/live/${DOMAIN}/privkey.pem"
debconf-set-selections <<< "jitsi-meet-web-config jitsi-meet/cert-path-crt string /etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
debconf-set-selections <<< "jitsi-meet-web-config jitsi-videobridge/jvb-hostname string ${DOMAIN}"

apt-get install -y jitsi-meet

cat <<EOF >> /etc/jitsi/jicofo/sip-communicator.properties
org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=$(ip -4 a sh ens18 | grep inet | grep -v inet6 | awk '{print $2}' | cut -d "/" -f1)
org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=${PUBLIC_IPv4}
EOF
