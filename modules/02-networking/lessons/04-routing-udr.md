# Azure Routing and User-Defined Routes (UDR)

## Overview

Azure routes traffic using system routes by default. **User-defined routes (UDRs)** let you override default behavior by directing traffic to a specific next hop, such as a virtual appliance (firewall/NVA), virtual network gateway, or peering path.

UDRs are central to security and egress control in hub-and-spoke and inspection-based architectures.

---

## What You Will Learn

- Difference between system routes and UDRs
- Route table association and scope
- Route selection logic (longest prefix match)
- Common next hop types and use cases
- Forced tunneling and egress control
- Effective route troubleshooting

---

## Routing Flow

```
 [Subnet]
   |
   v
 [Route Table (UDR)]
   |
   +--> [Route A: 10.20.0.0/16 -> Virtual Appliance]
   +--> [Route B: 0.0.0.0/0 -> Firewall/NVA]
   +--> [Route C: 10.30.0.0/16 -> VNet Peering]
   |
   v
 [Selected route by longest prefix match]
   |
   v
 [Next hop]
```

---

## Core Concepts

- **System routes** are automatically created by Azure.
- **UDRs** are custom routes in a route table that you associate to one or more subnets.
- **One route table per subnet** (a route table can be reused across subnets).
- **Route selection** uses longest prefix match. If multiple routes have the same prefix length, Azure route precedence applies: User-defined route (UDR) > BGP route > system route.
- Typical next hops:
  - Virtual network
  - Virtual network peering
  - Virtual network gateway
  - Virtual appliance (NVA/firewall)
  - Internet
  - None (drop/blackhole)

---

## Design Guidance

1. Keep route tables purpose-specific and documented.
2. Use explicit routes for critical traffic paths.
3. Apply 0.0.0.0/0 with care (forced tunneling can break platform access if not planned).
4. Align NSG and routing design together; both influence effective connectivity.
5. Validate gateway/NVA high availability before steering production traffic.

---

## Troubleshooting Workflow

1. Confirm route table is associated to the intended subnet.
2. Check route prefixes for overlap/conflict.
3. Inspect **effective routes** on source NIC.
4. Validate NVA/firewall health and forwarding configuration.
5. Use Network Watcher tests for path verification.

---

## Common Pitfalls and Exam Traps

- Associating the route table to the wrong subnet.
- Misreading longest prefix match behavior.
- Adding 0.0.0.0/0 to an unavailable NVA and causing full outage.
- Assuming UDRs override all platform-internal behavior without constraints.

---

## Quick CLI Reference

```bash
# Create route table
az network route-table create --resource-group <rg> --name <rt-name>

# Add UDR
az network route-table route create \
  --resource-group <rg> \
  --route-table-name <rt-name> \
  --name <route-name> \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address <nva-private-ip>

# Associate route table to subnet
az network vnet subnet update \
  --resource-group <rg> --vnet-name <vnet> --name <subnet> \
  --route-table <rt-name>
```

---

## Further Reading

- [Azure virtual network traffic routing](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
- [Diagnose a virtual machine routing problem](https://learn.microsoft.com/en-us/azure/network-watcher/diagnose-vm-network-routing-problem)

