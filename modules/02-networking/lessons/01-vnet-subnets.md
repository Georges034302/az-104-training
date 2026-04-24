# Azure Virtual Networks and Subnets

> **Azure Virtual Network (VNet)** is the core private networking service in Azure. It gives Azure resources private IP connectivity, isolation boundaries, routing control, and security integration.

---

## Overview

A VNet is the Azure equivalent of a private network in a datacenter. You define an address space, split it into **subnets**, and place resources such as VMs, Azure Bastion, VPN gateways, private endpoints, and firewalls into the appropriate network segments.

For AZ-104, this topic matters because most other networking features build on the VNet:

- **NSGs** filter traffic at subnet or NIC level
- **UDRs** change where traffic goes next
- **Peering** connects VNets together
- **Private endpoints** bring PaaS services into private IP space
- **DNS** controls how resources resolve names inside and outside the network

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

### Use RFC1918 Private Address Ranges

Azure VNets typically use these private ranges:

- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`

The most important rule is: **do not overlap address spaces** with:

- other Azure VNets you may peer later
- on-premises networks connected by VPN or ExpressRoute
- lab or DR environments that may need connectivity

### CIDR Example

| Prefix | Total IPs | Usable in Azure* | Typical Use |
|---|---:|---:|---|
| `/24` | 256 | 251 | medium subnet for VMs or app tier |
| `/26` | 64 | 59 | Azure Bastion or smaller app tier |
| `/27` | 32 | 27 | management or utility subnet |
| `/28` | 16 | 11 | very small dedicated subnet |

> *Azure reserves the **first four IP addresses** and the **last IP address** in every subnet.

### Example Plan

```text
VNet: 10.20.0.0/16
- web-subnet:            10.20.1.0/24
- app-subnet:            10.20.2.0/24
- data-subnet:           10.20.3.0/24
- private-endpoints:     10.20.10.0/24
- management-subnet:     10.20.20.0/27
```

This layout leaves large unused space for growth while keeping each workload isolated.

---

## Subnet Design Patterns

### 1. Separate by workload role

Use different subnets for different trust levels or traffic patterns:

- **Web tier**: internet-facing workloads
- **App tier**: internal APIs or business logic
- **Data tier**: databases or restricted services
- **Management**: jump hosts, Bastion, admin tools
- **Private endpoints**: private access to Storage, SQL, Key Vault, and other PaaS services

### 2. Keep room for managed services

Some Azure services require specific subnet behavior or names:

| Special subnet | Used for | Important note |
|---|---|---|
| `GatewaySubnet` | VPN Gateway / ExpressRoute Gateway | Reserved for the gateway service |
| `AzureBastionSubnet` | Azure Bastion | Must be named exactly `AzureBastionSubnet`; use `/26` or larger |
| `AzureFirewallSubnet` | Azure Firewall | Required reserved subnet name |
| `AzureFirewallManagementSubnet` | Azure Firewall management | Needed in specific forced-tunnel scenarios |

### 3. Use subnet-level policy as the default

Most network policy is applied at the **subnet**:

- NSGs for security filtering
- Route tables for custom routing
- Service endpoints or private endpoints for PaaS connectivity

This keeps policy easier to manage than configuring each VM individually.

---

## Example Scenario

A company is moving a three-tier application to Azure.

### Good design

- One VNet: `10.20.0.0/16`
- Three core subnets: `web`, `app`, `data`
- NSG on each subnet with least-privilege rules
- Private endpoint subnet for storage and Key Vault
- Optional hub VNet later for centralized firewall or VPN

### Poor design

- One flat subnet for everything
- Overlapping address space with on-prem network
- No room for future growth or private endpoints

The first design is easier to secure, troubleshoot, and extend.

---

## How VNets Interact with Other Azure Features

### NSGs
NSGs filter traffic to and from subnets or NICs.

### Route tables
UDRs let you send traffic to a firewall, NVA, or other next hop.

### DNS
You can use Azure-provided DNS or custom DNS servers. DNS design becomes especially important for hybrid networks and private endpoints.

### Private endpoints and service endpoints
These control secure access from a subnet to Azure PaaS services.

### Peering and gateways
When the environment grows, you often connect multiple VNets using peering or hybrid gateways.

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

## Common Pitfalls

- Thinking a VNet can span multiple regions — it cannot.
- Forgetting that overlapping address ranges block peering and hybrid connectivity.
- Creating subnets too small and then running out of IP addresses.
- Forgetting that Azure reserves 5 IPs in each subnet.
- Assuming DNS for private services works automatically without proper private DNS configuration.
- Placing everything in one subnet and then struggling with segmentation later.

---

## Troubleshooting Checklist

If a VM or service cannot communicate as expected:

1. Verify the resource is in the expected **subnet**.
2. Confirm the **VNet address space** and **subnet range** are correct.
3. Check whether an **NSG** blocks traffic.
4. Check whether a **route table** changes the path.
5. Validate **DNS resolution** if the issue is name-based rather than IP-based.
6. Review whether the design requires **peering**, a **VPN**, or a **private endpoint**.

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
