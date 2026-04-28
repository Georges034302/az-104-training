# Network Security Groups (NSGs) and Application Security Groups (ASGs)

> **NSGs** are Azure’s built-in Layer 3/4 traffic filters for subnets and NICs. **ASGs** make those rules easier to scale by letting you target application roles instead of hard-coded IP addresses.

---

## Overview

**Network Security Groups (NSGs)** are Azure's built-in **Layer 3/4 (network and transport layer) stateful firewall**. They are the primary traffic filtering tool in Azure networking. An NSG is a collection of security rules that decide whether traffic is allowed or denied based on:

- **Source** — where the packet came from (IP, service tag, or ASG)
- **Destination** — where it's going (IP, service tag, or ASG)
- **Port and protocol** — TCP/UDP port numbers, ICMP, or all protocols
- **Direction** — inbound (ingress) or outbound (egress)
- **Priority** — order of evaluation (100-4096; lower number = higher priority)

**Application Security Groups (ASGs)** work **with** NSGs to simplify rule management by grouping VM NICs into logical application roles (web, app, database) instead of using hard-coded IP addresses.

### Why NSGs matter for AZ-104

NSGs are the **first line of network defense** in Azure. Every Azure subscription should have NSG rules preventing unnecessary exposures. Common scenarios:

- Restrict internet-facing workloads to specific ports (HTTP 80, HTTPS 443)
- Block inter-tier communication that shouldn't happen (e.g., web tier directly to database)
- Prevent outbound internet access from critical workloads
- Enable only specific administrative ports like SSH (22) or RDP (3389)
- Create "bastion" workflows where admins cannot directly access production servers

Without NSGs, your VNet default behavior is **"allow all"** — every subnet can talk to every other subnet, and traffic can flow to/from the internet unless blocked by a firewall.

---

## What You Will Learn

- How NSG rules are evaluated
- Default rules and custom priority behavior
- Subnet-level vs NIC-level NSGs
- How ASGs simplify rule management
- Examples, best practices, and troubleshooting workflows

---

## Traffic Evaluation Flow

```text
[Inbound or outbound packet]
          |
          v
[Evaluate NSG rules by priority: 100 -> 4096]
          |
          +--> first matching Allow rule -> traffic permitted
          +--> first matching Deny rule  -> traffic blocked
          +--> no custom match           -> default rules apply
```

### Important rule
**Lower number = higher priority**. The first match wins.

---

## NSG Rule Components Explained

Each NSG rule consists of these properties:

| Property | Possible Values | Example | Notes |
|----------|---------|---------|-------|
| **Priority** | 100–4096 | 100 | Lower number = evaluated first; must be unique within Inbound/Outbound |
| **Direction** | Inbound, Outbound | Inbound | Inbound = traffic coming into the VM; Outbound = traffic leaving |
| **Source** | IP CIDR, Service Tag, ASG, `Any` | `10.20.1.0/24`, `Internet`, `web-asg` | Where traffic originates |
| **Destination** | IP CIDR, Service Tag, ASG, `Any` | `10.20.2.0/24`, `Storage`, `db-asg` | Where traffic is headed |
| **Protocol** | TCP, UDP, ICMP, `Any`, GRE | TCP | `Any` means all protocols |
| **Port** | Port number, range, or `*` | 443, 80-443, `*` | `*` means all ports; ranges like 3000-4000 also work |
| **Action** | Allow, Deny | Allow | First matching rule wins (by priority) |

### Rule evaluation example

A rule that says:
- Priority: 100
- Direction: Inbound
- Source: `10.0.0.0/8` (entire 10.x IP space)
- Destination: `Any`
- Protocol: TCP
- Port: 443
- Action: Allow

This means: "Allow all inbound TCP port 443 traffic from anywhere in the 10.x network" (e.g., from on-premises or another VNet via VPN/peering).

### Priority ordering (critical for exams)

**Lower priority number = higher precedence.** Rules are evaluated **top-to-bottom** in priority order:

| Priority | Rule | Effect |
|----------|------|--------|
| **100** | Allow TCP 443 from `10.0.0.0/8` | ← Evaluated first |
| 200 | Allow TCP 80 from `Internet` | |
| 300 | Deny TCP `*` from `Any` | |
| ... | ... | ... |
| **4096** | Last possible priority (default rules) | ← Evaluated last |

If a packet matches **priority 100** (Allow 443), it is allowed **immediately**, and rule 200, 300, etc. are NOT evaluated. The first match wins.

