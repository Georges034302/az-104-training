# Azure Virtual Networks and Subnets

> **Azure Virtual Network (VNet)** is the core private networking service in Azure. It gives Azure resources private IP connectivity, isolation boundaries, routing control, and security integration.

---

## Overview

**Azure Virtual Network (VNet)** is the foundational networking service in Azure. It functions as your private network boundary within an Azure region. A VNet is where you:

- Define your overall network address space (IP prefix, e.g., `10.20.0.0/16`)
- Segment that space into **subnets** for workload isolation and policy application
- Deploy Azure resources such as virtual machines, databases, firewalls, and private endpoints

### Why VNets are central to Azure networking

Every Azure networking feature operates **within the context of a VNet**:

- **Network Security Groups (NSGs)** — Layer 3/4 traffic filtering at subnet or NIC level
- **User-Defined Routes (UDRs)** — custom routing tables that change traffic paths for a subnet
- **VNet Peering** — private IP connectivity between two VNets on the Microsoft backbone
- **VPN Gateway and ExpressRoute** — hybrid connectivity to on-premises networks
- **Private Endpoints** — bring Azure PaaS services (Storage, SQL, Key Vault) into private IP space
- **Service Endpoints** — restrict public Azure services to traffic from a specific subnet
- **Azure DNS** — name resolution inside and outside your network
- **Azure Firewall and NVAs** — centralized inspection points for traffic control

You cannot apply an NSG to a resource that is not in a VNet. You cannot peer two VNets if their address spaces overlap. **VNet design is the prerequisite for every other networking feature.**

### VNet scope: Regional boundaries

A VNet is **scoped to a single Azure region**. A VNet deployed in Australia East exists only in Australia East. If you need resources in Europe West to communicate privately with Australia East resources, you must use:

- **VNet Peering** (connects VNets on Microsoft backbone)
- **VPN Gateway** (encrypts traffic over internet)
- **ExpressRoute** (dedicated private connection)

You cannot expand a VNet across regions.

---

## What You Will Learn

- How VNets and subnets are structured in Azure
- How to plan IP address spaces with CIDR notation
- How subnetting supports isolation and security boundaries
- How VNets integrate with NSGs, route tables, DNS, and private access
- Common design patterns, examples, and exam pitfalls

---

## Mental Model

```text
[Region: Australia East]
        |
        v
[VNet: prod-vnet 10.20.0.0/16]
        |
        +--> [web-subnet 10.20.1.0/24] -> web VMs / web tier
        +--> [app-subnet 10.20.2.0/24] -> app services / API VMs
        +--> [data-subnet 10.20.3.0/24] -> database tier / managed services
        +--> [private-endpoints 10.20.10.0/24] -> private link NICs
        +--> [AzureBastionSubnet 10.20.250.0/26] -> Azure Bastion
```

A VNet is **regional**, but it can span **multiple availability zones** inside that region.

---

## Core Building Blocks

| Component | Purpose | Key Notes |
|---|---|---|
| **VNet** | Private network boundary | Scoped to one Azure region |
| **Address space** | Overall IP range for the VNet | Example: `10.20.0.0/16` |
| **Subnet** | Segment inside the VNet | Used for workload separation and policy application |
| **NIC** | Network interface on a VM | Gets a private IP from a subnet |
| **NSG** | Layer 3/4 traffic filtering | Can be attached to subnet or NIC |
| **Route table** | Custom routing logic | Associated to subnets |
| **DNS settings** | Name resolution behavior | Azure-provided or custom DNS servers |
| **Private endpoint** | Private IP access to PaaS | Usually placed in a dedicated subnet |

---

## Address Planning and CIDR

### RFC1918 Private Address Ranges

Azure VNets must use private IP address ranges defined in **RFC 1918** (a standard reserving certain IPv4 blocks for private use). Azure supports three standard private ranges:

- `10.0.0.0/8` — Largest range (~16 million addresses). Very common in enterprise deployments.
- `172.16.0.0/12` — Middle range (~1 million addresses). Often used to avoid conflicts with `10.0.0.0/8`.
- `192.168.0.0/16` — Smallest range (~65,000 addresses). Common in SMB deployments and home labs.

