# Keycloak (Alpine 3.13)

```shell
apk add --update --no-cache curl

export DOMAIN="id.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/keycloak.sh | sh
```

## PostgreSQL
```shell
# add postgres jdbc driver
POSTGRES_VERSION=42.2.23
mkdir -p /opt/keycloak-${VERSION}/modules/system/layers/base/org/postgresql/jdbc/main
wget https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.jar -O /opt/keycloak-${VERSION}/modules/system/layers/base/org/postgresql/jdbc/main/postgres-jdbc.jar
wget https://raw.githubusercontent.com/keycloak/keycloak-containers/master/server/tools/databases/postgres/module.xml -O /opt/keycloak-${VERSION}/modules/system/layers/base/org/postgresql/jdbc/main/module.xml
cd /opt/keycloak-${VERSION}/

# configure postgresql database (arguments are: host, database, username, password)
java -jar /root/keycloak-configurator.jar /opt/keycloak-${VERSION}/standalone/configuration/standalone.xml postgres.secshell.net keycloak keycloak s3cret_p4ssw0rd

# restart keycloak
rc-service keycloak stop
rc-service keycloak start 
```

## Prometheus
* [Arch Linux: Keycloak Prometheus](https://wiki.archlinux.org/title/Keycloak#Keycloak_Prometheus_metrics)

