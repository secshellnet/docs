# General Information

!!! info ""
    You can't run containers (neighter docker nor lxc) in lxc containers.

### Alpine LXC
Especially for software without dependencies (e.g. Redis, database, ...) the use of an Alpine container is recommended, because it is very small and consumes less computing power.

### Debian / Ubuntu
Regardless of whether the target system is an LXC container or a virtual machine, some details should be considered during setup.

If it is a virtual machine, the installation of the Debian system runs as usual. The installation of a minimal system is recommended (at tasksel select SSH Server only).

After the installation is complete, the APT repository servers are switched to the servers provided by Hetzner, the time zone is configured and some default packages are installed:
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
