# Bookstack (Ubuntu 21.04)

```shell
apt-get update
apt-get -y install curl sudo
sudo -s

export DOMAIN="docs.secshell.net"
export EMAIL="certificates@secshell.net"
export CF_API_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/bookstack.sh | sh
```
