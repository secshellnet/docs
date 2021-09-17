# NetBox (Alpine 3.13)

Zuerst wird ein neuer Nutzer auf dem PostgreSQL Server angelegt, dieser erhält Zugriff auf eine Datenbank.
```shell
psql --user=postgres --no-password <<EOF
create database netbox;
create user netbox with encrypted password 's3cr3t_p4ssw0rd';
grant all privileges on database netbox to netbox;
EOF
```

Anschließend wird das Installations-Skript in einem eigenen LXC ausgeführt:
```shell
apk add --update --no-cache curl

export DOMAIN="netbox.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# PostgreSQL settings
export PG_HOST=postgres.secshell.net
#export PG_PORT=5432
#export PG_USER=netbox
export PG_PASS='s3cr3t_p4ssw0rd'
#export PG_DBNAME=netbox


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
