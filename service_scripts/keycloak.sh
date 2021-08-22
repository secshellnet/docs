#!/bin/sh

### configuration
domain="id.secshell.net"

export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Account_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Zone_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
### end of configuration

echo > /etc/motd

# install keycloak
apk add --update --no-cache openjdk11-jre nginx acme.sh socat
wget -O- https://github.com/keycloak/keycloak/releases/download/15.0.1/keycloak-15.0.1.tar.gz | tar xzC /opt/
cd /opt/keycloak-15.0.1

# get certificate
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --dns dns_cf -d ${domain}


# configure nginx
cat << EOF > /etc/nginx/conf.d/default.conf
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /root/.acme.sh/${domain}/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/${domain}/${domain}.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    # modern configuration
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    location / {
            proxy_pass http://127.0.0.1:8080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Forwarded-For \$proxy_protocol_addr;
            proxy_set_header X-Forwarded-Proto \$schema;
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
    }
}
EOF


# fix UnknownHostException
echo -e "127.0.0.1\tkeycloak" >> /etc/hosts


# create keycloak service and configure autostart
cat <<EOF > /etc/init.d/keycloak
#!/sbin/openrc-run
 
function start {
  sh /opt/keycloak-15.0.1/bin/standalone.sh & 2>&1 >/dev/null
}
EOF
chmod +x /etc/init.d/keycloak
 
rc-update add nginx
rc-service nginx restart
rc-update add keycloak
rc-service keycloak start

