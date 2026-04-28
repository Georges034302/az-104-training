# Azure Virtual Network Peering

> **VNet peering** connects two Azure VNets so resources can communicate privately over the Microsoft backbone network without needing a VPN gateway for that connection.

---

## Overview

**VNet peering** creates a private, low-latency connection between two Azure VNets without routing traffic over the public internet. It leverages the **Microsoft backbone network**, Azure's internal infrastructure that connects all data centers. Peering is a fundamental pattern in enterprise Azure deployments for building **hub-and-spoke networks**, connecting **isolated application workloads**, and creating **multi-region architectures**.

### Critical distinction: Peering is not transitive

This is the most important concept. If VNet A is peered to VNet B, and VNet B is peered to VNet C, that does **NOT automatically** mean A can reach C. Peering only connects the two specified VNets directly.

```text
[A] ←peer→ [B] ←peer→ [C]

A can reach B: YES (direct peering)
B can reach C: YES (direct peering)
A can reach C: NO (no direct peering) ← EXAM TRAP
```

If you need A to reach C, you must either:
- Create a direct peering between A and C, OR
- Route A-to-C traffic through B using UDRs and a firewall (hub-and-spoke inspection model)

### Why peering matters for AZ-104

Peering is used in:

- **Hub-and-spoke architectures** — central hub VNet with shared services (firewall, VPN gateway, DNS) connected to multiple spoke VNets
- **Multi-region disaster recovery** — peering VNets across regions for data replication with low-latency private paths
- **Shared services networks** — one VNet hosts common services (databases, caches) and multiple application VNets peer to it
- **Exam scenarios involving connectivity** — almost every test includes a peering question

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

1. **Peering requires non-overlapping address spaces** — cannot peer `10.0.0.0/16` with another `10.0.0.0/16`

2. **Peering traffic uses the Microsoft backbone** — private path between VNets, not internet

3. **Peering must be configured from both sides** — one-way peering is not "half-connected"; it's broken

4. **VNet peering is non-transitive** — 
   - A ↔ B and B ↔ C does NOT mean A ↔ C
   - Spoke-to-spoke traffic does NOT flow through hub automatically
   - Each connectivity pair requires explicit peering or routing

5. **NSGs, UDRs, firewalls, DNS still matter** — peering only solves connectivity; it doesn't solve filtering, routing, or naming

6. **Global peering (cross-region) has the same capabilities as local peering** — just different latency

### Deep dive: Non-transitivity (the #1 exam question)

This concept appears in almost every AZ-104 exam related to networking.

**Scenario:**
```
Hub (10.0.0.0/16)
  ↑
  ├→ Peered with Spoke-A (10.10.0.0/16)
  └→ Peered with Spoke-B (10.20.0.0/16)
```

**Question:** Can Spoke-A reach Spoke-B?

**Wrong answer:** "Yes, because they're both peered to the hub"
**Correct answer:** "No, unless there's explicit routing through the hub"

**Why:** Peering connects A-Hub and Hub-B. There's no peering between A-B unless explicitly created or there's a route that redirects A's traffic destined for B through the hub firewall.

**Fix:**
- Option 1: Create direct peering A ↔ B (if you want all traffic to go directly)
- Option 2: Create UDRs that route A → Hub (via firewall) → B (for inspection model)

---

## Local vs Global Peering

| Type | Scope | Common Use |
|---|---|---|
| **Local peering** | Between VNets in the same region | Hub-and-spoke inside one region |
| **Global peering** | Between VNets in different regions | Multi-region app, DR, shared services |

Both keep traffic private. Global peering is useful for cross-region architectures, but you should still validate latency, DNS design, and route intent.

---

## Peering Settings Explained

When creating peering, several checkbox options appear. Understanding each one is critical for the exam.

| Setting | What it does | When to enable | Hub value | Spoke value |
|---------|-------------|---------|-----------|------------|
| **Allow virtual network access** | Permits resources in the peered VNets to communicate with each other | Almost always | ✅ Yes | ✅ Yes |
| **Allow forwarded traffic** | Accepts traffic that was **forwarded by a router/firewall** in the other VNet | Needed when traffic passes through an NVA or firewall | ✅ Yes (if NVA exists) | ✅ Yes (if NVA exists) |
| **Allow gateway transit** | Permits the other VNet to use **this VNet's VPN/ExpressRoute gateway** | Hub side only (shares gateway with spokes) | ✅ Yes | ❌ No |
| **Use remote gateways** | Uses the **other VNet's gateway** for hybrid connectivity | Spoke side only (consumes hub gateway) | ❌ No | ✅ Yes (if hub has gateway) |

### Gateway Transit Pattern Explained  

This is the most complex peering feature. Here's the scenario:

**Hub VNet** has an **Azure VPN Gateway** (`10.0.250.0/27` GatewaySubnet)
**Spoke VNets** need on-premises connectivity

**Without gateway transit (wrong approach):**
- Each spoke must deploy its own VPN Gateway
- Cost: 3 spokes = 3 gateway deployments (expensive)
- Complexity: Each spoke maintains separate tunnel to on-prem

