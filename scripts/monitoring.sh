#!/bin/bash

if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
fi

# stop execution on failure
set -e

# require environment variables
if [[ -z ${DOMAIN} ]] || [[ -z ${CF_Token} ]] || [[ -z ${ADMIN_PASSWD} ]] || \
   [[ -z ${CHECK_DNS} ]] || [[ -z ${UPDATE_DNS} ]] || [[ -z ${CF_PROXIED} ]]; then
    echo "Missing environemnt variables, check docs!"
    exit 1
fi

if [[ -z ${CF_Account_ID} ]] || [[ -z ${CF_Zone_ID} ]]; then
    apt-get update
    apt-get install -y curl jq

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

# configure timezone
ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# comment out cdrom apt repositories
sed -i -e '/deb cdrom.*/ s/^#*/#/' /etc/apt/sources.list

apt-get update
apt-get upgrade -y
apt-get -y install sudo curl wget gnupg2 apt-transport-https software-properties-common git socat

# grafana, influxdb, prometheus
wget -qO- https://packages.grafana.com/gpg.key | gpg --dearmor > /etc/apt/trusted.gpg.d/grafana.gpg
echo "deb https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
wget -qO- https://repos.influxdata.com/influxdb.key | gpg --dearmor > /etc/apt/trusted.gpg.d/influxdb.gpg
export DISTRIB_ID=$(lsb_release -si)
echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdb.gpg] https://repos.influxdata.com/${DISTRIB_ID,,} $(lsb_release -sc) stable" > /etc/apt/sources.list.d/influxdb.list

apt-get update
apt-get -y install grafana influxdb prometheus

# set capability to bind to port 443
setcap 'cap_net_bind_service=+ep' /usr/sbin/grafana-server

# issue tls ecc certificate using dns-01 challenge
curl https://get.acme.sh | sh
ln /root/.acme.sh/acme.sh /usr/local/bin/acme.sh
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --keylength ec-384 --dns dns_cf -d ${DOMAIN}
acme.sh --install-cert --ecc -d ${DOMAIN} --key-file /etc/grafana/certs/${DOMAIN}.key --fullchain-file /etc/grafana/certs/fullchain.cer
chown -R grafana:grafana /etc/grafana/certs/

# enable https in grafana
sed -i "s|;http_port.*|http_port = 443|g" /etc/grafana/grafana.ini
sed -i "s|;protocol.*|protocol = https|g" /etc/grafana/grafana.ini
sed -i "s|;domain.*|domain = ${DOMAIN}|g" /etc/grafana/grafana.ini
sed -i "s|;root_url.*|root_url = https://${DOMAIN}/|g" /etc/grafana/grafana.ini
sed -i "s|;cert_file.*|cert_file = /etc/grafana/certs/fullchain.cer|g" /etc/grafana/grafana.ini
sed -i "s|;cert_key.*|cert_key = /etc/grafana/certs/${DOMAIN}.key|g" /etc/grafana/grafana.ini
sed -i "s|;admin_password.*|admin_password = ${ADMIN_PASSWD}|g" /etc/grafana/grafana.ini

# grant grafana access to certificate files
chown -R root:grafana /etc/letsencrypt
chmod -R 750 /etc/letsencrypt/{live,archive}

# configure autostart
systemctl enable --now grafana-server
systemctl enable --now influxdb
systemctl enable --now prometheus

echo "Grafana Credentials: admin / ${admin_password}"

# check dns
if [ ${CHECK_DNS} -eq 1 ]; then
    curl -fsSL https://docs.secshell.net/scripts/dns-api.sh | bash
fi
