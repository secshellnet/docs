#!/bin/sh

echo >/etc/motd

apk add --no-cache --update postgresql

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
