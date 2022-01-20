# Syncthing (Alpine 3.13)

!!! warning ""
    Aufgrund von komplexen Aktualisierungsprozessen und daraus resultierenden Problemen deploye ich keine Applications mehr in LXC Container.
    
```shell
apk add --update --no-cache curl openssl

export PASSWORD=$(openssl rand -hex 24)

curl -fsSL https://docs.secshell.net/scripts/syncthing.sh | sh
```
