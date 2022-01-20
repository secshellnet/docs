# Syncthing (Alpine 3.13)

!!! warning ""
    I no longer deploy applications in lxc containers, due to complex updates which results in errors.

```shell
apk add --update --no-cache curl openssl

export PASSWORD=$(openssl rand -hex 24)

curl -fsSL https://docs.secshell.net/scripts/syncthing.sh | sh
```
