# Keycloak (Alpine 3.13)

```shell
apk add --update --no-cache curl

export DOMAIN="id.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Account_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Zone_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

curl -fsSL https://docs.secshell.net/scripts/keycloak.sh | sh
```
