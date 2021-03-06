# Dendrite (Alpine 3.13)

!!! warning ""
    I no longer deploy applications in lxc containers, due to complex updates which results in errors.

## Prepare PostgreSQL database:
If you prefere to use a postgresql database, you should configure it directly:
```shell
# create databases
for db in mscs userapi_accounts userapi_devices mediaapi syncapi roomserver signingkeyserver keyserver federationsender appservice naffka; do
    psql --user=postgres --no-password -c "create database ${db}";
done

# create user
psql --user=postgres --no-password -c "create user dendrite with encrypted password 's3cret_p4ssw0rd';"

# grant access
for db in mscs userapi_accounts userapi_devices mediaapi syncapi roomserver signingkeyserver keyserver federationsender appservice naffka; do
    psql --user=postgres --no-password -c "grant all privileges on database ${db} to dendrite;"
done
```

## Install Dendrite
```shell
apk add --update --no-cache curl

export DENDRITE_DOMAIN="dendrite.secshell.net"
export MATRIX_DOMAIN="matrix.secshell.net"
export ELEMENT_DOMAIN="element.secshell.net"
export JITSI_DOMAIN="meet.jit.si"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# PostgreSQL configuration (comment out to setup using sqlite database)
export PG_HOST=postgres.secshell.net
export PG_USER=dendrite
export PG_PASSWD=s3cret_p4ssw0rd

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/dendrite.sh | sh
```

## Create Dendrite User
```shell
/root/dendrite/bin/create-account \
    --config dendrite.yaml \
    --username username \
    --ask-pass
```
