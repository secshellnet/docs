# Monitoring (Debian 10.7)
Die Installation kann über das [install_monitoring.sh](./monitoring.sh) Script erfolgen, ganz oben muss die Konfiguration (cloudflare token, domain, email) angepasst werden.

Zuerst werden die apt Repositories von Hetzner Online hinzugefügt und die Zeitzone angepasst:
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

Anschließend werden die Updates und benötigte Tools installiert, sodass die Paketquellen für grafana und influxdb hinzugefügt werden können. Im weiteren Verlauf, werden diese Pakete installiert:
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

Im Anschluss wird der Certbot sowie die aktuelle Version der Cloudflare Libary installiert. Dadurch kann man die Cloudflare API-Tokens anstelle des Global API Key für die ACME DNS-01 Challenge nutzen. Nach der Installation wird das gewünschte Zertifikat angefordert:
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

Die konfiguration von Grafana wird entsprechend angepasst (HTTPS aktivieren, Pfad zu Zertifikat setzen, Rechte des Let's Encrypt Verzeichnisses anpassen, Admin Passwort für Grafana setzen).
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

Zuletzt werden alle Dienste gestartet und dem Autostart hinzugefügt.
```shell
systemctl daemon-reload
systemctl enable --now grafana-server
systemctl enable --now influxdb
systemctl enable --now prometheus
```
