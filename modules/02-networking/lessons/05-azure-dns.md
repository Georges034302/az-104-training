# Azure DNS: Public and Private Name Resolution

> Azure DNS is the name-resolution layer for public internet domains and private Azure networks. In real environments, good DNS design is what makes peering, private endpoints, and hybrid connectivity actually usable.

---

## Overview

Most applications connect by **name**, not by memorizing IP addresses. Azure DNS services help you publish and resolve those names in two main scopes:

- **Public DNS zones** for internet-facing domains
- **Private DNS zones** for internal name resolution inside Azure VNets

For AZ-104, DNS becomes especially important when you work with:

- private endpoints
- hybrid networks
- custom DNS servers
- multi-VNet architectures

---

## What You Will Learn

- The difference between public and private DNS zones
- How Azure-provided and custom DNS behave in VNets
- How VNet links and auto-registration work
- Why private endpoints depend heavily on DNS
- Common admin scenarios, examples, and troubleshooting steps

---

## DNS Mental Model

```text
[Client VM / App]
        |
        v
[DNS Resolver]
  |             \
  |              +--> [Public Azure DNS zone] -> public records
  |
  +--> [Private DNS zone linked to VNet] -> internal records / privatelink records
```

If the wrong DNS path is used, a network that looks healthy can still fail from the user’s point of view.

---

## Public vs Private DNS Zones

| Zone type | Resolves where | Typical use |
|---|---|---|
| **Public DNS zone** | Internet clients | `contoso.com`, `www.contoso.com` |
| **Private DNS zone** | Linked VNets only | `internal.contoso.local`, `privatelink.blob.core.windows.net` |

### Public zones
Use a public zone when users or systems on the internet need to resolve the name.

### Private zones
Use a private zone when the record should resolve **only inside linked Azure VNets**.

---

## Azure-Provided DNS vs Custom DNS

### Azure-provided DNS
By default, VMs in a VNet can use Azure’s built-in resolver:

- IP: `168.63.129.16`
- easy for default deployments
- works well for many Azure-native scenarios

### Custom DNS
Use custom DNS servers when you need:

- on-prem Active Directory integrated DNS
- custom forwarding rules
- centralized enterprise name resolution
- hybrid environments with complex zone ownership

If you switch VNet DNS settings, clients may need to renew DHCP or restart to pick up the new resolver settings.

---

## Private DNS Zone Links

A private zone does nothing until it is linked to one or more VNets.

### Types of link behavior

| Feature | What it does |
|---|---|
| **Resolution link** | Allows the VNet to resolve records in the zone |
| **Auto-registration** | Automatically creates DNS records for Azure VMs in that linked VNet |

### Important note
Auto-registration is useful for VM hostname registration, but it is not a replacement for full enterprise DNS design.

---

## DNS for Private Endpoints

This is one of the most important practical Azure networking topics.

When you create a **private endpoint**, the service should usually resolve to a **private IP** instead of its normal public endpoint.

Example for Azure Storage:

- public name pattern: `mystorage.blob.core.windows.net`
- private DNS zone often used: `privatelink.blob.core.windows.net`

If DNS is not configured correctly, the client may still resolve the service to the **public IP**, which breaks the expected private-access design.

---

## Hybrid DNS Considerations

In hybrid environments, you often need Azure and on-premises DNS systems to forward queries to each other.

Common patterns:

- on-premises DNS forwards Azure private zones to Azure
- Azure workloads forward corporate internal zones to on-premises DNS
- **Azure DNS Private Resolver** is used to simplify managed inbound/outbound DNS forwarding

This is the modern Azure-friendly approach for large environments.

---

## Example Scenarios

### 1. Public website

- Public DNS zone: `contoso.com`
- Record: `www.contoso.com` -> public IP of App Gateway or Front Door

### 2. Internal application

- Private DNS zone: `corp.contoso.internal`
- Record: `app01.corp.contoso.internal` -> private IP of internal load balancer or VM

### 3. Private endpoint for Storage

