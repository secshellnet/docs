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
Not working yet...
```shell
# add postgres jdbc driver
mkdir -p ./modules/system/layers/base/org/postgres/jdbc/main
cd ./modules/system/layers/base/org/postgres/jdbc/main/
wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.23/postgresql-42.2.23.jar -O ./postgres-jdbc.jar
wget https://raw.githubusercontent.com/keycloak/keycloak-containers/master/server/tools/databases/postgres/module.xml
```

Afterwards you have to configure the standalone.xml [according to this cli script](https://github.com/keycloak/keycloak-containers/blob/master/server/tools/cli/databases/postgres/change-database.cli):
```xml
                <datasource jndi-name="java:jboss/datasources/KeycloakDS" pool-name="KeycloakDS" enabled="true" use-java-context="true" use-ccm="true">
                    <connection-url>jdbc:postgresql://postgres.secshell.net/keycloak</connection-url>
                    <driver>postgresql</driver>
                    <pool>
                        <flush-strategy>IdleConnections</flush-strategy>
                    </pool>
                    <security>
                        <user-name>keycloak</user-name>
                        <password>password password}</password>
                    </security>
                    <validation>
                        <check-valid-connection-sql>SELECT 1</check-valid-connection-sql>
                        <background-validation>true</background-validation>
                        <background-validation-millis>60000</background-validation-millis>
                    </validation>
                </datasource>

                    <driver name="postgresql" module="org.postgresql.jdbc">
                        <xa-datasource-class>org.postgresql.xa.PGXADataSource</xa-datasource-class>
                    </driver>

                    <property name="schema" value="${env.DB_SCHEMA:public}"/>
```
