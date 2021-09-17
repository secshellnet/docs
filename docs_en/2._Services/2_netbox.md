# NetBox (Alpine 3.13)

First we need to create a new user and a database on the postgresql server.
```shell
psql --user=postgres --no-password <<EOF
create database netbox;
create user netbox with encrypted password 's3cr3t_p4ssw0rd';
grant all privileges on database netbox to netbox;
EOF
```

Afterwards we will run the installation script in it's own lxc:
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

## Create administrative account
```sh
python3 /opt/netbox/netbox/manage.py createsuperuser
```
