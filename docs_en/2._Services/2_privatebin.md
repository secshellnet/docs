# PrivateBin (Alpine 3.13)

```shell
apk add --update --no-cache curl

export DOMAIN="bin.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

curl -fsSL https://docs.secshell.net/scripts/privatebin.sh | sh
```

Configuration: `/var/www/privatebin/cfg/conf.php`
