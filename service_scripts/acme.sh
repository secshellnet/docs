#!/bin/sh

### configuration
CF_TOKEN='XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
CF_ACCOUNT_ID='XXXXXXXXXXXXXXXXXXXXXXX'
CF_ZONE_ID='XXXXXXXXXXXXXXXXXXXXXXXXXX'
DOMAIN='acme.secshell.net'
### end of configuration

apk add acme.sh

# install crontab
cat <<EOF >> /etc/crontabs/root
# renew letsencrypt certificates every 15 days
22 3 */15 * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
EOF

# set letsencrypt acme server
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca

# store credentials for cloudflare dns
cat << EOF > /root/.acme.sh/account.conf 
SAVED_CF_Token='${CF_TOKEN}'
SAVED_CF_Account_ID='${CF_ACCOUNT_ID}'
SAVED_CF_Zone_ID='${CF_ZONE_ID}'
EOF

# get certificate using acme dns-01 challenge
acme.sh --issue --dns dns_cf -d ${domain}
