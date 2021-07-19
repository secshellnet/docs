# PrivateBin (Alpine 3.13)
Die Installation kann über das [install_privatebin.sh](./privatebin.sh) Script erfolgen. Die Konfiguration (`/var/www/localhost/htdocs/cfg/conf.php`) muss manuell durchgeführt werden!

Installation des Webservers mit PHP 7:
```shell
echo > /etc/motd

apk add php7-apache2 php-gd php-zlib php7-json
rm -r /var/www/localhost/htdocs/*
```

Installation der Anwendung: PrivateBin:
```shell
wget -O- https://github.com/PrivateBin/PrivateBin/archive/refs/tags/1.3.5.tar.gz | tar -xzC /var/www/localhost/htdocs/ --strip 1
cp /var/www/localhost/htdocs/cfg/conf{.sample,}.php
```

Anschließend wird PrivateBin konfiguriert (`/var/www/localhost/htdocs/cfg/conf.php`)

Zuletzt wird der Service gestartet und zum Autostart hinzugefügt:
```shell
rc-update add apache2
service apache2 start
```
