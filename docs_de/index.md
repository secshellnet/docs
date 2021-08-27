# Startseite

Die Secure Shell Networks Dokumentation beschreibt die Installation von Proxmox auf einem Dedicated Server bei Hetzner mit der Routing VM OPNsense.

## TODO
- Windows VM aufsetzen (IDE statt SCSI Harddrive, E1000 Network Interface, ...)
- Keycloak PostgreSQL Datenbank
- DNS Update Script überall einrichten
- bei ACME.sh `ZONE_ID` und `ACCOUNT_ID` über CF_Token (und Cloudflare API Requests) holen, sodass nur CF_Token angegeben werden muss.
- ACME.sh cronjob prüfen
- OPNsense kein IPv6 für WAN/Default Interface