---

## Default NSG Rules (Critical for understanding NSG behavior)

Azure includes built-in rules in **every NSG** that are evaluated **after** all custom rules. These defaults have very high priority numbers (65000+), so they are evaluated last.

### Inbound defaults

| Priority | Rule | What it means | When it matters |
|---:|---|---|----|
| **65000** | `AllowVnetInBound` | Allow all traffic from the same VNet | Resources can communicate within VNet by default; you must explicitly deny if you want to block |
| **65001** | `AllowAzureLoadBalancerInBound` | Allow health probes from Azure Load Balancer | Health checks from load balancer always pass through |
| **65500** | `DenyAllInBound` | Deny everything else | If no custom rule matches, traffic is blocked |

### Outbound defaults  

| Priority | Rule | What it means | When it matters |
|---:|---|---|----|
| **65000** | `AllowVnetOutBound` | Allow all traffic to the same VNet | Internal communication unrestricted; no custom rule needed |
| **65001** | `AllowInternetOutBound` | Allow outbound to Internet | Resources can reach internet unless explicitly blocked |
| **65500** | `DenyAllOutBound` | Deny everything else | If no custom rule matches, traffic is blocked |

### What this means in practice

- **Default VNet behavior is "allow"** — without any custom NSG rules, all communication within the VNet is allowed
- **You must use custom rules to first deny, then selectively allow** — this is the "deny-by-default" security model
- **The `DenyAllInBound` at 65500 is the safety net** — if your custom rules don't explicitly allow traffic, it gets blocked by this default

### Exam example

**Scenario:** A subnet has NO custom NSG rules.

**Question:** Can VM A (`10.20.1.10`) in the same subnet reach VM B (`10.20.1.20`)?

**Answer:** YES, because of `AllowVnetInBound` (priority 65000). The traffic doesn't match any custom rules (there are none), but it matches the default VNet allow rule.

**Scenario:** Same subnet, but you want to block all inbound traffic except port 443.

**Solution:** Add a custom rule at priority 100:
- Action: Allow
- Direction: Inbound
- Port: 443

This blocks everything by default (falls through to `DenyAllInBound` at 65500) except port 443.

---

## Subnet NSG vs NIC NSG

| Scope | Use case | Guidance |
|---|---|---|
| **Subnet-level NSG** | Baseline policy for a whole workload segment | Preferred default approach |
| **NIC-level NSG** | Exception for one specific VM | Use sparingly |

If both exist, traffic must be allowed by the **effective result** of both scopes. A deny at either layer blocks the traffic.

---

## NSG Statefulness (Critical exam concept)

**NSGs are stateful**, meaning Azure tracks established connections and automatically allows return traffic.

### What "stateful" means

When you send a packet from VM A to VM B, NSG tracks this connection. The response from B→A is automatically allowed, even if you don't have an explicit inbound rule.

### Example

VM A (`10.20.1.10`) sends a request to VM B (`10.20.2.10`) on TCP 443:

**Request (A → B):**
1. NSG evaluates outbound rules on A's subnet
2. If rule allows TCP 443 outbound to B, packet goes
3. Connection state is tracked ("A-B, port 443 established")

**Response (B → A):**
1. NSG evaluates inbound rules on A's subnet
2. **Does NOT need an explicit allow rule** because connection is already established
3. Response is automatically allowed based on stateful tracking

### Why this matters for admins

You do NOT need to create return rules for established connections:

❌ **Wrong approach:**
```
Rule 100: Allow inbound TCP 443 from B to A
Rule 101: Allow outbound TCP 443 from A to B (for the response)
```

✅ **Correct approach:**
```
Rule 100: Allow outbound TCP 443 from A to B (only need one direction)
```

The return traffic is automatically allowed by statefulness.

### Exam trap: "Return traffic requires separate rules"

This is FALSE. Statefulness handles return traffic automatically. If a question asks "Do you need a return rule for established connections?", the answer is NO.

### Edge case: Long-lived idle connections

If a connection is idle for an extended period (varies by Azure), connection tracking may expire, and return traffic could be blocked. This is rare but important for understanding troubleshooting scenarios.

---

## Service Tags and Application Security Groups

### Service Tags (Azure-managed IP ranges)

Service tags are **pre-defined group labels** for Azure services that Azure maintains and updates automatically. You use these instead of managing large IP lists manually.