- Private endpoint created in a subnet
- Private DNS zone linked to the VNet
- Storage name resolves privately for Azure VMs

---

## CLI Reference

### Create a private DNS zone

```bash
az network private-dns zone create \
  --resource-group <rg> \
  --name privatelink.blob.core.windows.net
```

### Link a VNet to the private zone

```bash
az network private-dns link vnet create \
  --resource-group <rg> \
  --zone-name privatelink.blob.core.windows.net \
  --name storage-zone-link \
  --virtual-network <vnet-id> \
  --registration-enabled false
```

### Add an A record manually

```bash
az network private-dns record-set a add-record \
  --resource-group <rg> \
  --zone-name privatelink.blob.core.windows.net \
  --record-set-name mystorage \
  --ipv4-address 10.20.10.4
```

### Validate name resolution from a VM

```bash
nslookup mystorage.blob.core.windows.net
```

---

## Best Practices

1. Keep **public** and **private** DNS responsibilities clearly separated.
2. Link every relevant VNet to the private zone that serves shared private services.
3. Standardize private DNS naming and ownership.
4. Use **Azure DNS Private Resolver** or well-planned forwarding in hybrid environments.
5. Always test from the **actual client network context**, not just from your laptop.

---

## Troubleshooting Checklist

If name resolution fails:

1. Verify whether the name should resolve in a **public** or **private** zone.
2. Confirm the record exists in the expected zone.
3. Confirm the **VNet link** exists for private zones.
4. Check whether the client uses **Azure-provided** or **custom DNS**.
5. Validate forwarding rules if the environment is hybrid.
6. Test with `nslookup` or `dig` from the Azure VM itself.

---

## Common Pitfalls

- Creating a private zone but forgetting to link the VNet.
- Assuming private endpoint DNS is automatic without the correct `privatelink` zone setup.
- Using custom DNS but not forwarding private Azure namespaces.
- Expecting a public zone to return private endpoint IPs.
- Troubleshooting connectivity only at the network layer when the issue is actually DNS.

---

## Key Takeaways

- DNS is a critical part of Azure networking, not an optional add-on.
- Use **public zones** for internet records and **private zones** for internal/private Azure resolution.
- Private endpoints depend on correct DNS integration.
- In hybrid environments, good **forwarding design** is essential.

---

## Advanced: DNS Architecture for Hybrid and Private Access

### Namespace Strategy

Design DNS zones with long-term operability in mind:

- Public zones for internet-facing records
- Private DNS zones for internal service discovery
- Clear naming standards to avoid collisions and ambiguity

### Private Endpoint Resolution Pattern

For private endpoints:

- Workloads must resolve service FQDN to private IP
- Private DNS zone links must exist for participating VNets
- Hybrid resolvers need forwarding rules for private zones

### Reliability and Change Safety

- Use low TTLs during migrations and cutovers
- Avoid frequent record churn without change tracking
- Validate both forward and reverse lookups where required

## Extended Troubleshooting Matrix (Azure DNS)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Name resolves to wrong IP | Stale cache or incorrect zone record | Query authoritative source and client resolver | Correct record and flush caches |
| Private endpoint uses public IP | Missing private zone link or record | Resolve FQDN from workload subnet | Link private zone and validate records |
| Hybrid clients cannot resolve private names | DNS forwarding not configured | Trace query path from on-prem resolver | Add conditional forwarder rules |
| Intermittent resolution behavior | Multiple resolvers with inconsistent data | Compare responses across resolvers | Align zone data and forwarding paths |

## Production Readiness Checklist (Azure DNS)

- DNS zone ownership and naming standards defined
- Private zone links validated for all required VNets
- Hybrid forwarding architecture documented and tested
- TTL strategy aligned to change and failover requirements
- Monitoring in place for resolver and query failures
- DNS changes tracked through change management


---

## Further Reading

- [Azure DNS overview](https://learn.microsoft.com/en-us/azure/dns/dns-overview)
- [Azure Private DNS overview](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview)
- [Azure DNS Private Resolver overview](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview)