> **CIDR Notation Explained** — `10.0.0.0/8` means "the 10.0.0.0 network where the first 8 bits of the 32-bit IP address are the network portion". This leaves 24 bits for hosts, resulting in 2^24 = 16,777,216 total addresses. The `/` is the prefix length indicator. Larger prefix numbers mean smaller subnets (/32 is one host; /24 is 256 addresses; /16 is 65,536 addresses).

### The Critical Rule: No Overlapping Address Spaces

**You cannot have overlapping address spaces if networks need to communicate.**

Overlapping ranges break:

- **VNet Peering** — cannot peer VNets with overlapping CIDR blocks
- **VPN connectivity** — cannot route traffic to overlapping prefixes
- **ExpressRoute** — cannot advertise overlapping prefixes to on-premises
- **Hybrid DNS** — on-premises DNS forwarding breaks with overlaps

You must avoid overlapping ranges with:

- **Other Azure VNets** (current and future)
- **On-premises networks** (connected via VPN Gateway or ExpressRoute)
- **Azure Stack or edge deployments** in your hybrid environment
- **Third-party clouds** for future multi-cloud deployments
- **Lab/dev/DR environments** that may eventually integrate

### Real-world planning mistake

A company deploys production VNet with `10.0.0.0/16`. Later they try to set up a DR environment in a secondary region, also using `10.0.0.0/16` for "consistency". When they enable VNet peering for replication, it fails because of the overlap. Fixing it requires readdressing the entire DR VNet — a significant and disruptive change.

### Address Space Exhaustion Risk

Plan for **growth** from the start:

- Subnets cannot be shrunk after creation (only deleted and recreated)
- Adding new subnets requires contiguous space from the VNet address space
- Azure reserves 5 IP addresses per subnet
- Special service requirements (gateways, firewalls, bastion) need dedicated subnets

If you provision a VNet as `10.20.0.0/24` (only 256 total IPs), and you populate it with three `/26` subnets (three tiers), you have only 10 IPs left. When you need to add a private endpoint subnet or scale a tier, you cannot expand the existing subnets—you must either run out of space or redesign.

### CIDR Planning Table

| Prefix | Total IPs | Usable in Azure* | Common Use |
|---|---:|---:|---|
| `/24` | 256 | 251 | Standard workload subnet; typical VMs, containers, app tier |
| `/25` | 128 | 123 | Logical subdivision; allows two `/26` subnets |
| `/26` | 64 | 59 | Azure Bastion (minimum `/26` required), smaller tier |
| `/27` | 32 | 27 | Management, API gateway, utility services |
| `/28` | 16 | 11 | Small specialized subnet, point-to-point links |
| `/29` | 8 | 3 | Very small; rarely recommended for workload |
| `/30` | 4 | 1 | Point-to-point links or gateway connections only |

> **Azure IP Address Reservation Pattern**: Azure reserves exactly **5 addresses** in every subnet:
> - `.0` — network address (unavailable)
> - `.1` — gateway IP for Azure DNS, routing, DHCP (unavailable)
> - `.2` — reserved by Azure (unavailable)
> - `.3` — reserved by Azure (unavailable)
> - last (`.255` in a `/24`) — broadcast address (unavailable)
>
> This means a `/24` subnet (256 total) provides only **251 usable IPs** for your workloads.

### Real-World CIDR Planning Example

A company plans a three-tier production application architecture in Australia East:

**Poor plan:** VNet = `10.20.0.0/26`
- Total usable IPs: only 59
- Divided by 3 tiers: roughly 19-20 IPs per tier
- Problem: Cannot grow; fills up immediately; requires full redesign
- Cost of redesign: Redeploy all resources, new VNets, re-peer, reconfigure DNS

**Good plan:** VNet = `10.20.0.0/16` (65,535 usable IPs)
- web-tier: `10.20.1.0/24` (251 IPs)
- app-tier: `10.20.2.0/24` (251 IPs)
- database: `10.20.3.0/24` (251 IPs)
- private-endpoints: `10.20.10.0/24` (251 IPs) 
- gateway subnet: `10.20.250.0/27` (27 IPs for VPN/ExpressRoute)
- remaining: `10.20.4.0` through `10.20.249.0` for future growth
- Result: Each tier has room to scale; no redesign needed for years

