# Azure Routing and User-Defined Routes (UDR)

> Azure automatically creates **system routes**, but administrators often need **user-defined routes (UDRs)** to control inspection, egress, and traffic flow across complex network topologies.

---

## Overview

**Azure Routing** is the mechanism that determines where a packet should go next. Every Azure subnet uses a routing table, whether you explicitly created one or not. Azure automatically provides **system routes** for common scenarios:

- Local VNet traffic (packets within the same VNet)
- Peered VNet traffic (packets to VNets with active peering)
- VPN Gateway or ExpressRoute traffic (packets to on-premises)
- Internet traffic

However, administrators often need to override these defaults using **User-Defined Routes (UDRs)** to:

- **Force traffic through a firewall or NVA** (Network Virtual Appliance) for inspection
- **Block/blackhole traffic** intentionally
- **Redirect workload traffic** based on policy
- **Support complex hybrid or multi-cloud designs** with custom appliances

### Why routing matters for AZ-104

Routing is the mechanism that makes hub-and-spoke architectures work, enables firewall-based inspection, and controls how traffic flows through your network topology. Many AZ-104 questions test understanding of:

- **Longest prefix match** (how Azure chooses among multiple routes)
- **Next hop types** (where packets should go)
- **Route table association** (which subnets use which routes)
- **Forced tunneling** patterns (corporate outbound control)
- **Effective routes** diagnostics (troubleshooting routing issues)

---

## What You Will Learn

- How Azure chooses routes
- System routes vs BGP routes vs UDRs
- Route table association and scope
- Common next hop types and use cases
- Forced tunneling, inspection, and troubleshooting

---

## Routing Mental Model

```text
[VM in subnet]
      |
      v
[Effective routes on NIC]
      |
      +--> 10.20.0.0/16 -> Virtual network
      +--> 10.0.0.0/16  -> VNet peering
      +--> 0.0.0.0/0    -> Virtual appliance
      |
      v
[Best route selected]
      |
      v
[Next hop: local / peering / gateway / NVA / internet / none]
```

---

## Route Selection Logic (Critical: Longest Prefix Match)

When a packet leaves a VM, Azure must decide which route to use. The **routing decision algorithm** is:

### Step 1: Find all matching routes

A route "matches" if the packet's destination IP falls within the route's destination prefix.

Example: A packet going to `8.8.8.0` (Google DNS on internet):

| Route prefix | Matches? |
|---|---|
| `10.20.0.0/16` (VNet) | No |
| `8.8.8.0/24` | YES |
| `0.0.0.0/0` (default internet) | YES |

Multiple routes can match the same packet!

### Step 2: Longest prefix match wins

If multiple routes match, Azure selects the most **specific** route (longest prefix = fewer wildcard bits).

**Example:** if both `8.8.8.0/24` and `0.0.0.0/0` match:

- `/24` prefix = 24 bits specific, 8 bits wildcard
- `/0` prefix = 0 bits specific, 32 bits wildcard

**Result:** `/24` is "longer" (more specific), so Azure uses the `/24` route.

### Step 3: If still tied, prioritize by source

If two routes have the **same prefix length**, Azure prioritizes:

1. **UDR (User-defined route)** — your custom routes
2. **BGP route** — learned from VPN Gateway or ExpressRoute
3. **System route** — Azure's defaults

This is an important exam distinction.

### Practical example

A subnet has these routes:

| Prefix | Type | Action |
|---|---|---|
| `0.0.0.0/0` | System | Internet (direct) |
| `10.0.0.0/8` | UDR | VirtualAppliance (firewall) |
| `10.20.0.0/16` | System | VirtualNetwork (local) |
| `10.20.1.5/32` | UDR | None (blackhole) |

**Packet going to `10.20.1.5`:**
- Matches `/32`, `/16`, `/8` → **use `/32`** (longest prefix)
- Action: None (blackhole) — packet is dropped

**Packet going to `10.50.0.1`:**
- Matches `/8`, `/0` → **use `/8`** (longer prefix)
- Action: VirtualAppliance → send to firewall

**Packet going to `8.8.8.8`:**
- Matches `/0` only
- Action: Internet → send directly to internet

### Common exam trap: "Which route takes precedence?"

**Question:** You have both a UDR and a BGP route to the same destination (same `/24` prefix). Which one Azure uses?

**Answer:** UDR wins, because UDR has higher priority than BGP.

But if instead you have:
- UDR to `0.0.0.0/0` (send to firewall)
- BGP to `8.0.0.0/8` (send to on-prem)

