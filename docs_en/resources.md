# Resources

The Proxmox VE hosts are identified using a unique id (`0-9`). They also get the FQDN `pveID.secshell.net` and the internal IPv4 range `10.ID.0.0/16` which can be used for vm networks.

Specifying the IP range prevents later problems, for example with the IPsec tunnels.

The first host gets the id `0` so the FQDN for this host is `pve0.secshell.net`, the internal IPv4 range is 10.0.0.0/16.

The remaining subnets, which were not intended for the hosts during planning, can be requested and freely used if the request is being approved.
The request only serves to check whether the desired subnet is already in use.

## Hosts
`pve0` is only for testing purpose, `pve1` and `pve2` are rental servers from Hetzner Online GmbH.

### pve1
The IPv4 network `10.1.0.0/16` has been split into two `/17` networks.

- The first network (`10.1.0.0/17`) will be further split (into /30 and /29 networks respectively), these will be used for connecting Virtual Machines and LXC Containers via VLANs.
- The second network (`10.1.128.0/17`) is further split into /29 networks and then used for OpenVPN client specfic overrides. 

### pve2
`pve2` is used by several partners so the resources have been divided:

!!! info ""
    The listed ID's are valid for Proxmox VM/LXC as well as VLAN ID's


| Use Case / Partner                |      ID     |         IPv4 network          |     IPv6 network          |
|:----------------------------------|:-----------:|:------------------------------|:--------------------------|
| General useage (e. g. VPN)        | 100  -  109 | 10.2.0.0/24                   |                           |
|                                   |             | 88.99.59.71                   | 2a01:4f8:10a:b88::/66     |
| A                                 | 110  -  139 | 10.2.1.0/24                   |                           |
|                                   |             | 176.9.198.65 und 176.9.198.66 | 2a01:4f8:10a:b88::4000/66 |
| B                                 | 140  -  169 | 10.2.2.0/24                   |                           |
|                                   |             | 176.9.198.67 und 176.9.198.68 | 2a01:4f8:10a:b88::8000/66 |
| C                                 | 170  -  199 | 10.2.3.0/24                   |                           |
|                                   |             | 176.9.198.69 und 176.9.198.70 | 2a01:4f8:10a:b88::c000/66 |

The IPv4 address of the OPNsense (`88.99.59.71`) is available to each partner via port forwarding.
For web protocols (`http`/`https`) the reverse proxy HAProxy is used.

The Freenom domains `secshell.cf`, `secshell.ml`, `secshell.tk`, `secshell.gq` and `secshell.ga` can be used for testing. Since no certificates can be requested via the ACME DNS-01 challenge, it is mandatory to use the TLS-01 challenge for this purpose.  
Apart from the subdomains `pve[0-9].secshell.net`, the domain `secshell.net` is mainly used internally.

