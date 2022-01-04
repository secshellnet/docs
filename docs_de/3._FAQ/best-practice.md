# VM Setup: Best Practice
Dieses Dokument beschreibt das derzeit von mir bevorzugte Verfahren eine virtuelle Maschine mit Web-Anwendungen hinter dem Cloudflare Proxy erreichbar zu machen.

Da die Services lediglich auf einer öffentliche IPv6 Adresse bereitgestellt werden, ist die Verwendung des Cloudflare Proxies obligatorisch um die IPv4 Erreichbarkeit sicherzustellen. 

Ein Cloudflare Origin Server Certificate wird verwendet, wenn ein Dienst direkt aus dem Internet über https erreichbar sein soll. Browser vertrauen diesem Zertifikat nicht, weshalb die Nutzung des Cloudflare Proxies notwendig ist, durch diesen wird auch die IPv4-Erreichbarkeit sichergestellt.

Wird ein Dienst lediglich Intern benötigt (z. B. `keycloak.the-morpheus.org`) wird mithilfe der Software `acme.sh` (ACME DNS-01 Challenge) ein Let's Encrypt Zertifikat angefordert.

```
                                  |--- Privates Netzwerk (VPN) -------------------------------------|
                                  |                                                                 |
Cloudflare Proxy <-- https mit Origin Server Certificate --> nginx <-- http --> Docker Container    |
                                  |                            ^                                    |
                                  |                            |                                    |
                                  |          https mit Let's Encrypt Zertifikat                     |
                                  |                            |                                    |
                                  |                            |                                    |
                                  |                         Browser                                 |
                                  |                                                                 |
                                  |-----------------------------------------------------------------|
```

## Verwendung von `acme.sh` zwecks Erstellung der Let's Encrypt Zertifikat
Die Software `acme.sh` stellt eine minimimale Implementierung von ACME in Bash da. Wir verwenden die ACME DNS-01-Challenge mit der Cloudflare DNS API um die Zertifikate zu erhalten.

Die Installation gestaltet sich unter den meisten Betriebsystemen sehr einfach, hier als Beispiel für Debian 11:
```bash
# mit root-Rechten ausführen!
curl https://get.acme.sh | sh -s email=infrastructure@the-morpheus.de
sudo ln -s /root/.acme.sh/acme.sh /usr/bin/acme.sh
acme.sh --install-cronjob
```

Anschließend werden Environment Variablen für die Cloudflare DNS API gesetzt und das Let's Encrypt ACME backend genutzt:
```bash
export CF_Token=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CF_Account_ID=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CF_Zone_ID=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
```

Zuletzt wird ein ECC Zertifikat angefordert:
```bash
acme.sh --issue --keylength ec-384 --dns dns_cf -d keycloak.the-morpheus.org
```

## Verwendung von `nginx` als Reverse Proxy auf dem Host
Der Webserver `nginx` wird direkt auf dem Host installiert (`apt install nginx`), dieser agiert als Reverse Proxy und leitet die Requests an die Web Applications, die innerhalb der Docker Container laufen. Die Konfiguration dieser kann größtensteils von [ssl-config.mozilla.org](https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6) übernommen werden.


## Beispiel: Keycloak mit Public und interner Admin Domain 
Zuletzt möchte ich hier an einem Beispiel das Deployment von Keycloak erläutern.

```
                         |--- Privates Netzwerk (VPN) -------------------------------------|
                         |                                                                 |
Cloudflare Proxy <-- https://id.the-morpheus.de --> nginx <-- http --> Keycloak            |
                         |                            ^                                    |
                         |                            |                                    |
                         |           https://keycloak.the-morpheus.org                     |
                         |                            |                                    |
                         |                            |                                    |
                         |                          Admin                                  |
                         |                                                                 |
                         |-----------------------------------------------------------------|
```

In der `docker-compose.yml` wird für den Keycloak Service eine Portweiterleitung auf einen Local-Loopback (`[::1]` ist IPv6 für `127.0.0.1` aka `localhost`) Port gesetzt, der vom `nginx` angesprochen werden kann: 
```yml
version: '3.9'
services:
  keycloak:
    image: jboss/keycloak:16.1.0
    restart: always
    env_file: .keycloak.env
    ports:
      - "[::1]:8080:8080"
```

In der Konfiguration des internen nginx V-Hosts (`/etc/nginx/sites-available/keycloak.the-morpheus.org`) wird nur ein IPv4 Listener (der nur Intern verwendet wird) erstellt, außerdem werden mittels deny all alle Verbindungen aus dem Internet blockiert. 
```nginx
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name keycloak.the-morpheus.org;
    listen 443 ssl http2;

    ssl_certificate /root/.acme.sh/keycloak.the-morpheus.org_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/keycloak.the-morpheus.org_ecc/keycloak.the-morpheus.org.key;
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

    # ACL
    allow 10.0.0.0/8;
    allow 192.168.0.0/16;
    allow 172.16.0.0/12;
    allow 2a01:4f8:201:72cb::/64;
    deny all;

    location / {
            proxy_pass http://[::1]:8080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
    }
    
    # redirect to admin console
    location ~* ^(\/|\/auth\/)$ {
        return 301 https://keycloak.the-morpheus.org/auth/admin/master/console/;
    }
}
```

Der öffentlichen V-Host (`/etc/nginx/sites-available/id.the-morpheus.de`) wird auf eine spezifische IPv6 Adresse gebinded, desweiteren wird der Zugriff auf die Keycloak Admin URL's denied. Das Cloudflare Origin Server Certificate wurde in `/etc/ssl/` abgelegt.
```nginx
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name id.the-morpheus.de;
    listen [2001:db8::fdfd:dead:beef:affe]:443 ssl http2;

    ssl_certificate /etc/ssl/id.the-morpheus.de.crt;
    ssl_certificate_key /etc/ssl/id.the-morpheus.de.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    # modern configuration
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
            proxy_pass http://[::1]:8080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
    }

    # redirect to account login
    location ~* ^(\/|\/auth\/)$ {
        return 301 https://id.secshell.net/auth/realms/themorpheustutorials/account/;
    }

    # do not allow keycloak admin from this domain
    location ~* (\/auth\/admin\/|\/auth\/realms\/master\/) {
        return 403;
    }
}
```

Wenn weitere IPv6 Adressen benötigt werden (für jeden Service eine Adresse!) können diese in der `/etc/network/interfaces` wie folgt hinzugefügt werden:
```sh
allow-hotplug ens18
iface ens18 inet static
    address 10.25.36.3/31
    gateway 10.25.36.2

iface ens18 inet6 static
    # keycloak
    address 2001:db8::fdfd:dead:beef:affe/64
    gateway 2001:db8::1
    # service 2
    post-up ip -6 a add 2001:db8::fefe:dead:beef:affe/64 dev ens18
    # service 3
    post-up ip -6 a add 2001:db8::ffff:dead:beef:affe/64 dev ens18
```
