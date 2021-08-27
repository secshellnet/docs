# Vaultwarden (Alpine 3.13)

```shell
apk add --update --no-cache curl

export DOMAIN="vault.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/vaultwarden.sh | sh
```

## PostgreSQL database
```env
DATABASE_URL=postgresql://vaultwarden:password@postgres.secshell.net/vaultwarden
```
