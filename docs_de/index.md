# Startseite

Die Secure Shell Networks Dokumentation beschreibt die Installation von Proxmox auf einem Dedicated Server bei Hetzner mit der Routing VM OPNsense.

## TODO
- Windows VM aufsetzen (IDE statt SCSI Harddrive, E1000 Network Interface, ...)
- Keycloak PostgreSQL einrichtung beschreiben (XML Migrations; Treiber laden)
- Keycloak Script `xmlstarlet` fixen
- Jitsi Script (während `apt-get install`)
  ```
  /etc/ca-certificates/update.d/jks-keystore: 82: java: not found
  E: /etc/ca-certificates/update.d/jks-keystore exited with code 1.
  ```
- ACME.sh cronjob prüfen
- OPNsense kein IPv6 für WAN/Default Interface
