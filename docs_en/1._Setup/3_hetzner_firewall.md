# Hetzner Firewall
Since the host should only be accessible from trusted addresses, the firewall is set up in Hetzner Robot:
![Firewall rules](../img/setup/firewall/firewall.png?raw=true){: loading=lazy }

Due to the set firewall rules only the ordered IP addresses can access the host. Additionally, packets of another IPv4 address were allowed, which is used to interact with the host in case of problems with the OPNsense.

Rules 6, 7 and 8 ensure that the host can receive responses from the Internet and send DNS/NTP queries. [This is described in the Hetzner Wiki.](https://docs.hetzner.com/robot/dedicated-server/firewall/#out-going-tcp-connections)

