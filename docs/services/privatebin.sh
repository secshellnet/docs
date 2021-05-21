#!/bin/sh

echo > /etc/motd

apk add php7-apache2 php-gd php-zlib
rm -r /var/www/localhost/htdocs/*

wget -O- https://github.com/PrivateBin/PrivateBin/archive/refs/tags/1.3.5.tar.gz | tar -xzC /var/www/localhost/htdocs/ --strip 1
cp /var/www/localhost/htdocs/cfg/conf{.sample,}.php

# adjust /var/www/localhost/htdocs/cfg/conf.php

rc-update add apache2
service apache2 start
