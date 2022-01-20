# Synapse (Debian 11)

!!! warning ""
    I no longer deploy applications in lxc containers, due to complex updates which results in errors.

```shell
apt-get update
apt-get -y install curl sudo
sudo -s

export SYNAPSE_DOMAIN="synapse.secshell.net"
export MATRIX_DOMAIN="matrix.secshell.net"
export ELEMENT_DOMAIN="element.secshell.net"
export JITSI_DOMAIN="meet.jit.si"
export EMAIL="certificates@secshell.net"
export CF_API_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/synapse.sh | bash
```

Configuration: `/etc/matrix-synapse/homeserver.yaml`
