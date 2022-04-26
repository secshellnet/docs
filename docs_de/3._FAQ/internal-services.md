# VM Setup: Internal Services
Dieses Dokument erweitert den [AdminGuide](https://adminguide.pages.dev/) und erläutert die Bereitstellung von Services im Internen Netzwerk.

In meinem Setup existiert ein internes Netzwerk, worüber administrative Dienste verfügbar gemacht werden können (z. B. Admin Panel). Für diese Seiten wird mithilfe der Software `acme.sh` über die ACME DNS-01 Challenge ein Let's Encrypt Zertifikat angefordert.

![Schaubild](../img/faq/internal-services.png?raw=true){: loading=lazy }

## Verwendung von `acme.sh` zwecks Erstellung der Let's Encrypt Zertifikat
Die Software `acme.sh` stellt eine minimimale Implementierung von [ACME](https://datatracker.ietf.org/doc/html/rfc8555) in Bash da. Wir verwenden die ACME DNS-01-Challenge mit der Cloudflare DNS API um die intern Verwendeten Zertifikate zu erhalten.

Die Installation gestaltet sich unter den meisten Betriebsystemen sehr einfach, hier als Beispiel für Debian 11:
```bash
# mit root-Rechten ausführen!
curl https://get.acme.sh | sh -s email=infrastructure@secshell.net
sudo ln -s /root/.acme.sh/acme.sh /usr/bin/acme.sh
acme.sh --install-cronjob
```

Anschließend werden Environment Variablen für die Cloudflare DNS API gesetzt und das Let's Encrypt ACME Backend genutzt:
```bash
export CF_Token=
export CF_Account_ID=b6150c745385ae6ec778daef69a6ed19
export CF_Zone_ID=1b5abe1a94042aad89a26481d710aaf0
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
```

Zuletzt wird ein ECC Zertifikat für die gewünschte Domain angefordert:
```bash
acme.sh --issue --keylength ec-384 --dns dns_cf -d keycloak.pve2.secshell.net
```

## Beispiel: Keycloak mit Public und interner Admin Domain 
Zuletzt möchte ich hier an einem Beispiel das Deployment von Keycloak erläutern.

```
                 |--- Privates Netzwerk (VPN) -----------------------|
                 |                                                   |
CF-Proxy <-- https://id.secshell.net --> nginx <-- http --> Keycloak |
   ^             |                         ^                         |
   |             |                         |                         |
   |             |         https://keycloak.pve2.secshell.net        |
   |             |                         |                         |
   |             |                         |                         |
Browser          |                       Admin                       |
                 |---------------------------------------------------|
```

In der `docker-compose.yml` wird für den Keycloak Service eine Portweiterleitung auf einen Local-Loopback (`[::1]` ist IPv6 für `127.0.0.1` aka `localhost`) Port gesetzt, der vom `nginx` angesprochen werden kann: 
```yml
version: '3.9'
services:
  keycloak:
    image: ghcr.io/secshellnet/keycloak
    restart: always
    env_file: .keycloak.env
    ports:
      - "[::1]:8080:8080"
```

In der Konfiguration des internen nginx V-Hosts (`/etc/nginx/sites-available/keycloak.pve2.secshell.net`) wird nur ein IPv4 Listener (der nur intern verwendet wird) erstellt, außerdem werden mittels deny all alle Verbindungen aus dem Internet blockiert. 
```nginx
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name keycloak.pve2.secshell.net;
    listen 0.0.0.0:443 ssl http2;

    ssl_certificate /root/.acme.sh/keycloak.pve2.secshell.net_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/keycloak.pve2.secshell.net_ecc/keycloak.pve2.secshell.net.key;
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
    location ~* ^(\/)$ {
        return 301 https://keycloak.pve2.secshell.net/admin/master/console/;
    }
}
```

Der öffentlichen V-Host (`/etc/nginx/sites-available/id.secshell.net`) wird auf eine spezifische IPv6 Adresse gebinded, desweiteren wird der Zugriff auf die Keycloak Admin URL's denied. Das Cloudflare Origin Server Certificate wurde in `/etc/ssl/` abgelegt.
```nginx
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
server {
    server_name id.secshell.net;
    listen [2001:db8::fdfd:dead:beef:affe]:443 ssl http2;

    ssl_certificate /etc/ssl/id.secshell.net.crt;
    ssl_certificate_key /etc/ssl/id.secshell.net.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    # modern configuration
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    # only allow cloudflare to connect to your nginx
    ssl_client_certificate /etc/ssl/cloudflare_ca.crt;
    ssl_verify_client on;

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
    location ~* ^(\/)$ {
        return 301 https://id.secshell.net/realms/main/account/;
    }

    # do not allow keycloak admin from this domain
    location ~* (\/admin\/|\/realms\/master\/) {
        return 403;
    }
}
```