A packet to `8.8.8.8` matches both, but **`8.0.0.0/8` is longer** (/8 vs /0), so it takes precedence **regardless of type**.

---

## Next Hop Types Explained

Each UDR specifies where matching traffic should go: the **next hop**. Let's examine each type:

| Next Hop Type | Meaning | Use Case | Example |
|---|---|---|---|
| **VirtualNetwork** | Local VNet traffic; reaches by direct forwarding | Default; no UDR needed usually | Packet stays within VNet |
| **VirtualNetworkPeering** | Traffic to peered VNet | Connectivity set up by Azure automatically | Reaches peered spoke from hub |
| **VirtualNetworkGateway** | Traffic to/from on-premises or another region | Hybrid connectivity (VPN, ExpressRoute) | Sends to VPN Gateway for encryption to on-prem |
| **VirtualAppliance** | Forward to a custom appliance (firewall, NVA, load balancer) | Hub-and-spoke inspection; forced tunneling | Send to Azure Firewall on private IP `10.0.1.4` |
| **Internet** | Send directly to internet via Azure NAT | Default for outbound internet; rarely overridden | Replies use elastic public IP or standard outbound |
| **None** | Drop the packet (blackhole) | Block specific traffic by design | Drop all traffic to `192.168.0.0/16` intentionally |

### VirtualAppliance in detail (most complex and exam-heavy)

When you set a route to "VirtualAppliance", you specify the **private IP of an appliance** (typically a firewall or load balancer) that will forward or filter the traffic.

```text
[Spoke subnet]
  |
  v (packet to 0.0.0.0/0)
[Routing table: 0.0.0.0/0 → VirtualAppliance 10.0.1.4]
  |
  v
[Firewall NIC at 10.0.1.4 in hub subnet]
  |
  v
[Firewall inspects, filters, possibly NATspacket]
  |
  v
[Forwards to destination or drops]
```

**Critical requirements for VirtualAppliance to work:**
1. The appliance must have **IP forwarding enabled** (Azure setting)
2. The appliance must be **healthy and running**
3. The appliance must be **configured to forward traffic** (not just firewall it)
4. NSGs must allow traffic to/from the appliance
5. The appliance must handle return traffic back to source

### None (blackhole) in detail

A route with next hop type "None" intentionally drops traffic.

**Example:** You want to block specific networks regardless of NSG rules:

```
Route: 192.168.0.0/16 → None
```

Any packet destined for `192.168.0.0/16` will be **silently discarded** (not sent to NSG for filtering).

**When to use None:**
- Block known-bad networks
- Prevent accidental routing to non-existent on-prem networks
- Policy-based blocking (more permanent than NSG rules)

---

## Route Tables and Scope

A **route table** contains one or more UDRs and is associated with a **subnet**.

Important behavior:

- a subnet can have **one** route table associated with it
- the same route table can be reused across multiple subnets
- routes affect the workloads in that subnet through their effective routes

UDRs are not attached directly to the VM NIC; they are attached to the subnet.

---

## Common Routing Scenarios and Design Patterns

### Scenario 1: Forced Internet Egress Through Firewall

**Goal:** All internet-bound traffic from prod subnets passes through Azure Firewall for inspection, logging, and policy enforcement.

**Design:**

Hub VNet: `10.0.0.0/16`
- Azure Firewall: `10.0.1.4` (in AzureFirewallSubnet)

Spoke VNet: `10.10.0.0/16`
- App subnet: `10.10.1.0/24`

**Route table on spoke app-subnet:**

| Destination | Next Hop Type | Next Hop IP | Purpose |
|---|---|---|---|
| `0.0.0.0/0` | VirtualAppliance | `10.0.1.4` | Route all internet through firewall |
| `10.10.0.0/16` | VirtualNetwork | — | Local spoke VNet direct |

**Result:**
- Traffic to on-prem: `→ VPN Gateway` (system route)
- Traffic to internet: `→ Firewall →` inspect `→` allow/deny
- Local VNet traffic: Direct

**Why:** Organizations want centralized egress control (one place to audit internet access) rather than each VM making direct internet connections.

### Scenario 2: Asymmetric routing (intentional path difference)

Sometimes you deliberately want return traffic to take a different path than request traffic.

**Example:** Build network latency varies by region; you want:
- Request: `A → Firewall → B` (via hub forinstruction)
- Response: `B → direct to A` (for speed)

This requires different routing at A and B, and NSG rules understanding asymmetric paths can work.

