!!! info ""
    In LXC Containern können keine weiteren Container (weder Docker, noch LXC) gestartet werden.

### Alpine LXC
Vor allem für Software ohne Abhängigkeiten (z. B. Redis, Datenbank, ...) empfielt sich die Verwendung eines Alpine Container, da dieser sehr klein ist und wenig Leistung verbraucht.

### Debian / Ubuntu
Unabhängig davon ob es sich bei dem Zielsystem um einen LXC Container oder eine Virtuelle Maschine handelt, sollten einige Details bei der Einrichtung beachtet werden.

Falls es sich um eine Virtuelle Maschine handelt, läuft die Installation des Debian Systems wie gewohnt. Die Installation eines Minimalen Systems wird empfohlen (bei Tasksel nur SSH Server anwählen).

Nach Abschluss der Installation werden die APT Repository-Server auf die von Hetzner zur Verfügung gestellten Server umgestellt, die Zeitzone konfiguriert und einige Standardpakete installiert:
```shell
# enable hetzner apt repositories
sed -i '1 i\deb http://mirror.hetzner.de/debian/packages buster main contrib non-free' /etc/apt/sources.list
sed -i '2 i\deb http://mirror.hetzner.de/debian/security buster/updates main contrib non-free' /etc/apt/sources.list
sed -i '3 i\deb http://mirror.hetzner.de/debian/packages buster-updates main contrib non-free' /etc/apt/sources.list

# configure timezone
ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# install basic software
apt-get update
apt-get upgrade -y
apt-get install -y sudo curl wget gnupg2
```
