# Azure Virtual Network Peering

> **VNet peering** connects two Azure VNets so resources can communicate privately over the Microsoft backbone network without needing a VPN gateway for that connection.

---

## Overview

VNet peering is a core AZ-104 concept because it is used in:

- **hub-and-spoke** designs
- **shared services** networks
- **multi-region** connectivity patterns
- **separating workloads** while still allowing controlled communication

Peering gives you **private, low-latency connectivity**, but it does **not** merge VNets into one network and it does **not** make connectivity transitive.

---

## What You Will Learn

- How VNet peering works in Azure
- Local vs global peering
- Important peering settings and what they actually do
- Gateway transit and forwarded traffic behavior
- DNS, routing, and troubleshooting considerations
- Real usage examples and exam traps

---

## Peering Mental Model

```text
[Spoke VNet A 10.10.0.0/16] <----> [Hub VNet 10.0.0.0/16] <----> [Spoke VNet B 10.20.0.0/16]
            |                               |                              |
            v                               v                              v
      [App workloads]                [Firewall / VPN]                [Data workloads]
```

### Key point

Even though both spokes are peered to the hub, **Spoke A does not automatically reach Spoke B** unless routing and forwarding are deliberately designed.

---

## Core Rules You Must Remember

1. **Address spaces cannot overlap**.
2. Peering traffic uses the **Microsoft backbone**, not the public internet.
3. Peering is effectively configured from **both VNets**.
4. VNet peering is **non-transitive**.
5. **NSGs, UDRs, firewalls, and DNS** still matter after peering is in place.

---

## Local vs Global Peering

| Type | Scope | Common Use |
|---|---|---|
| **Local peering** | Between VNets in the same region | Hub-and-spoke inside one region |
| **Global peering** | Between VNets in different regions | Multi-region app, DR, shared services |

Both keep traffic private. Global peering is useful for cross-region architectures, but you should still validate latency, DNS design, and route intent.

---

## Peering Settings Explained

When creating peering, you will see several options.

| Setting | What it does | When to use it |
|---|---|---|
| **Allow virtual network access** | Permits traffic between the two VNets | Usually enabled for normal communication |
| **Allow forwarded traffic** | Accepts traffic forwarded by a firewall or NVA | Needed for service chaining or hub firewall designs |
| **Allow gateway transit** | Shares this VNet’s VPN/ExpressRoute gateway | Enable on the hub side |
| **Use remote gateways** | Uses the other VNet’s shared gateway | Enable on the spoke side |

### Gateway transit rule
A spoke can use a remote gateway from a hub, but it should not try to use multiple remote gateways. This is a common exam scenario.

---

## What Peering Does Not Do

Peering is powerful, but it does **not** automatically provide:

- DNS resolution across environments
- firewall inspection by default
- spoke-to-spoke transit
- internet egress centralization unless routing is configured
- identity or application authorization

It gives you **network reachability**, not the full connectivity design.

---

## Real-World Usage Patterns

### 1. Hub-and-spoke

The most common enterprise pattern:

- **Hub VNet** contains Azure Firewall, VPN Gateway, DNS forwarders, or shared services
- **Spoke VNets** contain apps or business workloads
- Traffic may be forced through the hub by UDRs

### 2. Multi-environment separation

Keep `dev`, `test`, and `prod` in separate VNets and peer only where needed.

### 3. Multi-region resilience

Peer VNets across regions for DR or replication traffic.

---

## Example Scenario

A company has:

- `hub-vnet` with Azure Firewall and VPN Gateway
- `spoke-app-vnet` for application servers
- `spoke-data-vnet` for data workloads

### Desired outcome

- Spokes reach on-premises through the hub gateway
- Internet egress goes through the hub firewall
- App and data VNets do not communicate unless explicitly routed

### Required thinking

- Bidirectional peering
- `Allow gateway transit` on the hub side
- `Use remote gateways` on the spoke side
- UDRs for forced traffic inspection if required

---

## DNS Considerations

Peering gives you IP-level connectivity, but **name resolution is separate**.

To resolve names across peered VNets, use one of these designs:

- **Azure Private DNS zones** linked to each relevant VNet
- **Custom DNS servers** with proper forwarding rules
- **Azure DNS Private Resolver** in hybrid or centralized DNS designs

If the network path works by private IP but not by hostname, DNS is usually the missing piece.

---

## Azure CLI Examples

### Create peering from VNet A to VNet B

```bash
az network vnet peering create \
  --resource-group <rg-a> \
  --vnet-name vnet-a \
  --name a-to-b \
  --remote-vnet <vnet-b-resource-id> \
  --allow-vnet-access
```

### Create return peering from VNet B to VNet A

```bash
az network vnet peering create \
  --resource-group <rg-b> \
  --vnet-name vnet-b \
  --name b-to-a \
  --remote-vnet <vnet-a-resource-id> \
  --allow-vnet-access
```

### Review peering state

```bash
az network vnet peering list \
  --resource-group <rg-a> \
  --vnet-name vnet-a \
  -o table
```

---

## Operational Notes

- Peering supports **cross-subscription** scenarios if permissions allow.
- Changes to VNet address space after peering may require a **peer sync** action.
- Peering traffic is typically **billed for ingress/egress**, so it is not a free connectivity layer.
- If a firewall or NVA is in the path, `Allow forwarded traffic` is often required.

---

## Troubleshooting Checklist

If peered VNets cannot communicate:

1. Confirm both peerings show **Connected**.
2. Verify there is **no address overlap**.
3. Check **NSG rules** on the source and destination subnets.
4. Review **effective routes** on the VM NIC.
5. Verify firewall/NVA forwarding behavior if the design uses inspection.
6. Test both **private IP** connectivity and **DNS name resolution**.

---

## Common Pitfalls and Exam Traps

- Assuming peering is transitive.
- Creating only one side and forgetting the return peering configuration.
- Misusing `Use remote gateways` and `Allow gateway transit`.
- Expecting DNS to work automatically after peering.
- Overlooking overlapping CIDR ranges.

---

## Key Takeaways

- VNet peering gives **private connectivity** between VNets.
- It is fast and common, but **not transitive**.
- Gateway sharing, forwarded traffic, and DNS design are where most mistakes happen.
- In enterprise Azure environments, peering is often the foundation for **hub-and-spoke networking**.

---

## Further Reading

- [Virtual network peering overview](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Create a peering between virtual networks](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-connect-virtual-networks-portal)
- [Hub-spoke network topology in Azure](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke)
