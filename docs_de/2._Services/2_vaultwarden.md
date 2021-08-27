# Vaultwarden (Alpine 3.13)

```shell
apk add --update --no-cache curl

export DOMAIN="vault.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Account_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Zone_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

curl -fsSL https://docs.secshell.net/scripts/vaultwarden.sh | sh
```

## PostgreSQL Datenbank
```env
DATABASE_URL=postgresql://user:password@host[:port]/database_name
```

## MariaDB Datenbank
```env
DATABASE_URL=mysql://user:password@host[:port]/database_name
```
