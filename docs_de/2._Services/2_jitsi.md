# Jitsi (Debian 11)

Falls Sie Jitsi auf einer Debian 11 VM aufsetzen finden Sie hier ein Video zur Installation:
<video width="100%" height="240" controls>
  <source src="../../video/services/debian11_vm.mp4" type="video/mp4">
</video>

```shell
apt-get update
apt-get install -y curl sudo
sudo -s

export DOMAIN="jitsi.secshell.net"
export EMAIL="certificates@secshell.net"
export CF_API_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export PUBLIC_IPv4="88.99.59.71"

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/jitsi.sh | bash

# open id connect authentication
export AUTH_DOMAIN="jitsi-oidc.secshell.net"
export ISSUER_BASE_URL="https://id.secshell.net/auth/realms/main"
export CLIENT_SECRET="784e7868-777d-4476-9a66-aa59bc2aaf1e"

curl -fsSL https://docs.secshell.net/scripts/jitsi-oidc.sh | bash
```

Konfiguration: `/etc/jitsi/meet/jitsi.secshell.net-config.js` und `/usr/share/jitsi-meet/interface_config.js` 

Die Ports [10000/udp und 4443/tcp müssen über IPv4 erreichbar sein](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker#external-ports), daher werden sie über die IPv4 Adresse der OPNsense geforwarded:  
![](../img/services/jitsi_opnsense_nat.png?raw=true){: loading=lazy }
![](../img/services/jitsi_opnsense_wan.png?raw=true){: loading=lazy }