### Azure Exam Trap: Counting IPs Correctly

Common AZ-104 question: **"You need to host 200 VMs in a subnet. What is the minimum prefix size?"**

- Option A: `/24` (256 total IPs)
- Option B: `/23` (512 total IPs)  
- Option C: `/22` (1,024 total IPs)

Correct answer: **B (`/23`)**. Here's why:
- `/24 = 256 total, but Azure reserves 5, so 251 usable. Since 251 > 200, seems correct!
- But wait: You also need IPs for the gateway, DNS servers, and DHCP server within the subnet
- Additionally, some admins leave 10-20% buffer for temporary services
- Safe answer: A `/23` with 512 total (507 usable) gives you approximately 470 IPs after reservations and buffer

This is a frequent exam trick—the answer that "barely works mathematically" is wrong; you need practical headroom.

---

## Subnet Design Patterns

### 1. Layer-based segmentation by workload tier and trust level

The most common design separates networks by functional role and security requirements:

- **Web Tier Subnet** — internet-facing workloads (VMs behind load balancer, container instances). Highest exposure; should have NSG rules restricting inbound to HTTP/HTTPS only.
- **App Tier Subnet** — business logic and internal APIs. Mid-trust zone; inbound from web tier, outbound to data tier and external services.
- **Data Tier Subnet** — databases and persistent storage. Most restrictive; inbound only from app tier on specific ports (SQL 1433, MySQL 3306, etc.), no direct internet access.
- **Management Subnet** — bastion hosts, jump boxes, admin tools. Restrictive inbound (SSH/RDP from limited IPs), used for operations and troubleshooting.
- **Private Endpoints Subnet** — dedicated for Azure private endpoints. Hosts the private NICs that give VNet-local access to Storage, SQL, Key Vault, etc.

By placing each tier in separate subnets, you can apply different **NSG rules**, **UDRs**, and **DNS settings** per tier. This is the foundation of **network segmentation**.

### 2. Special Azure managed subnets

Some Azure services require dedicated subnets with specific requirements:

| Subnet Name | Service | Key Requirement | CIDR Recommendation |
|---|---|---|---|
| `GatewaySubnet` | VPN Gateway / ExpressRoute Gateway | Must be named exactly; cannot use for other resources | `/27` minimum (27 IPs) for single gateway; `/26` for HA pair |
| `AzureBastionSubnet` | Azure Bastion | Must be named exactly; no NSGs with Deny rules on SSH/RDP; minimum `/26` | `/26` or `/25` (bastion traffic + all tunneled RDP/SSH) |
| `AzureFirewallSubnet` | Azure Firewall | Must be reserved for firewall NIC; no policies allowed | `/26` minimum (Azure Firewall requires at least 250 usable IPs) |
| `AzureFirewallManagementSubnet` | Azure Firewall management plane | Required only in specific forced-tunnel designs | `/26` minimum |

> **Exam Trap**: A question might ask "What is the minimum subnet size for Azure Bastion?" The correct answer is `/26` (64 addresses, 59 usable), not `/27`. If you answer `/27`, your deployment will fail with a validation error.

### 3. Subnet-level policy as the default approach

Most network security and routing policy should be applied at the **subnet level**, not per-VM:

- **Easier to manage** — one NSG for 20 VMs instead of 20 individual NICs
- **Consistent** — ensures uniform security baseline for all subnet members
- **Scalable** — VMSS and dynamic VM provisioning automatically inherit subnet policy
- **Troubleshooting** — clear which policy applies to which tier

Exceptions (NIC-level policy) should be rare and well-documented.

---

## Real-World Three-Tier Application Example

A company is migrating an existing on-premises three-tier application to Azure in Australia East.

### The application architecture
- **Web tier**: ASP.NET web servers behind a load balancer
- **App tier**: internal API servers
- **Data tier**: SQL Server database
- **On-premises integration**: connection to on-prem management tools and legacy databases

### Good VNet design

**VNet:** `10.20.0.0/16` (65,535 usable IPs, room for growth and future services)

**Subnets:**
- `web-subnet` (`10.20.1.0/24`): Hosts web VMs and load balancer. NSG allows TCP 80/443 from Internet, outbound to app-subnet on TCP 443.
- `app-subnet` (`10.20.2.0/24`): Internal API servers. NSG allows TCP 443 from web-subnet, outbound to data-subnet on TCP 1433.
- `data-subnet` (`10.20.3.0/24`): SQL Server VM. NSG restricts to TCP 1433 from app-subnet only. No outbound internet.
- `gateway-subnet` (`10.20.250.0/27`): VPN Gateway for on-prem connectivity. Reserved for gateway only.
- `private-endpoints` (`10.20.10.0/24`): Storage private endpoints for app configuration files, backups.

**Effective connectivity:**
- Internet → web-subnet (via load balancer public IP)
- web-subnet → app-subnet (private peering inside VNet)
- app-subnet → data-subnet (private)
- app-subnet → on-prem (via VPN Gateway)
- app-tier VMs → Storage private endpoint (private)

### Poor VNet design (what to avoid)

- Single `/26` VNet for everything (too small; cannot scale)
- All subnets in one `/27` (no isolation; NSG rules conflict)
- Overlapping address space with on-prem network (VPN would fail)
- No room for private endpoints (readdressing required later)
- No separate management tier (mixing ops access with app tiers)

## How VNets Integrate with Azure Networking Services

### NSGs (Network Security Groups)

NSGs apply **Layer 3/4 filtering rules** to subnets or individual NICs:

- **Subnet NSG** — traffic rule applied to all NICs in that subnet
- **NIC NSG** — rule applied to one specific adapter
- **Effective NSGs** — combination of both (traffic must pass both layers)

Example: A subnet has an NSG allowing port 443. An individual VM NIC also has an NSG. Both rules must allow traffic for it to pass.

### Route Tables & UDRs (User-Defined Routes)

A **route table** associates with a subnet and controls how outbound traffic is routed:

- **System routes** — default Azure routing for local VNets and internet
- **UDRs** — custom routes you create (e.g., send all traffic to a firewall)
- **BGP routes** — learned from VPN Gateway or ExpressRoute

Without a route table, a subnet uses all default system routes. You associate a route table to a subnet to override or extend those defaults.

Example: You create a UDR that sends `0.0.0.0/0` (all internet traffic) to an Azure Firewall in a hub subnet, then associate that route table to your app subnets.

### DNS (Azure DNS)

DNS controls name resolution inside and outside your networks:

- **Azure-provided DNS** (`168.63.129.16`) — default; answers queries for VNet and Azure PaaS services
- **Custom DNS servers** — point your VNet to on-prem or third-party DNS forwarders
- **Private DNS zones** — linked to your VNet for private Azure services and private endpoints

Example: If you use a private endpoint for Storage, you create a private DNS zone `privatelink.blob.core.windows.net` and link it to subnets so workloads resolve storage names to the private endpoint IP instead of the public one.

### Private Endpoints & Service Endpoints

These control access from your VNet to Azure PaaS services:

- **Private Endpoint** — creates a private NIC in your subnet with a private IP pointing to a PaaS service
- **Service Endpoint** — extends a subnet identity to the public PaaS endpoint (simpler but less secure)

Example: You create a private endpoint for Storage in your `private-endpoints` subnet, so the app tier can reach Storage using a private IP without any internet exposure.

### VNet Peering & Gateways

When your environment grows, you connect multiple VNets:

- **VNet Peering** — private connectivity between two VNets (no-overlap address spaces required)
- **VPN Gateway** — encrypted tunnel to on-premises (requires `GatewaySubnet`)
- **ExpressRoute Gateway** — dedicated connection to on-premises (requires `GatewaySubnet`)

Example: You have a hub VNet with shared services and firewalls, and spokes for each application. Peering connects all spokes to the hub.

---

## CLI Reference

### Create a VNet with an initial subnet

```bash
az network vnet create \
  --resource-group <rg> \
  --name prod-vnet \
  --location australiaeast \
  --address-prefixes 10.20.0.0/16 \
  --subnet-name web-subnet \
  --subnet-prefixes 10.20.1.0/24