### Scenario 3: Blackholing unwanted traffic

**Goal:** Block traffic to a known-bad network that should never be reached.

**Route table rule:**

| Destination | Next Hop Type | Purpose |
|---|---|---|
| `192.168.0.0/16` | None | Block any packets trying reach this range |

**Result:** VM tries to reach `192.168.1.100`, packet matches the route, is dropped by Azure immediately. No request even reaches the destination.

**When useful:** Block mistaken connections to incorrect ranges, prevent leakage to non-existent on-prem networks, etc.

### Scenario 4: Service chaining through multiple appliances

You want traffic from A → IDS (Intrusion Detection) → Firewall → B for deep inspection.

**Implementation:** Use multiple UDRs with progressively specific prefixes:

| Destination | Next Hop | Purpose |
|---|---|---|
| app-tier IPs | IDS appliance | First hop: intrusion detection |
| (if allowed by IDS) packet goes to next route | Firewall | Second hop: firewall policy |

Each appliance must be configured to forward to the next one.

### Scenario 5: Forced tunneling to on-premises

**Goal:** All traffic (including internet) routes through on-prem for compliance (all data must pass through corporate proxy/inspection).

**Route table:**

| Destination | Next Hop Type | Purpose |
|---|---|---|
| `0.0.0.0/0` | VirtualNetworkGateway | Send ALL traffic to on-prem via VPN |

**Result:**
- Internet traffic:  `Azure → VPN → on-prem proxy → internet`
- Latency: Higher (all traffic through VPN)
- Compliance: Yes, all data inspected by corporate controls

**Trade-off:** More latency for centralized control.

---

## Example Scenario

A company wants every production subnet to send internet-bound traffic through Azure Firewall in the hub VNet.

### Required route

- Destination prefix: `0.0.0.0/0`
- Next hop type: `VirtualAppliance`
- Next hop IP: private IP of the firewall

### Result

VMs in that subnet no longer take the default internet route directly.

This is a standard forced-tunneling pattern.

---

## BGP Propagation Note

If you use VPN Gateway or ExpressRoute, Azure can learn routes through **BGP**.

In some designs, you may want to disable **BGP propagation** on a route table so that only your intended UDRs apply to that subnet.

This is more advanced but important in enterprise routing design.

---

## CLI Reference

### Create a route table

```bash
az network route-table create \
  --resource-group <rg> \
  --name prod-rt \
  --location australiaeast
```

### Add a default route to an NVA or firewall

```bash
az network route-table route create \
  --resource-group <rg> \
  --route-table-name prod-rt \
  --name default-to-firewall \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address <firewall-private-ip>
```

### Associate the route table to a subnet

```bash
az network vnet subnet update \
  --resource-group <rg> \
  --vnet-name prod-vnet \
  --name app-subnet \
  --route-table prod-rt
```

### Inspect effective routes on a NIC

```bash
az network nic show-effective-route-table \
  --resource-group <rg> \
  --name <nic-name>
```

---

## Best Practices

1. Keep route tables **purpose-driven** and well documented.
2. Use `0.0.0.0/0` carefully — a bad default route can break a whole subnet.
3. Make sure the firewall or NVA is **highly available** before forcing production traffic through it.
4. Review **NSGs and UDRs together**; both influence connectivity.
5. Use **effective routes** to verify the real result rather than guessing.

---

## Routing Troubleshooting and Diagnostics

### Diagnostic flow for routing problems

If traffic doesn't follow the expected path:

1. **Confirm route table is attached to the subnet**
   - Use: `az network vnet subnet show --resource-group <rg> --vnet-name <vnet> --name <subnet>`
   - Look for `routeTable` field

2. **View all routes in the table**
   - Use: `az network route-table route list --resource-group <rg> --route-table-name <rt-name>`
   - Confirm all expected routes exist

3. **Check effective routes on the VM NIC**
   - This is the REAL picture of what Azure sees
   - Use: `az network nic show-effective-route-table --resource-group <rg> --name <nic-name>`
   - Includes system routes, UDRs, BGP routes combined

4. **Apply longest prefix match logic manually**
   - For the destination IP in question, which route has the longest prefix?
   - Is that the intended path?

5. **Verify the next hop is healthy**
   - If using VirtualAppliance, is the firewall/NVA running?
   - Is IP forwarding enabled on the appliance NIC?
   - Use: `az network nic show --resource-group <rg> --name <appliance-nic>`$
   - Check `enableIpForwarding` field

