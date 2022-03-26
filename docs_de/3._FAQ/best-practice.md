# VM Setup: Best Practice
Dieses Dokument beschreibt das derzeit von mir bevorzugte Verfahren eine virtuelle Maschine mit Web-Anwendungen hinter dem Cloudflare Proxy erreichbar zu machen.

Grundsätzlich stelle ich webbasierte Anwendungen nur noch über IPv6 zur Verfügung. Um die IPv4 Erreichbarkeit zu sichern, und gegebenenfalls eine [Web Application Firewall](https://www.cloudflare.com/waf/) oder [Page Rules](https://www.cloudflare.com/features-page-rules/) schalten zu können, wird der Cloudflare Proxy verwendet.

Cloudflare verbindet sich per IPv6 mit der webbasierten Anwendung auf meinem Server. Mittels [Origin Server Certificates](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca) wird die Verbindung verschlüsselt.

Um sicherzustellen, dass die WAF / Page Rules nicht umgangen werden können, erwartet mein Webserver ein TLS Client Zertifikat von der Cloudflare Origin Pull CA, [die Einrichtung bei Cloudflare wird hier beschrieben](https://developers.cloudflare.com/ssl/origin-configuration/authenticated-origin-pull/set-up).

Wenn mehr als eine webbasierte Anwendung auf einem Server installiert werden, weise ich mir für jeden Dienst eine eigene IPv6 Adresse zu. Dies macht zum einen das Sperren eines einzelnen Dienstes in der Firewall, als auch das Debuggen einfacher. Unter Debian wird dafür die Netzwerkkonfiguration in der Datei `/etc/network/interfaces` wie folgt erweitert:
```sh
allow-hotplug ens18
iface ens18 inet dhcp

iface ens18 inet6 static
    # service 1 
    address 2001:db8::fdfd:dead:beef:affe/64
    gateway 2001:db8::1
    # service 2
    post-up ip -6 a add 2001:db8::fefe:dead:beef:affe/64 dev ens18    # <---- this line
    # service 3
    post-up ip -6 a add 2001:db8::ffff:dead:beef:affe/64 dev ens18    # <---- this line
```

In meinem Setup existiert ein internes Netzwerk, worüber administrative Dienste verfügbar gemacht werden können (z. B. Admin Panel). Für diese Seiten wird mithilfe der Software `acme.sh` über die ACME DNS-01 Challenge ein Let's Encrypt Zertifikat angefordert.

```
               |--- Privates Netzwerk (VPN) ----------------------------|
               |                                                        |
CF-Proxy <-- https mit OS-Cert --> nginx <-- http --> Docker Container  |
   ^           |                     ^                                  |
   |           |                     |                                  |
   |           |              https mit LE-Cert                         |
   |           |                     |                                  |
Browser        |                  Browser                               |
               |                                                        |
               |--------------------------------------------------------|
Legende:
Cloudflare Proxy:           CF-Proxy
Origin-Server Certificate:  OS-Cert
Let's Encrypt Certificate:  LE-Cert
```

## `nginx` setup
Für die webbasierten Anwendungen auf meinem Server verwende ich meist den Webserver `nginx`. Die Konfiguration kann größtenteils von [ssl-config.mozilla.org](https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6) übernommen werden. Lediglich einige Einstellungen bezüglich der Cloudflare Origin-Server / Pull-Client Certificates müssen angepasst werden:

Das Cloudflare Origin Pull CA Zertifikat muss auf dem System abgelegt sein, damit `nginx` die TLS Client Zertifikate überprüfen kann. Ich lege dieses unter dem Pfad `/etc/ssl/cloudflare_ca.crt` ab.
```pem
-----BEGIN CERTIFICATE-----
MIIGCjCCA/KgAwIBAgIIV5G6lVbCLmEwDQYJKoZIhvcNAQENBQAwgZAxCzAJBgNV
BAYTAlVTMRkwFwYDVQQKExBDbG91ZEZsYXJlLCBJbmMuMRQwEgYDVQQLEwtPcmln
aW4gUHVsbDEWMBQGA1UEBxMNU2FuIEZyYW5jaXNjbzETMBEGA1UECBMKQ2FsaWZv
cm5pYTEjMCEGA1UEAxMab3JpZ2luLXB1bGwuY2xvdWRmbGFyZS5uZXQwHhcNMTkx
MDEwMTg0NTAwWhcNMjkxMTAxMTcwMDAwWjCBkDELMAkGA1UEBhMCVVMxGTAXBgNV
BAoTEENsb3VkRmxhcmUsIEluYy4xFDASBgNVBAsTC09yaWdpbiBQdWxsMRYwFAYD
VQQHEw1TYW4gRnJhbmNpc2NvMRMwEQYDVQQIEwpDYWxpZm9ybmlhMSMwIQYDVQQD
ExpvcmlnaW4tcHVsbC5jbG91ZGZsYXJlLm5ldDCCAiIwDQYJKoZIhvcNAQEBBQAD
ggIPADCCAgoCggIBAN2y2zojYfl0bKfhp0AJBFeV+jQqbCw3sHmvEPwLmqDLqynI
42tZXR5y914ZB9ZrwbL/K5O46exd/LujJnV2b3dzcx5rtiQzso0xzljqbnbQT20e
ihx/WrF4OkZKydZzsdaJsWAPuplDH5P7J82q3re88jQdgE5hqjqFZ3clCG7lxoBw
hLaazm3NJJlUfzdk97ouRvnFGAuXd5cQVx8jYOOeU60sWqmMe4QHdOvpqB91bJoY
QSKVFjUgHeTpN8tNpKJfb9LIn3pun3bC9NKNHtRKMNX3Kl/sAPq7q/AlndvA2Kw3
Dkum2mHQUGdzVHqcOgea9BGjLK2h7SuX93zTWL02u799dr6Xkrad/WShHchfjjRn
aL35niJUDr02YJtPgxWObsrfOU63B8juLUphW/4BOjjJyAG5l9j1//aUGEi/sEe5
lqVv0P78QrxoxR+MMXiJwQab5FB8TG/ac6mRHgF9CmkX90uaRh+OC07XjTdfSKGR
PpM9hB2ZhLol/nf8qmoLdoD5HvODZuKu2+muKeVHXgw2/A6wM7OwrinxZiyBk5Hh
CvaADH7PZpU6z/zv5NU5HSvXiKtCzFuDu4/Zfi34RfHXeCUfHAb4KfNRXJwMsxUa
+4ZpSAX2G6RnGU5meuXpU5/V+DQJp/e69XyyY6RXDoMywaEFlIlXBqjRRA2pAgMB
AAGjZjBkMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgECMB0GA1Ud
DgQWBBRDWUsraYuA4REzalfNVzjann3F6zAfBgNVHSMEGDAWgBRDWUsraYuA4REz
alfNVzjann3F6zANBgkqhkiG9w0BAQ0FAAOCAgEAkQ+T9nqcSlAuW/90DeYmQOW1
QhqOor5psBEGvxbNGV2hdLJY8h6QUq48BCevcMChg/L1CkznBNI40i3/6heDn3IS
zVEwXKf34pPFCACWVMZxbQjkNRTiH8iRur9EsaNQ5oXCPJkhwg2+IFyoPAAYURoX
VcI9SCDUa45clmYHJ/XYwV1icGVI8/9b2JUqklnOTa5tugwIUi5sTfipNcJXHhgz
6BKYDl0/UP0lLKbsUETXeTGDiDpxZYIgbcFrRDDkHC6BSvdWVEiH5b9mH2BON60z
0O0j8EEKTwi9jnafVtZQXP/D8yoVowdFDjXcKkOPF/1gIh9qrFR6GdoPVgB3SkLc
5ulBqZaCHm563jsvWb/kXJnlFxW+1bsO9BDD6DweBcGdNurgmH625wBXksSdD7y/
fakk8DagjbjKShYlPEFOAqEcliwjF45eabL0t27MJV61O/jHzHL3dknXeE4BDa2j
bA+JbyJeUMtU7KMsxvx82RmhqBEJJDBCJ3scVptvhDMRrtqDBW5JShxoAOcpFQGm
iYWicn46nPDjgTU0bX1ZPpTpryXbvciVL5RkVBuyX2ntcOLDPlZWgxZCBp96x07F
AnOzKgZk4RzZPNAxCXERVxajn/FLcOhglVAKo5H0ac+AitlQ0ip55D2/mf8o72tM
fVQ6VpyjEXdiIXWUq/o=
-----END CERTIFICATE-----
```

### Service startet nicht
Sollte es vorkommen, dass der nginx beim Neustart des Servers nicht startet, weil die IPv6 Adresse (die als listener konfiguriert wurde) noch nicht zum Interface hinzugefügt wurde, kann der Startprozess des nginx wie [hier](https://docs.ispsystem.com/ispmanager-business/troubleshooting-guide/if-nginx-does-not-start-after-rebooting-the-server) beschrieben verzögert werden. Dazu wird die Datei `/lib/systemd/system/nginx.service` in der Kategorie Service wie folgt erweitert:
```s
# make sure the ipv6 addresses (which have been added with post-up) are there (only required for enabled nginx service on system boot)
ExecStartPre=/bin/sleep 5
```

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
export CF_Token=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CF_Account_ID=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CF_Zone_ID=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
```

Zuletzt wird ein ECC Zertifikat angefordert:
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
