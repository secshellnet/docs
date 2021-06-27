# PrivateBin (Alpine 3.13)
You can simply execute the [install_privatebin.sh](./privatebin.sh) script. Afterwards you have to adjust the privatebin configuration in `/var/www/localhost/htdocs/cfg/conf.php`.

First install apache2 with php 7 support:
```shell
echo > /etc/motd

apk add php7-apache2 php-gd php-zlib
rm -r /var/www/localhost/htdocs/*
```

Next install privatebin:
```shell
wget -O- https://github.com/PrivateBin/PrivateBin/archive/refs/tags/1.3.5.tar.gz | tar -xzC /var/www/localhost/htdocs/ --strip 1
cp /var/www/localhost/htdocs/cfg/conf{.sample,}.php
```

Adjust the privatebin configuration (`/var/www/localhost/htdocs/cfg/conf.php`)

Start the webserver and enable autostart:
```shell
rc-update add apache2
service apache2 start
```
