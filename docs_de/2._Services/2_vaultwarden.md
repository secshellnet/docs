# Vaultwarden (Alpine 3.13)

```shell
apk add --update --no-cache curl

export DOMAIN="vault.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

curl -fsSL https://docs.secshell.net/scripts/vaultwarden.sh | sh
```

## PostgreSQL Datenbank
```env
DATABASE_URL=postgresql://vaultwarden:password@postgres.secshell.net/vaultwarden
```
