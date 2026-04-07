# Azure Routing and User-Defined Routes (UDR)

> Azure automatically creates **system routes**, but administrators often need **user-defined routes (UDRs)** to control inspection, egress, and traffic flow across complex network topologies.

---

## Overview

Every Azure subnet uses a routing table, whether you created one or not. By default, Azure inserts system routes for:

- local VNet traffic
- internet-bound traffic
- peering-connected networks
- gateways and hybrid paths where applicable

A **UDR** lets you override or refine that behavior for a subnet.

This is essential in designs such as:

- hub-and-spoke with Azure Firewall
- forced tunneling to on-premises
- service chaining through a virtual appliance (NVA)
- blackholing traffic you explicitly want to drop

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

## Route Sources in Azure

| Route source | Created by | Typical use |
|---|---|---|
| **System route** | Azure | Default platform routing |
| **BGP route** | VPN Gateway / ExpressRoute | Hybrid learned prefixes |
| **User-defined route** | Administrator | Custom traffic steering |

### Route selection logic
Azure follows two important rules:

1. **Longest prefix match wins**
2. If prefix length is the same, precedence is generally:
   - **UDR**
   - **BGP**
   - **System route**

This is a classic exam topic.

---

## Common Next Hop Types

| Next hop type | Use case |
|---|---|
| **Virtual network** | Local traffic within the same VNet |
| **Virtual network peering** | Traffic to a peered VNet |
| **Virtual network gateway** | Traffic to on-premises or another connected network |
| **Virtual appliance** | Send traffic to a firewall or NVA |
| **Internet** | Public outbound path |
| **None** | Drop / blackhole the traffic |

---

## Route Tables and Scope

A **route table** contains one or more UDRs and is associated with a **subnet**.

Important behavior:

- a subnet can have **one** route table associated with it
- the same route table can be reused across multiple subnets
- routes affect the workloads in that subnet through their effective routes

UDRs are not attached directly to the VM NIC; they are attached to the subnet.

---

## Common Scenarios

### 1. Forced internet egress through a firewall

```text
[Spoke subnet] -- 0.0.0.0/0 --> [Azure Firewall in hub] --> [Internet]
```

A route sends all default outbound traffic to a firewall instead of directly to the internet.

### 2. Service chaining through an NVA

Traffic between spokes is sent through a hub NVA for inspection.

### 3. Blackholing a route

A route with next hop type `None` can intentionally drop traffic to a destination range.

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

## Azure CLI Examples

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

## Troubleshooting Checklist

If traffic does not follow the expected path:

1. Confirm the route table is attached to the correct **subnet**.
2. Check whether another route has a **more specific prefix**.
3. Review the VM NIC’s **effective routes**.
4. Verify the target firewall or NVA is healthy and forwarding traffic.
5. Check NSGs, peering settings, and gateway connectivity if the route looks correct but communication still fails.

---

## Common Pitfalls and Exam Traps

- Forgetting that **longest prefix match** wins.
- Associating the route table to the wrong subnet.
- Sending `0.0.0.0/0` to an unavailable NVA and causing an outage.
- Assuming a UDR changes authorization or DNS behavior — it changes **traffic path**, not access permissions.
- Ignoring effective routes and troubleshooting only from the portal design view.

---

## Key Takeaways

- Azure already provides system routing, but UDRs let you take control.
- The two core concepts are **longest prefix match** and **next hop type**.
- UDRs are central to hub-and-spoke, firewall inspection, and forced tunneling designs.
- Always validate the result using **effective routes** on the source NIC.

---

## Further Reading

- [Azure virtual network traffic routing](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
- [Diagnose a virtual machine routing problem](https://learn.microsoft.com/en-us/azure/network-watcher/diagnose-vm-network-routing-problem)
- [Azure Firewall hub-spoke reference architecture](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/firewalls/azure-firewall)
