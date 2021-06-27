# Monitoring (on Debian 10.7)
You can simply execute the [install_monitoring.sh](./monitoring.sh) script. Make sure to adjust the configuration section (cloudflare token, domain, email).


First, the apt repositories of Hetzner Online are added and the time zone is adjusted:
```shell
echo > /etc/motd

# enable hetzner apt repositories
sed -i '1 i\deb http://mirror.hetzner.de/debian/packages buster main contrib non-free' /etc/apt/sources.list
sed -i '2 i\deb http://mirror.hetzner.de/debian/security buster/updates main contrib non-free' /etc/apt/sources.list
sed -i '3 i\deb http://mirror.hetzner.de/debian/packages buster-updates main contrib non-free' /etc/apt/sources.list

# configure timezone
ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
```

Afterwards the updates and required tools are installed so that the package sources for grafana and influxdb can be added. These packages are installed in the next section.
```shell
apt-get update
apt-get upgrade -y
apt-get -y install sudo curl wget gnupg2 apt-transport-https software-properties-common git python3-pip

# grafana, influxdb, prometheus
wget -qO- https://packages.grafana.com/gpg.key | gpg --dearmor > /etc/apt/trusted.gpg.d/grafana.gpg
echo "deb https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
wget -qO- https://repos.influxdata.com/influxdb.key | gpg --dearmor > /etc/apt/trusted.gpg.d/influxdb.gpg
export DISTRIB_ID=$(lsb_release -si)
echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdb.gpg] https://repos.influxdata.com/${DISTRIB_ID,,} $(lsb_release -sc) stable" > /etc/apt/sources.list.d/influxdb.list

apt-get update
apt-get -y install grafana influxdb prometheus
```

Afterwards, the Certbot and the current version of the Cloudflare Libary are installed. This allows you to use the Cloudflare API tokens instead of the Global API Key for the ACME DNS-01 challenge. After the installation, the desired certificate is requested:
```shell
# install certbot
python3 -m pip install certbot certbot-dns-cloudflare cryptography==3.2
git clone https://github.com/cloudflare/python-cloudflare /tmp/python-cloudflare
cd /tmp/python-cloudflare/
python3 setup.py build
python3 setup.py install
cd
rm -rf /tmp/python-cloudflare

# get ssl certificate over dns-01 challenge
domain="grafana.secshell.net"
echo "dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN" > /root/.cloudflare.ini
chmod 400 /root/.cloudflare.ini
/usr/local/bin/certbot certonly \
  --non-interactive \
  --agree-tos \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare.ini \
  -d ${domain} \
  -m certificates@secshell.net \
  --preferred-challenges dns-01
```

The configuration of Grafana is adjusted accordingly (enable HTTPS, set path to the certificate, adjust rights of the Let's Encrypt directory, set admin password for Grafana):
```shell
# enable https in grafana
admin_password=$(cat /dev/urandom | tr -dc A-Za-z0-9 | fold -w 24 | head -n 1)
echo "Grafana Credentials: admin / ${admin_password}"
sed -i "s|;protocol.*|protocol = https|g" /etc/grafana/grafana.ini
sed -i "s|;cert_file.*|cert_file = /etc/letsencrypt/live/${domain}/cert.pem|g" /etc/grafana/grafana.ini
sed -i "s|;cert_key.*|cert_key = /etc/letsencrypt/live/${domain}/privkey.pem|g" /etc/grafana/grafana.ini
sed -i "s|;admin_password.*|admin_password = ${admin_password}|g" /etc/grafana/grafana.ini

chown -R root:grafana /etc/letsencrypt
chmod 755 /etc/letsencrypt/{live,archive}
```

Start the webserver and enable autostart:
```shell
systemctl daemon-reload
systemctl enable --now grafana-server
systemctl enable --now influxdb
systemctl enable --now prometheus
```