```

### Add more subnets

```bash
az network vnet subnet create \
  --resource-group <rg> \
  --vnet-name prod-vnet \
  --name app-subnet \
  --address-prefixes 10.20.2.0/24

az network vnet subnet create \
  --resource-group <rg> \
  --vnet-name prod-vnet \
  --name private-endpoints \
  --address-prefixes 10.20.10.0/24
```

### Review configuration

```bash
az network vnet show --resource-group <rg> --name prod-vnet
az network vnet subnet list --resource-group <rg> --vnet-name prod-vnet -o table
```

---

## Best Practices

1. **Plan address space early** and leave room for expansion.
2. **Avoid overlap** with current and future connected networks.
3. **Subnet by function**, not randomly by team name.
4. **Keep private endpoints separate** from general-purpose workloads when possible.
5. **Document subnet purpose** and expected traffic flows.
6. **Use NSGs and route tables intentionally**; do not rely on a flat open network.

---

## Common VNet Pitfalls (Exam Traps and Operational Mistakes)

| Mistake | Why it fails | Impact | How to avoid |
|---------|-------------|--------|-------------|
| Thinking a VNet can span multiple regions | Azure regional scope boundary | Cannot connect resources across regions without peering/gateway | Understand region limitation; use peering for multi-region |
| Using overlapping subnets when peering is planned | Peering requires non-overlapping address spaces | Peering creation fails; blocks Azure connectivity | Pre-plan address space across all environments |
| Creating subnets too small | No room for scaling or service additions | Outgrows subnet quickly; requires readdressing | Start with `/24` minimum for workload subnets |
| Forgetting Azure reserves 5 IPs per subnet | Calculated IPs don't match usable IPs | Deployment failures due to insufficient IPs | Remember: -5 IPs per subnet (gateway, reservations, broadcast) |
| Placing gateway/bastion in wrong subnet size | Service requirements not met | Deployment fails with validation error | `GatewaySubnet` minimum `/27`; `AzureBastionSubnet` minimum `/26` |
| Assuming DNS works automatically for private endpoints | Private endpoint requires private DNS zone to work | Private service resolves to public IP; traffic bypasses private path | Configure private DNS zones and links explicitly |
| Not planning for private endpoints or future services | Address space exhausted | Cannot add private endpoint subnet; requires VNet redesign | Reserve 10-20% of address space for expansion |
| Applying all NSG rules at NIC level instead of subnet | Operational overhead and missed VMs | Complex VMSS/auto-scale scenarios break; inconsistent policy | Use subnet-level NSGs as default; NIC for exceptions |
| Creating too many subnets without naming convention | Operational confusion | "What does `10.20.54.0/24` do?" Hard to troubleshoot | Name subnets by function: `web-subnet`, `app-subnet`, `db-subnet`, etc. |

### Exam Trap: Which Azure service forces you to use a specific subnet name?

Options:
- A) Azure Storage
- B) Azure Load Balancer  
- C) Azure Bastion **✓ Correct**
- D) Application Gateway

**Why C is correct**: Azure Bastion deployment **requires** the subnet to be named exactly `AzureBastionSubnet`. Other services don't enforce specific subnet names.

---

## Troubleshooting VNet and Subnet Issues

If a VM or service cannot communicate as expected:

### Diagnostic flow

1. **Confirm network placement**
   - Verify the resource is deployed in the **expected VNet and subnet**
   - Use: `az network nic show --resource-group <rg> --name <nic-name>` to check subnet ID

2. **Validate subnet configuration**
   - Confirm the **subnet address range** matches the deployment design (`10.20.1.0/24`?)
   - Check whether the subnet has room for the resource (not exhausted)
   - Use: `az network vnet subnet show --resource-group <rg> --vnet-name <vnet> --name <subnet>`

3. **Check NSG rules** (Layer 3/4 filtering)
   - Review **inbound** rules — does traffic from source IP/port pass?
   - Review **outbound** rules — can the resource send traffic to destination?
   - Check effective NSGs on both subnet and NIC
   - Use: `az network nic list-effective-nsg --resource-group <rg> --name <nic-name>`

4. **Check route table** (traffic path)
   - Confirm routes on the source subnet
   - Does a UDR override the expected path? (e.g., sending all traffic to a firewall)?
   - Is the firewall or NVA healthy and configured for forwarding?
   - Use: `az network nic show-effective-route-table --resource-group <rg> --name <nic-name>`

5. **Validate DNS resolution**
   - Can the resource resolve the destination hostname?
   - Public IP or private IP? (Determines if DNS should return public or private endpoint IP)
   - Check Azure-provided DNS (`168.63.129.16`) or custom DNS forwarders
   - Use: `nslookup <hostname>` from within the VM

6. **Confirm peering/gateway configuration** (if cross-VNet)
   - Does peering exist and show "Connected" status?
   - Are address spaces non-overlapping?
   - Is gateway transit enabled (if applicable)?
   - Use: `az network vnet peering list --resource-group <rg> --vnet-name <vnet>`

7. **Verify private endpoint or service endpoint setup**
   - Does private DNS zone exist and link to the VNet?
   - Does service endpoint subnet have the correct service enabled?
   - Use: `az network private-endpoint show --resource-group <rg> --name <endpoint-name>`

### Symptoms → Likely causes

| Symptom | Check first |
|---------|-----------|
| "Connection timed out" from outside VNet | NSG blocking inbound; route table redirecting; firewall rules |
| VM cannot reach on-prem resource | VPN Gateway connected? BGP routes propagating? Address space overlap? |
| Private endpoint appears unreachable | Private DNS zone linked? Name resolves to private IP? NSG allows private IP range? |
| CANNOT reach website on public IP | Load balancer backend pool healthy? NSG allows 80/443 inbound? |
| Cannot add subnet to VNet | Address space too small? No contiguous block available? |



---

## Key Takeaways

- A **VNet** is Azure’s private network boundary within a region.
- **Subnets** create isolation, enable policy, and make traffic easier to control.
- Good **IP planning** prevents major future connectivity problems.
- Most Azure networking features build on top of VNet and subnet design.

---

## Advanced: VNet and Subnet Design at Scale

### Hub-Spoke and Shared Services

Large environments typically use a hub-spoke model:

- Hub VNet hosts shared services (firewall, DNS forwarders, VPN/ExpressRoute gateways)
- Spoke VNets host application workloads
- Centralized controls reduce duplicated security and simplify operations

### Address Space Governance

Define a formal enterprise IP plan before deployment:

- Reserve ranges for growth and future peering
- Avoid overlap across subscriptions and regions
- Allocate subnets by workload tier and expected scale

### Service Endpoints vs Private Endpoints

- Service endpoints keep traffic on Azure backbone but still target public service endpoints
- Private endpoints provide private IP-based access within the VNet
- Choose based on data exposure requirements and DNS strategy

## Extended Troubleshooting Matrix (VNets and Subnets)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| VM cannot reach peer resource | Missing route or NSG block | Check effective routes and effective security rules | Add required route or NSG allow rule |
| Deployment fails due to address conflict | Overlapping CIDR ranges | Compare VNet and on-prem ranges | Re-plan address space and redeploy |
| Service private access fails | DNS resolution points to public endpoint | Resolve FQDN from workload subnet | Configure private DNS zone/link |
| Subnet delegation error | Incompatible service configuration | Review subnet delegation and target service requirements | Correct delegation and retry deployment |

## Production Readiness Checklist (VNets and Subnets)

- Enterprise IP addressing standard documented and approved
- Non-overlapping CIDR blocks enforced across environments
- Subnet segmentation aligned to workload trust boundaries
- NSG and route controls validated per subnet
- Private access patterns and DNS behavior tested
- Network changes governed through change control


---

## Further Reading

- [What is Azure Virtual Network?](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Virtual network planning and design](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-vnet-plan-design-arm)
- [Create, change, or delete a subnet](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-subnet)
