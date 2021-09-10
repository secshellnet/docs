# NetBox (Alpine 3.13)

```shell
apk add --update --no-cache curl

export DOMAIN="netbox.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/netbox.sh | sh
```

## Administrativen Account erstellen
```sh
python3 /opt/netbox/netbox/manage.py createsuperuser
```