| Service Tag | Represents | Use case |
|---|---|---|
| `Internet` | All internet IPs (not in Azure) | Allow/deny traffic to/from public internet |
| `VirtualNetwork` | All IPs in the VNet and peered VNets | Allow all internal VNet communication |
| `AzureLoadBalancer` | Azure Load Balancer infrastructure | Allow health probes (usually port 80) |
| `Storage` | All Azure Storage service IPs across regions | Allow traffic to Storage accounts |
| `Sql` | All Azure SQL Database service IPs | Allow traffic to SQL Database endpoints |
| `AzureCloud` | All Azure datacenter IPs | Broader than Storage/Sql; includes everything |
| `ApiManagement` | Azure API Management service IPs | Allow traffic to API Management |
| `EventHub`, `ServiceBus` | Azure event/messaging services | Allow traffic to queuing services |
| `AzureCosmosDB` | Azure Cosmos DB service IPs | Allow traffic to Cosmos DB |

**Key advantage:** If Microsoft adds or changes IPs for a service, your NSG rules automatically stay current without manual updates.

### Example realistic rules using service tags

```
Rule 100: Allow inbound TCP 443 from Internet
  (allows HTTPS from anywhere)

Rule 110: Allow outbound to Storage service tag
  (allows traffic to any Storage account, any region)

Rule 200: Allow outbound to AzureCloud
  (allows traffic to all Azure services)

Rule 300: Deny outbound to Internet (except Azure services)
  (blocks direct internet access but allows Azure service access)
```

### Application Security Groups (ASGs)

ASGs let you group VM NICs by **application role** rather than by IP address. This is especially powerful for multi-tier applications that auto-scale.

| Component | Approach A: IP-based | Approach B: ASG-based |
|-----------|------|------|
| **Web tier** | NSG rules with IP ranges like `10.20.1.0/24` | NSG references `web-asg` |
| **When VM scales** | You must manually update IP ranges in NSG rules | VM NIC auto-joins `web-asg`; rules apply automatically |
| **Complexity** | Rules reference hard-coded IPs | Rules reference roles |
| **Maintainability** | High complexity at scale | Simple and declarative |

### Real example: Three-tier app with ASGs

**Setup:**

1. Create ASGs:
   - `web-asg` — all web tier VMs
   - `app-asg` — all app tier VMs
   - `db-asg` — all database tier VMs

2. Create NSG rule:
   - Priority 100
   - Direction: Inbound
   - Source: `web-asg`
   - Destination: `app-asg`
   - Port: TCP 443
   - Action: Allow

3. **Effect:** Any VM added to `web-asg` can automatically reach any VM in `app-asg` on port 443. No manual rule updates needed.

### When to use ASGs

✅ **Use ASGs when:**
- You have application tiers that auto-scale (VMSS, dynamic provisioning)
- You need role-based rather than IP-based rules
- You want consistent policies across environments

❌ **Don't use ASGs for:**
- Non-VM resources (Azure Storage endpoints, databases, etc.) — use service tags instead
- External IP ranges — use CIDR notation
- Complex conditional rules based on ports/protocols that vary per machine

> **Important limitation:** ASGs are specifically for grouping **VM NICs within Azure VNets**. They are not general-purpose resource grouping like resource tags or management groups.

---

## Comprehensive Three-Tier Application NSG Design

A company deploys a multi-tier web application in Azure:

```text
[Internet Users]
        |
        v (HTTP 80 / HTTPS 443)
[web-subnet + web-asg]
        |
        v (HTTPS 443)
[app-subnet + app-asg]
        |
        v (SQL 1433)
[data-subnet + db-asg]
        |
        v (encrypted backup)
[Storage account with private endpoint]
```

### NSG Rules for Web Tier

| Priority | Direction | Source | Dest | Protocol | Port | Action | Purpose |
|---|---|---|---|---|---|---|---|
| 100 | Inbound | `Internet` | `web-asg` | TCP | 80,443 | Allow | Public HTTP/HTTPS access |
| 110 | Inbound | `10.0.0.0/8` | `web-asg` | TCP | 22 | Allow | SSH for admins from on-prem via jump box |
| 200 | Outbound | `web-asg` | `app-asg` | TCP | 443 | Allow | Web to app communication |
| 210 | Outbound | `web-asg` | `Storage` | TCP | 443 | Allow | Web tier reads cached config from Storage |
| 220 | Outbound | `web-asg` | `Internet` | TCP | 443 | Allow | HTTPS to external CDN/APIs |
| 4096 | Outbound | `Any` | `Any` | Any | Any | Deny | Default deny (catches unintended outbound) |

