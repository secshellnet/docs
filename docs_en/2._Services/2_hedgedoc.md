# HedgeDoc (Alpine 3.13)

![](../img/services/hedgedoc.png?raw=true){: loading=lazy }

You need at least 2 gb of ram to install hedgedoc, for productive usage 512 mb are sufficient.

```shell
apk add --update --no-cache curl

export DOMAIN="md.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/hedgedoc.sh | sh
```

## PostgreSQL database
```json
    "db": {
      "dialect": "postgres",
      "username": "hedgedoc",
      "password": "$(cat /dev/urandom | tr -dcA-Za-z0-9 | fold -w24 | head -n1)",
      "database": "hedgedoc",
      "host": "postgres.secshell.net"
    },
```

## Keycloak OIDC
```json
    "oauth2": {
      "providerName": "Keycloak",
      "userProfileURL": "https://id.secshell.net/auth/realms/main/protocol/openid-connect/userinfo",
      "userProfileUsernameAttr": "preferred_username",
      "userProfileDisplayNameAttr": "name",
      "userProfileEmailAttr": "email",
      "tokenURL": "https://id.secshell.net/auth/realms/main/protocol/openid-connect/token",
      "authorizationURL": "https://id.secshell.net/auth/realms/main/protocol/openid-connect/auth",
      "clientID": "md.secshell.net",
      "clientSecret": "912bc300-561c-4ba6-939f-5fdc00cf13a0"
    },
```
