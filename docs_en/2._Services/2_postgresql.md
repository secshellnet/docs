# PostgreSQL (Alpine 3.13)

```shell
curl -fsSL https://docs.secshell.net/scripts/postgresql.sh | sh
```

## Create user
```shell
psql --user=postgres --no-password <<EOF
create database keycloak;
create user keycloak with encrypted password 's3cret_p4ssw0rd';
grant all privileges on database keycloak to keycloak;
EOF
```
