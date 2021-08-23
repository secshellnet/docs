#!/bin/sh

if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo "Please run the script as root!"
  exit 1
fi

nickname=$(cat /dev/urandom | tr -dcA-Za-z0-9 | fold -w 50 | head -n 1)
contact_info="Name <example@domain.tld>"

echo >/etc/motd
apk add --no-cache --update tor

# configuration
cat <<EOF >/etc/tor/torrc
ControlPort 9051
ORPort 9001
Nickname ${nickname}
RelayBandwidthRate 1 MB
RelayBandwidthBurst 1 MB
AccountingMax 10 GBytes
AccountingStart day 00:00
ContactInfo ${contact_info}
ExitPolicy reject *:*
BridgeRelay 0
DisableDebuggerAttachment 0
EOF

# handle autostart
rc-update add tor
rc-service tor start
