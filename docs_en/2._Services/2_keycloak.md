# Keycloak (Alpine 3.13)
You can run the installation using the [install_keycloak.sh](./keycloak.sh) script.

Install keycloak:
```shell
echo > /etc/motd

apk add --update --no-cache openjdk11-jre nginx acme.sh socat
wget -O- https://github.com/keycloak/keycloak/releases/download/15.0.1/keycloak-15.0.1.tar.gz | tar xzC /opt/
cd /opt/keycloak-15.0.1
```

Aquire TLS certificate:
```shell
domain="id.secshell.net"

export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Account_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export CF_Zone_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
acme.sh --issue --dns dns_cf -d ${domain}
```

configure nginx:
```shell
cat << EOF > /etc/nginx/conf.d/default.conf
server {
    server_name ${domain};
    listen 80 default_server;
    listen [::]:80 default_server;
 
    location / {
        return 301 https://\$host\$request_uri;
    }
}
 
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
 
    ssl_certificate /root/.acme.sh/${domain}/${domain}.cer;
    ssl_certificate_key /root/.acme.sh/${domain}/${domain}.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;
 
    # intermediate configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
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
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
         
    }
}
EOF
```

fix keycloak UnknownHostException
```shell
echo -e "127.0.0.1\tkeycloak" >> /etc/hosts
```

create keycloak service and configure autostart:
```shell
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
```

## Configure Keycloak
After you finished the installation you can create the administrative user:
![](../img/services/keycloak_welcome.png?raw=true){: loading=lazy }
