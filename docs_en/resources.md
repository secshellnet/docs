# Resources

The Proxmox VE hosts are identified using a unique id (`0-9`). They also get the FQDN `pveID.secshell.net` and the internal IPv4 range `10.ID.0.0/16` which can be used for vm networks.

The first host gets the id `0` so the FQDN for this host is `pve0.secshell.net`, the internal IPv4 range is 10.0.0.0/16.

The remaining subnets, which were not intended for the hosts during planning, can be requested and freely used if the request is being approved.
The request only serves to check whether the desired subnet is already in use.

The ranges `192.168.0.0/16` and `172.28.0.0/16` should not be used, to prevent problems with tunnels.

## Hosts
`pve0` is only for testing purpose, `pve1` and `pve2` are rental servers from Hetzner Online GmbH.

The IPv4 network `10.1.0.0/16` has been split into two `/17` networks.

- The first network (`10.1.0.0/17`) will be further split (into /30 and /29 networks respectively), these will be used for connecting Virtual Machines and LXC Containers via VLANs.
- The second network (`10.1.128.0/17`) is further split into /29 networks and then used for OpenVPN client specfic overrides. 

### pve2
`pve2` is used by several partners so the first network have been divided furthermore:

!!! info ""
    The listed ID's are valid for Proxmox VM/LXC, VLAN ID's and ipv6 addresses: <code>2a01:4f8:10a:b88:ID::/80</code>


| Use Case / Partner                |      ID     | IPv4 network                                 |
|:----------------------------------|:-----------:|:---------------------------------------------|
| Gateway                           |             | 10.2.0.0/30                                  |
| General usage                     | 201  -  209 | 10.2.0.4/30 - 10.2.0.252/30                  |
|                                   |             | 88.99.59.69/32 + 88.99.59.71/32              |
| A                                 | 210  -  239 | 10.2.1.0/24                                  |
| B                                 | 240  -  249 | 10.2.2.0/24                                  |
| C                                 | 250  -  259 | 10.2.3.0/24                                  |
| D                                 | 260  -  269 | 10.2.4.0/24                                  |
| E                                 | 270  -  279 | 10.2.5.0/24                                  |
| VPN                               |             | 10.2.248.0/22                                |

The IPv4 address of the Gateway (`88.99.59.71`) is available to each partner via port forwarding.