6. **Check NSGs on the path**
   - NSGs must allow traffic even if routing is correct
   - Verify at source, appliance, and destination

7. **Verify appliance configuration**
   - Is the appliance actually forwarding packets?
   - Is it dropping certain ports/protocols intentionally?
   - Check appliance logs (firewall rules, etc.)

8. **Test end-to-end**
   - Can you `tracert` (Windows) or `traceroute` (Linux) to see hops?
   - From source: `tracert 10.20.1.1` to see path
   - On appliance: can it see the traffic passing through?

### Common symptoms and root causes

| Symptom | Likely cause | First check |
|---------|-------------|-----------|
| Packet blackholes after route change | Next hop unavailable or route to nowhere | Verify next hop health and IP correctness |
| Unexpected route used (wrong path) | Longer prefix match or BGP route override | Check effective routes; apply prefix matching |
| On-prem traffic unreachable | VPN Gateway not in route or BGP disabled | Verify route to VirtualNetworkGateway exists; check BGP ads |
| Only some subnets affected | Route table not associated correctly | Confirm association; check which subnets have route tables |
| Intermittent routing failures | Appliance health intermittent or HA issues | Monitor appliance; check if high availability is configured |
| Return traffic takes different path | Asymmetric routing by design or accident | Confirm intentional; validate return path NSGs |

### Exam trap: "What happens if a UDR points to an invalid next hop?"

**Scenario:** You create a route:
- Destination: `0.0.0.0/0`
- Next hop type: VirtualAppliance
- Next hop IP: `10.50.1.4` (firewall doesn't exist here)

**Question:** What happens to traffic matching this route?

**Options:**
- A) Traffic is blocked with an error
- B) Traffic is automatically rerouted to the internet gateway
- C) Packet is silently dropped ✓ **Correct**
- D) Azure prevents the route creation

**Why C:** Azure does NOT validate that the next hop really exists when you create the route. Traffic is sent to the non-existent IP, then Azure silently drops it. This is why monitoring appliance health is critical.

### BGP Route Propagation Note

If you use VPN Gateway or ExpressRoute, you may want to:
- **Enable BGP propagation** — learn routes from on-prem dynamically
- **Disable BGP propagation** — use only static UDRs (more control)

**Exam question:** "How do you prevent on-prem routes from overriding your UDRs?"

**Answer:** Disable `Propagate gateway routes` on the route table, then manually add needed on-prem routes as static UDRs.

---

## Key Takeaways

- Azure already provides system routing, but UDRs let you take control.
- The two core concepts are **longest prefix match** and **next hop type**.
- UDRs are central to hub-and-spoke, firewall inspection, and forced tunneling designs.
- Always validate the result using **effective routes** on the source NIC.

---

## Advanced: Route Control Strategy

### Forced Tunneling and Inspection

UDRs are commonly used to direct traffic through network virtual appliances:

- Route default traffic to firewall/NVA next hop
- Preserve required service reachability with exceptions where needed
- Validate return path symmetry to avoid hidden packet drops

### Route Precedence and Predictability

Azure routing behavior depends on source and specificity:

- Longest-prefix match determines selected path
- UDRs can override system routes for targeted prefixes
- BGP routes can alter expected pathing in hybrid networks

### Operational Guardrails

- Treat route tables as controlled artifacts
- Test changes in non-production before rollout
- Document intended path for critical application flows

## Extended Troubleshooting Matrix (Routing and UDR)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Traffic blackholes after route change | Invalid next hop or missing appliance path | Inspect effective routes and next hop health | Correct next hop and ensure appliance availability |
| On-prem route not used | BGP propagation disabled or overridden | Review route table propagation setting | Enable propagation or adjust UDR specificity |
| Internet egress fails | Default route forced to unavailable NVA | Validate NVA forwarding and SNAT path | Restore NVA health or rollback route |
| Only some subnets affected | Route table not associated uniformly | Check subnet associations | Associate correct route table with all intended subnets |

## Production Readiness Checklist (Routing and UDR)

- Critical application routes documented and versioned
- Route table associations reviewed for all subnets
- NVA/firewall high availability validated
- BGP propagation behavior tested in hybrid design
- Rollback plan defined for routing changes
- Monitoring alerts configured for path and reachability failures


---

## Further Reading

- [Azure virtual network traffic routing](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
- [Diagnose a virtual machine routing problem](https://learn.microsoft.com/en-us/azure/network-watcher/diagnose-vm-network-routing-problem)
- [Azure Firewall hub-spoke reference architecture](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/firewalls/azure-firewall)
