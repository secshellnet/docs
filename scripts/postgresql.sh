#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

echo >/etc/motd

# stop execution on failure
set -e

apk add --no-cache --update postgresql openssh-server bc

rc-service postgresql start
rc-service postgresql restart

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

# change location of authorized keys file (.ssh/authorized_keys is no longer required so it can be removed)
mkdir -p /etc/ssh/authorized_keys
sed -i 's|AuthorizedKeysFile.*|AuthorizedKeysFile /etc/ssh/authorized_keys/%u|g' /etc/ssh/sshd_config

# create user without password and shell
adduser --shell=/bin/false --disabled-password exporter

# unlock user
passwd -u exporter

# ssh keys
touch /etc/ssh/authorized_keys/exporter
echo "Make sure to add the ssh key of exporter to /etc/ssh/authorized_keys/exporter"

chown root:root /home/exporter

# configure sftp jail
cat <<EOF >> /etc/ssh/sshd_config
Match User exporter
   ChrootDirectory /home/exporter
   ForceCommand internal-sftp
   AllowTCPForwarding no
   X11Forwarding no

Match all
EOF

# create script which create a backup of the postgresql database in /home/exporter
cat <<EOF > /root/backup.sh
#!/bin/sh
DATE=$(date +"%Y-%m-%d_%H")-$(echo "$(date +%M) - ($(date +%M)%15)" | bc)
pg_dumpall --username="postgres" --file="/home/exporter/\${DATE}.sql"
ln /home/exporter/\$DATE.sql /home/exporter/postgres.sql
EOF

chmod +x /root/backup.sh

# enable autostart and start postgresql
rc-update add postgresql
rc-service postgresql restart
rc-update add sshd
rc-service sshd restart
