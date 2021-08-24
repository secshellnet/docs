# Synapse (Debian 11)

```shell
apt-get update
apt-get -y install curl sudo
sudo -s

export SYNAPSE_DOMAIN="synapse.secshell.net"
export MATRIX_DOMAIN="matrix.secshell.net"
export ELEMENT_DOMAIN="element.secshell.net"
export EMAIL="certificates@secshell.net"
export CF_API_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

curl -fsSL https://docs.secshell.net/scripts/synapse.sh | bash
```

Configuration: `/etc/matrix-synapse/homeserver.yaml`