### NSG Rules for App Tier

| Priority | Direction | Source | Dest | Protocol | Port | Action | Purpose |
|---|---|---|---|---|---|---|---|
| 100 | Inbound | `web-asg` | `app-asg` | TCP | 443 | Allow | Accept from web tier |
| 110 | Inbound | `10.0.0.0/8` | `app-asg` | TCP | 22 | Allow | SSH from on-prem admin jump box |
| 200 | Outbound | `app-asg` | `db-asg` | TCP | 1433 | Allow | SQL queries to database tier |
| 210 | Outbound | `app-asg` | `Storage` | TCP | 443 | Allow | Read/write to app data in Storage |
| 220 | Outbound | `app-asg` | `Internet` | TCP | 443 | Allow | HTTPS to external APIs, auth services |
| 4096 | Outbound | `Any` | `Any` | Any | Any | Deny | Default deny |

### NSG Rules for Data Tier

| Priority | Direction | Source | Dest | Protocol | Port | Action | Purpose |
|---|---|---|---|---|---|---|---|
| 100 | Inbound | `app-asg` | `db-asg` | TCP | 1433 | Allow | SQL queries from app tier |
| 110 | Inbound | `10.0.0.0/8` | `db-asg` | TCP | 1433 | Allow | DBA queries from on-prem |
| 120 | Inbound | `db-asg` | `db-asg` | TCP | 5022 | Allow | SQL Server replication/clustering |
| 200 | Outbound | `db-asg` | `Storage` | TCP | 443 | Allow | Backup to Storage account |
| 4096 | Outbound | `Any` | `Any` | Any | Any | Deny | Default deny (db doesn't need internet) |

### What these rules achieve

✅ **Network segmentation** — each tier only communicates where needed
✅ **Least privilege** — admin SSH restricted to from on-prem only
✅ **Data isolation** — database only reachable from app tier; cannot reach internet
✅ **Compliance-friendly** — clear audit trail of allowed flows
✅ **Operational safety** — default deny prevents accidental exposure

---

## CLI Reference

### Create an NSG

```bash
az network nsg create \
  --resource-group <rg> \
  --name web-nsg \
  --location australiaeast
```

### Add a rule to allow HTTPS inbound

```bash
az network nsg rule create \
  --resource-group <rg> \
  --nsg-name web-nsg \
  --name allow-https-in \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 443 \
  --source-address-prefixes Internet
```

### Create an ASG

```bash
az network asg create \
  --resource-group <rg> \
  --name web-asg \
  --location australiaeast
```

### Inspect effective rules

```bash
az network nic list-effective-nsg \
  --resource-group <rg> \
  --name <nic-name>
```

---

## Best Practices

1. Apply baseline rules at the **subnet level**.
2. Use **NIC NSGs only for exceptions**.
3. Prefer **ASGs and service tags** over raw IP address lists.
4. Keep management ports like `22` and `3389` tightly restricted.
5. Use clear rule naming such as `allow-web-to-app-443`.
6. Review priorities carefully to avoid accidental broad access.

---

## NSG Troubleshooting and Common Failures

### Diagnostic checklist

If traffic is blocked unexpectedly:

1. **Confirm NSG is attached**
   - Verify subnet has an NSG or NIC has an NSG
   - Both can have NSGs; traffic must pass BOTH
   - Use: `az network vnet subnet show` to check subnet NSG

2. **Check priority order**
   - **Lower number = higher priority** (common mistake)
   - Priority 100 is evaluated before 200
   - If priority 100 denies, priority 200 allow is never checked
   - Use: `az network nsg rule list --resource-group <rg> --nsg-name <nsg>` to see order

3. **Verify direction**
   - Ensure you're checking the RIGHT direction
   - Source → Dest is "Outbound" FROM source, "Inbound" FOR dest
   - Common mistake: checking "Inbound" when you need "Outbound"

4. **Confirm source/destination values**
   - IP ranges correct? (`10.20.1.0/24` not `10.20.1.0/25`?)
   - Service tag names correct? (It's `Storage` not `StorageAccount`)
   - ASG exists and NICs are members?
   - Use: `az network asg show --resource-group <rg> --name <asg-name>` to verify membership

5. **Check port and protocol**
   - Port specified correctly? (often forgets 0 in `443`, enters `44` instead)
   - Protocol correct? (TCP vs UDP confusion)
   - `*` means all ports? Confirmed needed?

6. **Review effective security rules**
   - This shows what's actually in effect after subnet + NIC NSGs merge
   - Use: `az network nic list-effective-nsg --resource-group <rg> --name <nic-name>`

7. **Remember: both subnet AND NIC NSGs must allow**
   - If subnet NSG allows port 443, but NIC NSG denies, traffic is blocked
   - Effective NSG = intersection (AND logic) of both

### Symptoms and typical causes

| Symptom | Likely Cause | Quick fix |
|---------|------------|----------|
| Inbound traffic blocked; appear to be allow rule | Priority ordering wrong; deny rule evaluated first | Verify priority; move allow to 100+ range |
| Traffic works one direction, fails reverse | Forgot about stateless reality; added return rule unnecessary | Remove unnecessary return rule; verify statefulness |
| "Effective NSG rules" shows allow but still blocked | NIC NSG denying (different NSG on NIC) | Check BOTH subnet and NIC NSG rules |
| ASG membership not taking effect | Device not added to ASG or NSG doesn't reference it | Add NIC to ASG; verify NSG rule references ASG |
| Service tag rule not working | Service endpoint not enabled on subnet OR typo in tag name | Enable service endpoint; verify spelling (e.g. `Storage` not `StorageAccount`) |
| All traffic appears blocked including from same VNet | Default rule removed accidentally | Default rules are read-only; might be custom rules; review priority 65000-65500 |

### Common exam traps for NSGs

| Trap | Mistake | Correct Info |
|------|---------|-------------|
| "Do I need return rules?" | YES, must create inbound AND outbound | NO, NSGs are stateful; only first direction needed |
| "What priority should rules use?" | Use 65000-65500 like defaults | Use 100-4096; defaults are not modifiable |
| "Can priority numbers be reused?" | YES, for simplicity | NO, each rule must have unique priority within Inbound/Outbound |
| "ASGs work for all resources?" | YES, all Azure services | NO, only for VM NICs; use service tags for PaaS |
| "Service tag `Internet` includes all public IPs?" | No, only IPs outside Azure | YES, it represents non-Azure IPs |
| "NSG can have 0 rules?" | YES, then default allow | NO, then default DENY (DenyAllInBound/DenyAllOutBound at 65500) |

---

## Key Takeaways

- NSGs are the primary Azure tool for **network traffic filtering**.
- They evaluate rules by **priority**, and the **first match wins**.
- ASGs make policies cleaner and easier to maintain at scale.
- A strong design uses **subnet segmentation + NSGs + least privilege**.

---

## Advanced: Policy Engineering for NSG and ASG

### Rule Design Principles

Use deterministic rule design:

- Deny-by-default with explicit allow rules
- Keep rule intent narrow by source, destination, and port
- Avoid broad Any-to-Any rules except emergency windows

### ASG Operational Model

ASGs reduce IP-based rule sprawl:

- Group workloads by role (web, app, data)
- Reference ASGs in NSG rules for role-based controls
- Keep naming aligned with application architecture

### Governance and Drift Control

- Version-control NSG rule sets
- Require change review for high-impact ports
- Periodically validate effective rules against design intent

## Extended Troubleshooting Matrix (NSG and ASG)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Traffic blocked unexpectedly | Higher-priority deny rule | Check NSG rule priority order | Reorder priorities or refine rule scope |
| App tier cannot reach DB tier | Missing ASG-to-ASG allow rule | Validate NIC ASG membership and target rule | Add correct rule and verify membership |
| Connectivity intermittent | Conflicting subnet and NIC NSGs | Review effective security rules on NIC | Harmonize subnet and NIC policies |
| RDP/SSH access unavailable | No inbound management path | Validate source IP and allowed ports | Add controlled management rule or Bastion path |

## Production Readiness Checklist (NSG and ASG)

- Standardized NSG baseline per subnet tier implemented
- ASG naming and membership conventions documented
- Rule priorities reviewed to prevent unintended shadowing
- Emergency access process defined and audited
- Effective rule validation included in release workflow
- Periodic cleanup for stale rules and unused ASGs


---

## Further Reading

- [Network security groups overview](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Application security groups](https://learn.microsoft.com/en-us/azure/virtual-network/application-security-groups)
- [Tutorial: Filter network traffic with an NSG](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-filter-network-traffic)
