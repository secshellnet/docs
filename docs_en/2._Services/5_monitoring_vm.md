# Monitoring VM (Debian 11)

```shell
apt-get update
apt-get install -y curl sudo
sudo -s

export DOMAIN="grafana.secshell.net"
export EMAIL="certificates@secshell.net"
export CF_API_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/monitoring.sh | sh
```
