# Azure Virtual Network Peering: Private Connectivity Across VNets

## Overview

**VNet peering** connects two Azure virtual networks so resources can communicate privately over the Microsoft backbone network, without using public internet gateways.

Peering is a foundational AZ-104 topic because it affects architecture decisions for hub-and-spoke designs, shared services, and cross-region communication.

---

## What You Will Learn

- How VNet peering works
- Local vs global peering
- Peering configuration options and when to use them
- Routing and gateway transit behavior
- DNS considerations with peered VNets
- Validation and troubleshooting workflows

---

## Architecture Pattern

```
 [Spoke VNet A] <----> [Hub VNet] <----> [Spoke VNet B]
          |                    |                    |
          v                    v                    v
    [Workloads]        [Firewall/VPN/ER]     [Workloads]
```

Important: Connectivity between spokes is not automatic unless routing/forwarding is intentionally designed.

---

## Core Concepts

- **Private connectivity**: Traffic between peered VNets remains on Microsoft’s backbone.
- **No overlap allowed**: Peered VNets cannot have overlapping address spaces.
- **Non-transitive behavior**: If A is peered with B and B with C, A does not automatically reach C.
- **Bidirectional setup**: In practice, you configure peering from both VNets.
- **Local vs global peering**:
   - Local peering: VNets in the same Azure region.
   - Global peering: VNets in different regions.

---

## Peering Settings You Must Understand

- **Allow virtual network access**: Enables communication between peered VNets.
- **Allow forwarded traffic**: Required when traffic is forwarded through an NVA/firewall.
- **Allow gateway transit** (hub side): Lets this VNet share its VPN/ExpressRoute gateway.
- **Use remote gateways** (spoke side): Allows a VNet to use the peered VNet’s gateway.

Use gateway transit only when the topology requires centralized connectivity.

---

## DNS and Name Resolution Considerations

- Peering provides network connectivity, not automatic private DNS design.
- For private name resolution across VNets, use one of:
   - Private DNS zones linked to required VNets
   - Custom DNS servers with appropriate forwarding rules

---

## Validation Workflow (Operational)

1. Verify both peering connections are in **Connected** state.
2. Validate no CIDR overlap exists.
3. Test connectivity (for example, VM-to-VM over private IP).
4. Check effective routes on source NIC if traffic fails.
5. Validate NSG rules and any NVA/firewall forwarding behavior.

---

## Common Pitfalls and Exam Traps

- Creating peering only from one side and assuming full communication.
- Forgetting non-transitive behavior in hub-and-spoke designs.
- Enabling remote gateway settings incorrectly (or on both sides).
- Assuming peering solves DNS resolution without private DNS links or custom DNS forwarding.

---

## Quick CLI Reference

```bash
# Create peering from VNet A to VNet B
az network vnet peering create \
   --resource-group <rg-a> \
   --vnet-name <vnet-a> \
   --name <peer-a-to-b> \
   --remote-vnet <vnet-b-resource-id> \
   --allow-vnet-access

# List peerings on a VNet
az network vnet peering list --resource-group <rg> --vnet-name <vnet>

# Show a peering connection
az network vnet peering show --resource-group <rg> --vnet-name <vnet> --name <peering-name>
```

---

## Further Reading

- [Azure Virtual Network peering overview](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Tutorial: Connect virtual networks with peering](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-connect-virtual-networks-portal)

