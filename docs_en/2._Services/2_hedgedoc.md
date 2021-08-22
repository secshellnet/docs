# HedgeDoc (Alpine 3.13)

![](../img/services/hedgedoc.png?raw=true){: loading=lazy }

```shell
apk add --update --no-cache curl

export DOMAIN="md.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Account_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Zone_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

curl -fsSL https://docs.secshell.net/scripts/hedgedoc.sh | sh
```
