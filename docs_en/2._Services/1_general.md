# General Information

!!! info ""
    You can't run containers (neighter docker nor lxc) in lxc containers.

## Repositories
### Debian
```shell
# enable hetzner apt repositories
function add {
    sed -i '1 i\deb http://mirror.hetzner.de/debian/packages ${1} main contrib non-free' /etc/apt/sources.list
    sed -i '2 i\deb http://mirror.hetzner.de/debian/security ${1}/updates main contrib non-free' /etc/apt/sources.list
    sed -i '3 i\deb http://mirror.hetzner.de/debian/packages ${1}-updates main contrib non-free' /etc/apt/sources.list
}
source /etc/os-release  
test $VERSION_ID = "7" && add wheezy
test $VERSION_ID = "8" && add jussie
test $VERSION_ID = "9" && add stretch
test $VERSION_ID = "10" && add buster
test $VERSION_ID = "11" && add bullseye
```

### Ubuntu
```shell
# enable hetzner apt repositories
function add {
    sed -i '1 i\deb http://mirror.hetzner.com/ubuntu/packages ${1} main restricted universe multiverse' /etc/apt/sources.list
    sed -i '2 i\deb http://mirror.hetzner.com/ubuntu/packages ${1}-updates main restricted universe multiverse' /etc/apt/sources.list
    sed -i '3 i\deb http://mirror.hetzner.com/ubuntu/packages ${1}-security main restricted universe multiverse' /etc/apt/sources.list
}
source /etc/lsb-release
test $DISTRIB_RELEASE = "20.04" && add focal
test $DISTRIB_RELEASE = "18.04" && add bionic
test $DISTRIB_RELEASE = "16.04" && add xenial
```

## Adjust Timezone
### Debian / Ubuntu
```shell
# configure timezone
ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
```

## VM configure IPv6
### Debian 11
```shell
VLAN_ID=101
sudo -s
cat <<EOF >> /etc/network/interfaces

iface ens18 inet6 static
    address 2a01:4f8:10a:b88:${VLAN_ID}::2
    network 80
    gateway 2a01:4f8:10a:b88:${VLAN_ID}::1
EOF
```