**With gateway transit (correct approach):**
- Hub has one VPN Gateway
- Spokes peer to hub with:
  - Hub peering: ✅ "Allow gateway transit" = YES
  - Spoke peering: ✅ "Use remote gateways" = YES  
- Result: Spokes use hub gateway for on-prem connectivity
- Cost: One gateway instead of three
- Complexity: Simplified

### Visual example

```text
[On-Premises]
     |
     | (encrypted tunnel)
     v
[Hub VNet] -- GatewaySubnet with VPN Gateway
     ^
     | peering (allow gateway transit)
     |
[Spoke A]  [Spoke B]  [Spoke C]
(use remote gateway) — they can all reach on-prem through hub
```

### Critical exam pattern: spoke-to-spoke through host doesn't happen automatically

❌ **Wrong assumption**: "Spoke A peers to Hub, Hub peers to Spoke B, so A can reach B on-prem"

❌ **Actually**: Spoke A can reach Hub, Hub can reach Spoke B, but A cannot reach B unless:
- A is also directly peered to B (non-transitive), OR
- Routes and inspection are explicitly configured

This is the most common exam trap involving peering and gateways.

### What peering does NOT provide

Even when all peering settings are correct, peering **does not automatically**:

- **Resolve DNS names across VNets** — requires private DNS zones or custom DNS forwarders
- **Inspect or filter traffic** — NSGs still apply at both ends; if you want centralized inspection, you need a hub firewall + UDRs
- **Merge security policies** — each VNet's NSGs and route tables are independent
- **Share identity/RBAC** — role-based access is evaluated separately in each subscription
- **Enable encryption** — peering uses Azure backbone (encrypted by default infra), but not end-to-end app encryption

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

## Real-World Hub-and-Spoke Peering Scenario

A company has:

- `hub-vnet` (`10.0.0.0/16`) containing:
  - Azure Firewall for centralized egress inspection
  - VPN Gateway for on-premises connectivity
  - DNS forwarders for hybrid DNS
  - Shared storage and ADLS for analytics
  
- `prod-app-spoke` (`10.10.0.0/16`) — production applications
- `dev-app-spoke` (`10.20.0.0/16`) — development workloads  
- `data-spoke` (`10.30.0.0/16`) — analytics and data workloads

### Desired outcomes

- Prod and dev apps reach each other through hub for inspection
- Internet egress from all spokes routes through hub firewall
- On-prem reach all spokes and shared hub services
- Data spoke reaches hub shared storage for analytics

### Required peering configuration

**Hub ↔ Prod-App Spoke**
- Hub: ✅ Allow virtual network access, ✅ Allow gateway transit
- Spoke: ✅ Allow virtual network access, ✅ Use remote gateways

**Hub ↔ Dev-App Spoke**
- Hub: ✅ Allow virtual network access, ✅ Allow gateway transit, ✅ Allow forwarded traffic
- Spoke: ✅ Allow virtual network access, ✅ Use remote gateways, ✅ Allow forwarded traffic

**Hub ↔ Data Spoke**
- Hub: ✅ Allow virtual network access, ✅ Allow forwarded traffic
- Spoke: ✅ Allow virtual network access, ✅ Allow forwarded traffic

> **Why "Allow forwarded traffic"?** Because traffic between spokes must pass through the hub firewall, and the firewall will forward traffic on behalf of other VNets.

### Route policy (UDRs needed for traffic inspection)

**Prod-app-spoke route table:**
- `0.0.0.0/0` → VirtualAppliance (firewall in hub) — force internet through firewall
- `10.20.0.0/16` → VirtualAppliance (firewall) — force dev traffic inspection
- `10.30.0.0/16` → VirtualAppliance (firewall) — force data traffic inspection

**Dev-app-spoke route table:**
- Similar rules for routing to hub firewall

Without these routes, spokes would still be able to reach each other through peering, but traffic wouldn't pass through the hub inspection point.

### DNS for hybrid connectivity

**Private DNS zones needed:**
- `corp.example.internal` — on-premises resources resolvable from Azure
- `azure.example.internal` — Azure resources resolvable from on-prem

**Custom DNS forwarders in hub:**
- Forward `corp.example.internal` queries to on-premises DNS
- Forward `azure.example.internal` queries from on-premises to Azure forwarder

Without this DNS design, even with working VPN and routes, users cannot access on-prem services by hostname.

---

## DNS Considerations

Peering gives you IP-level connectivity, but **name resolution is separate**.

To resolve names across peered VNets, use one of these designs:

- **Azure Private DNS zones** linked to each relevant VNet
- **Custom DNS servers** with proper forwarding rules
- **Azure DNS Private Resolver** in hybrid or centralized DNS designs

If the network path works by private IP but not by hostname, DNS is usually the missing piece.

---

## CLI Reference

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

## Peering Troubleshooting and Common Issues

### Diagnostic checklist

If peered VNets cannot communicate:

