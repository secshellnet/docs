# PostgreSQL (Alpine 3.13)

The installation process is quiet simnple, for security reasons we recommend the hashing method `scram-sha-256` instead of `md5`.
```shell
apk add postgresql

# use scram-sha-256 instead of md5
sed -i '/^#password_encryption.* /{
  s/#//
  s/md5/scram-sha-256/
}' /etc/postgresql/postgresql.conf

# listen on all addresses 
sed -i '/^#listen_address.* /{
  s/#//
  s/localhost/*/
}' /etc/postgresql/postgresql.conf

# allow logins from anywhere using scram-sha-256 authentication method
echo -e "host\tall\t\tall\t\t0.0.0.0/0\t\tscram-sha-256" >> /etc/postgresql/pg_hba.conf
echo -e "host\tall\t\tall\t\t::0/0\t\t\tscram-sha-256" >> /etc/postgresql/pg_hba.conf

# enable autostart and start postgresql
rc-update add postgresql
rc-service postgresql start
```

## Create user
```shell
psql --user=postgres --no-password <<EOF
create database keycloak;
create user keycloak with encrypted password 's3cret_p4ssw0rd';
grant all privileges on database keycloak to keycloak;
EOF
```
