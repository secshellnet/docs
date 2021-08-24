# Syncthing (Alpine 3.13)

```shell
apk add --update --no-cache curl openssl

export PASSWORD=$(openssl rand -hex 24)

curl -fsSL https://docs.secshell.net/scripts/syncthing.sh | sh
```