1. **Verify peering state**
   - Confirm **both directions** show "Connected" (peering is bidirectional)
   - If one shows "Disconnected", peering is broken
   - Use: `az network vnet peering list --resource-group <rg> --vnet-name <vnet>`

2. **Check address space overlap**
   - Peering fails if VNets have overlapping CIDR ranges
   - Example: Both `10.0.0.0/16` — peering will fail
   - Calculate actual ranges with CIDR tool to confirm no overlap

3. **Verify NSG rules at both ends**
   - Source subnet NSG must allow outbound to destination  
   - Destination subnet NSG must allow inbound from source
   - Also check NIC-level NSGs
   - Use: `az network nic list-effective-nsg` at source and destination
   - Remember: Traffic must pass **both** source and destination NSGs

4. **Check route tables**
   - Does source have a route reaching the destination VNet?
   - Does a UDR override the peering path (e.g., sending to NVA)?
   - Is the NVA healthy and configured for forwarding?
   - Use: `az network nic show-effective-route-table` to see actual routes

5. **Validate gateway transit setup (if applicable)**
   - Hub peering: ✅ "Allow gateway transit" must be YES
   - Spoke peering: ✅ "Use remote gateways" must be YES
   - Try a test connection through the gateway

6. **Test DNS separately from IP connectivity**
   - Can you `ping` by IP address? (tests network layer)
   - Can you `nslookup` the hostname? (tests DNS layer)
   - If IP works but hostname doesn't, the issue is DNS, not networking

### Common symptoms and causes

| Symptom | Likely causes | Diagnostic command |
|---------|--------|---|
| Peering shows "Connected" but no traffic flows | NSG blocking; UDR to wrong next hop | Check effective NSGs and routes on both ends |
| "Cannot create peering: address space conflict" | Overlapping CIDR ranges | Verify VNet address spaces don't overlap |
| On-prem unreachable from spoke despite peering | "Use remote gateways" not enabled on spoke | Check peering settings on spoke side |
| Intermittent connectivity on peered VNets | Firewall rules or transient probe failures | Review firewall logs; check peering health |
| Peering shows Disconnected after creation | Permission issue or regional problem | Recreate peering; check IAM permissions |

### Exam Traps: Common peering mistakes

| Scenario | Wrong answer | Right answer | Why |
|----------|------------|------------|-----|
| "How do spokes share connectivity without direct peering?" | They can, through transitive peering | They cannot; spokes need direct peering or hub routing | Peering is non-transitive |
| "Which setting shares a hub gateway with spokes?" | "Use remote gateways" on hub | "Allow gateway transit" on hub + "Use remote gateways" on spoke | Correct pairing is essential |
| "Can a spoke use two different hub gateways?" | Yes, for redundancy | No, only one remote gateway per spoke | Limitation of platform |
| "Does peering provide security filtering?" | Yes, automatically | No, NSGs and UDRs still required | Peering is only connectivity |
| "What happens if peering address spaces overlap?" | They are automatically merged | Peering cannot be created | Overlap must be resolved first |

---

## Key Takeaways

- VNet peering gives **private connectivity** between VNets.
- It is fast and common, but **not transitive**.
- Gateway sharing, forwarded traffic, and DNS design are where most mistakes happen.
- In enterprise Azure environments, peering is often the foundation for **hub-and-spoke networking**.

---

## Advanced: Peering Architecture and Governance

### Transitivity and Route Intent

VNet peering is non-transitive:

- A peered with B and B peered with C does not mean A can reach C
- Additional peerings or a routed hub design are required

### Gateway Transit Patterns

Use gateway transit intentionally:

- Hub provides VPN/ExpressRoute gateway
- Spokes consume transit to avoid per-spoke gateways
- Validate route propagation and failover paths

### Cross-Region Considerations

Global peering reduces latency compared to internet-based paths, but still requires:

- Thoughtful address planning
- NSG policy parity across regions
- Tested recovery patterns during regional incidents

## Extended Troubleshooting Matrix (VNet Peering)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Peered VNets cannot communicate | Peering state not connected or blocked by NSG | Inspect peering status and flow rules | Fix peering config and NSG rules |
| On-prem access unavailable from spoke | Missing gateway transit settings | Review allow gateway transit/use remote gateway flags | Correct peering settings and revalidate routes |
| Name resolution fails across VNets | DNS servers not reachable or no forwarding | Test DNS queries from each VNet | Configure DNS forwarding and conditional rules |
| Unexpected asymmetric path | Custom routes override expected peering path | Review effective routes on NICs | Adjust route tables for symmetry |

## Production Readiness Checklist (VNet Peering)

- Peering topology documented (hub-spoke, mesh, hybrid)
- Address spaces validated for non-overlap
- Required peering flags configured per scenario
- NSG and UDR policies verified end-to-end
- Cross-region and failover behavior tested
- DNS strategy documented for all peered VNets


---

## Further Reading

- [Virtual network peering overview](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Create a peering between virtual networks](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-connect-virtual-networks-portal)
- [Hub-spoke network topology in Azure](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke)
