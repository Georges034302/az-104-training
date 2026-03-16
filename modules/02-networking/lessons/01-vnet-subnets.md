
# Azure Virtual Networks (VNets) and Subnets: Planning, Isolation, and Best Practices

## Overview

An **Azure Virtual Network (VNet)** is the fundamental building block for private networking in Azure. VNets enable Azure resources—such as VMs, containers, and PaaS services—to securely communicate with each other, with on-premises networks, and with the internet. Each VNet is an isolated, logical network boundary within Azure.

**Subnets** divide a VNet's address space into segments, allowing you to isolate workloads, apply security policies, and control routing.

---

## What You Will Learn

- The purpose and structure of VNets
- How to design and plan address spaces and subnets (CIDR)
- Subnet isolation and workload separation
- Best practices for subnet sizing and growth
- How subnets interact with NSGs, route tables, and private endpoints
- Common pitfalls and troubleshooting tips

---

## VNet and Subnet Architecture

```
 [Azure VNet: 10.10.0.0/16]
            |
            +--> [Subnet: App 10.10.1.0/24] ---> [App Servers]
            |
            +--> [Subnet: VM 10.10.2.0/24] ---> [Virtual Machines]
            |
            +--> [Subnet: Private Endpoints 10.10.3.0/24] ---> [Private Endpoints]
```

---

## Key Concepts

- **VNet**: A private, isolated network boundary in Azure. Each VNet has a defined IP address space (CIDR block), is scoped to a single Azure region, and contains one or more subnets. Multi-region designs use multiple VNets connected with services such as global VNet peering, VPN Gateway, or ExpressRoute.
- **Subnet**: A segment of a VNet's address space. Subnets allow you to group resources, apply security policies (NSGs), and control routing.
- **Address Planning**: Choose non-overlapping, RFC1918 address ranges (e.g., 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16). Plan for future growth—avoid small subnets that limit scaling.
- **Subnet Isolation**: Use separate subnets for different workloads (e.g., web, app, database, private endpoints) to enforce security boundaries and simplify management.
- **Integration**: Subnets are the scope for NSGs (firewall rules), route tables (custom routing), and private endpoints (secure PaaS access).

---

## Best Practices

1. **Plan for Growth**: Allocate larger address spaces than you need today. Changing subnet ranges later can be constrained and disruptive, especially after resources are deployed.
2. **Avoid Overlap**: Ensure VNet and subnet ranges do not overlap with on-premises networks or other VNets (critical for peering and VPNs).
3. **Subnet for Function**: Use dedicated subnets for private endpoints, DMZ, application tiers, and management resources.
4. **Document Your Design**: Keep a record of all address spaces and subnet purposes to avoid confusion and future conflicts.
5. **Security First**: Apply NSGs at the subnet level for broad policy, and at the NIC level only for exceptions.

---

## Common Pitfalls and Exam Traps

- Overlapping address spaces prevent peering and VPN connections.
- Placing private endpoints in the same subnet as workloads can complicate routing and security.
- VNets do not automatically configure DNS for private zones—you must link private DNS zones to VNets.
- Changing subnet ranges later can be constrained and disruptive when subnets already host resources.

---

## Quick Reference: Azure CLI

```bash
# List VNets in a subscription
az network vnet list -o table

# Show subnets in a VNet
az network vnet subnet list --resource-group <rg> --vnet-name <vnet>

# Create a VNet and subnets
az network vnet create --resource-group <rg> --name <vnet> --address-prefix 10.10.0.0/16 \
    --subnet-name app --subnet-prefix 10.10.1.0/24
az network vnet subnet create --resource-group <rg> --vnet-name <vnet> --name private-endpoints --address-prefix 10.10.3.0/24
```

---

## Further Reading

- [What is Azure Virtual Network? (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Virtual network planning and design](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-vnet-plan-design-arm)
