# Azure DNS: Public and Private Name Resolution

## Overview

DNS is critical to Azure networking because most service access patterns rely on names rather than raw IP addresses. Azure provides:

- **Azure DNS Public Zones** for internet-resolvable domains
- **Azure DNS Private Zones** for internal/private name resolution across linked VNets

For AZ-104, you must understand how DNS affects private endpoints, hybrid connectivity, and troubleshooting.

---

## What You Will Learn

- Public vs private DNS zones and use cases
- VNet links for private DNS
- Auto-registration behavior in private zones
- DNS for private endpoints (`privatelink` zones)
- Hybrid DNS forwarding considerations
- Validation and troubleshooting methods

---

## Name Resolution Flow

```
 [Client VM/App]
         |
         v
 [DNS Resolver]
    (Azure-provided or custom)
         |
         +--> [Public DNS Zone] ---> [A/AAAA/CNAME records]
         |
         +--> [Private DNS Zone] ---> [privatelink.* or internal records]
```

---

## Core Concepts

- **Public zone**: Hosts records reachable from the internet.
- **Private zone**: Resolves names only within linked VNets.
- **Private DNS zone links**:
   - Link each VNet that needs resolution.
   - Optional auto-registration for VM hostnames (only in selected VNets).
- **Private endpoints**: Typically require `privatelink` private DNS zones for correct internal resolution.
- **Azure-provided DNS**: By default, Azure VMs can use the platform DNS resolver (`168.63.129.16`) unless a custom DNS server is configured on the VNet.
- **Custom DNS**: If using custom DNS servers, configure forwarding so private Azure zones resolve correctly.

---

## Design Guidance

1. Use public and private zones intentionally; avoid mixing responsibilities.
2. Standardize private zone naming and ownership.
3. Link all relevant VNets to private zones used by shared services.
4. For hybrid, define conditional forwarding between on-prem DNS and Azure DNS patterns.
5. Validate name resolution after any network or endpoint change.

---

## Troubleshooting Workflow

1. Confirm the queried name and expected zone type (public/private).
2. Verify private zone link exists for the client VNet.
3. Check record presence and record type.
4. Validate whether custom DNS forwarding is correctly configured.
5. Test with `nslookup` or `dig` from the actual client network context.

---

## Common Pitfalls and Exam Traps

- Creating a private zone but forgetting VNet links.
- Assuming private endpoint DNS works without zone integration.
- Using custom DNS without forwarding `privatelink` namespaces.
- Expecting public DNS records to resolve to private endpoint IPs automatically.

---

## Quick CLI Reference

```bash
# Create private DNS zone
az network private-dns zone create --resource-group <rg> --name <zone-name>

# Link VNet to private DNS zone
az network private-dns link vnet create \
   --resource-group <rg> \
   --zone-name <zone-name> \
   --name <link-name> \
   --virtual-network <vnet-id> \
   --registration-enabled false

# Add A record
az network private-dns record-set a add-record \
   --resource-group <rg> --zone-name <zone-name> --record-set-name <name> --ipv4-address <ip>
```

---

## Further Reading

- [What is Azure DNS?](https://learn.microsoft.com/en-us/azure/dns/dns-overview)
- [Azure Private DNS overview](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview)

