# Jitsi VM (Debian 11)

```shell
apt-get install -y curl

export DOMAIN="jitsi.secshell.net"
export EMAIL="certificates@secshell.net"
export CF_API_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

curl -fsSL https://docs.secshell.net/scripts/jitsi.sh | bash


# open id connect authentication
#export DOMAIN="jitsi.secshell.net"
#export EMAIL="certificates@secshell.net"
#export CF_API_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export AUTH_DOMAIN="jitsi-oidc.secshell.net"
export ISSUER_BASE_URL="https://id.secshell.net/auth/realms/main"
export CLIENT_SECRET="784e7868-777d-4476-9a66-aa59bc2aaf1e"

curl -fsSL https://docs.secshell.net/scripts/jitsi-oidc.sh | bash
```

Configuration: `/etc/jitsi/meet/jitsi.secshell.net-config.js` and `/usr/share/jitsi-meet/interface_config.js` 

