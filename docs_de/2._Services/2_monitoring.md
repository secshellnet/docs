# Monitoring (Debian 11)

Wir empfehlen die Installation in einer VM, da InfluxDB in einem LXC Container bei unseren Tests regelmäßig abgestürzt ist.
```shell
apt-get update
apt-get install -y curl sudo
sudo -s

export DOMAIN="grafana.secshell.net"
export CF_Token="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export ADMIN_PASSWD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | fold -w24 | head -n1)

# DNS API Script
export CHECK_DNS=1
export UPDATE_DNS=1
export CF_PROXIED='true'

curl -fsSL https://docs.secshell.net/scripts/monitoring.sh | bash
```

## Keycloak OIDC
Informationen zur Keycloak Einrichtung finden sie hier: [https://janikvonrotz.ch/2020/08/27/grafana-oauth-with-keycloak-and-how-to-validate-a-jwt-token/](https://janikvonrotz.ch/2020/08/27/grafana-oauth-with-keycloak-and-how-to-validate-a-jwt-token/)
```
cat <<EOF >> /etc/grafana/grafana.ini
[auth.generic_oauth]
enabled = true
name = Keycloak
allow_sign_up = true
client_id = grafana.secshell.net
client_secret = 10b50f2f-d7f8-45fd-9124-1e78ce837baf
scopes = openid, profile, roles
auth_url = https://id.secshell.net/auth/realms/main/protocol/openid-connect/auth
token_url = https://id.secshell.net/auth/realms/main/protocol/openid-connect/token
api_url = https://id.secsshell.net/auth/realms/main/protocol/openid-connect/userinfo
role_attribute_path = contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'
EOF

# hide grafana login
sed -i '/^;disable_login_form.* /{
  s/;//
  s/false/true/
}' /etc/grafana/grafana.ini
```
