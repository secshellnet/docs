# vSwitch
Die von Hetzner angebotenen vSwitches können zum Verbinden von mehreren Servern verwendet werden. Die Einrichtung eines vSwitches welcher nur für Dedicated Server gedacht ist kann der [Hetzner Dokumentation](https://docs.hetzner.com/de/robot/dedicated-server/network/vswitch/) entnommen werden. Im folgenden erläutern wir die Einrichtung eines vSwitch mit einem Hetzner Cloud Netzwerk. Wir verwenden ein 24er Netzwerk, außerhalb des Netzwerkes 10.0.0.0/8 um keine Konflikte mit den Internen Netzwerken zu erhalten.

The vSwitches offered by Hetzner can be used to connect multiple servers. The setup of a vSwitch which is only intended for dedicated servers can be found in the [Hetzner documentation](https://docs.hetzner.com/de/robot/dedicated-server/network/vswitch/). In the following we will explain the setup process of a vSwitch with a Hetzner Cloud network. We use a /24 network, outside the network 10.0.0.0/8 to avoid conflicts with the internal networks.

## Setup of the cloud network, vSwitches and cloud server
![Hetzner Cloud: networks](../img/setup/vswitch/vswitch_create1.png?raw=true){: loading=lazy }
![Hetzner Cloud: create network](../img/setup/vswitch/vswitch_create2.png?raw=true){: loading=lazy }
![Hetzner Robot: vSwitch menu](../img/setup/vswitch/vswitch_create3.png?raw=true){: loading=lazy }
![Hetzner Robot: create vSwitch](../img/setup/vswitch/vswitch_create4.png?raw=true){: loading=lazy }
![Hetzner Cloud: add subnet](../img/setup/vswitch/vswitch_create5.png?raw=true){: loading=lazy }
![Hetzner Cloud: configuration information](../img/setup/vswitch/vswitch_create6.png?raw=true){: loading=lazy }

The cloud server can finally be added in the /28 subnet for cloud servers, the configuration is done automatically:
![Hetzner Cloud: add cloudserver](../img/setup/vswitch/vswitch_create7.png?raw=true){: loading=lazy }
![Hetzner Cloud: subnet overview](../img/setup/vswitch/vswitch_create8.png?raw=true){: loading=lazy }
![Hetzner Cloud: network configuration of the cloudserver](../img/setup/vswitch/vswitch_cloudserver.png?raw=true){: loading=lazy }

If the Dedicated Server firewall has been enabled, a firewall rule must be created that allows packets into the created subnet. In this case, a firewall rule has been created that covers the entire Private /16 network, so no further customization is required for additional vSwitches in this network segment (192.160.0.0/16):
![Hetzner Robot: Firewall](../img/setup/vswitch/vswitch_firewall.png?raw=true){: loading=lazy }

## Setup of the Dedicated Server
First the network interface `vmbr0` must be made VLAN capable:
![VLAN Awareness for `vmbr0`](../img/setup/vswitch/vswitch_pve_vlan_aware.png?raw=true){: loading=lazy }

After the host has been restarted, the interface can be created in the OPNsense.
![create vlan](../img/setup/vswitch/vswitch_opnsense_interface1.png?raw=true){: loading=lazy }
![create interface](../img/setup/vswitch/vswitch_opnsense_interface2.png?raw=true){: loading=lazy }
![confgure the created interface](../img/setup/vswitch/vswitch_opnsense_interface3.png?raw=true){: loading=lazy }

After configuring the firewall for this interface, the gateway must be created. The gateway has the first usable address of the used network:
![Gateway: configuration](../img/setup/vswitch/vswitch_opnsense_gateway1.png?raw=true){: loading=lazy }
![Gateway: overview](../img/setup/vswitch/vswitch_opnsense_gateway2.png?raw=true){: loading=lazy }

Finally, the created /24 network has to be routed via the gateway of the /28 network of the vSwitch by creating a static route in the OPNsense:
![Route: configuration](../img/setup/vswitch/vswitch_opnsense_route.png?raw=true){: loading=lazy }
