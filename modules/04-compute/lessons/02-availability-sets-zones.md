# Availability in Azure: Availability Sets, Availability Zones, and Resilience Design

> Azure availability design is about reducing downtime from **host failures, planned maintenance, and datacenter-level outages**. For AZ-104, the core comparison is **availability sets** versus **availability zones**.

---

## Overview

High availability is not a single setting on one VM. It is a design choice involving:

- how many instances you run
- where those instances are placed
- how traffic is balanced
- whether the app and data layer can tolerate failure

Azure gives administrators two major VM-focused placement options:

- **Availability Sets**
- **Availability Zones**

---

## What You Will Learn

- Fault domains and update domains in availability sets
- How availability zones improve resilience
- When to use sets versus zones
- How load balancers and multiple instances fit the design
- Common operational mistakes and exam traps

---

## Availability Mental Model

```text
[Application tier]
      |
      +--> [Availability Set]
      |         +--> [Fault Domains]
      |         +--> [Update Domains]
      |
      +--> [Availability Zones]
                +--> [Zone 1]
                +--> [Zone 2]
                +--> [Zone 3]
```

---

## Core Concepts

### Availability Set
An availability set is a logical grouping that spreads VMs across:

- **fault domains (FDs)**
- **update domains (UDs)**

This helps reduce the chance that both VMs are impacted by the same rack, power, or planned maintenance event.

### Fault Domain (FD)
A fault domain represents a shared failure boundary such as common power or network hardware.

### Update Domain (UD)
An update domain represents a group of resources that might be rebooted together during planned Azure platform maintenance.

### Availability Zone
An availability zone is a **physically separate datacenter location** within the same Azure region.

This gives stronger protection against a datacenter-level issue than an availability set.

> A VM cannot be both **zonal** and part of an **availability set** at the same time.

---

## Availability Sets vs Availability Zones

| Feature | Availability Set | Availability Zone |
|---|---|---|
| Placement scope | Distribution inside a datacenter environment | Distribution across separate datacenter locations in one region |
| Protects against host/rack issues | Yes | Yes |
| Protects against full datacenter failure | Limited | Better |
| Requires zone-supported region/SKU | No | Yes |
| Typical use | Traditional multi-VM HA design | Modern production resilience pattern |

---

## Important Design Rule

If the business cannot tolerate one VM failing, **do not deploy only one VM**.

A proper high-availability design usually requires:

- at least **two instances**
- a **load balancer** or similar traffic distribution layer
- health probes so failed instances stop receiving traffic

Availability is a property of the **architecture**, not of a single checkbox.

---

## When to Choose Each Model

### Choose **Availability Sets** when:

- the target region or required VM SKU does not support zonal deployment
- the workload uses a traditional multi-VM pattern in one region
- you need a non-zonal HA design for compatibility or legacy reasons

### Choose **Availability Zones** when:

- the business must tolerate a datacenter-level outage
- the region and SKU support zones
- you want stronger resilience for modern production workloads

### Common real-world pattern
For many modern web or API workloads, the preferred pattern is:

- multiple VMs
- spread across **zones**
- fronted by a **Standard Load Balancer** or other resilient traffic layer

---

## Availability Design Examples

### 1. Two-VM internal application in a non-zonal requirement

Use an **availability set** if zonal deployment is not required or not supported.

### 2. Internet-facing production app

Use VMs spread across **availability zones**, fronted by a load balancer and health probes.

### 3. Single VM running a business-critical workload

This is **not** a high-availability design, even if backup exists. Backup helps recovery, not continuous availability.

---

## Dependencies Often Missed

Before selecting a resilience model, verify:

- the **region** supports availability zones
- the required **VM SKU** is available in those zones
- load balancing aligns with the design
- storage and application state do not create a single point of failure

Even if compute is redundant, the workload can still fail if:

- the database is single-instance only
- DNS or networking is not resilient
- the app cannot handle multiple active instances

---

## SLA Thinking

Availability features improve resilience, but they only help when paired with the right deployment pattern.

Examples of stronger patterns:

- multiple VMs + load balancer
- zonal placement for front-end instances
- resilient storage and data replication strategy

A single VM, even on premium storage, is still a single compute failure point.

---

## CLI Reference

### Create an availability set

```bash
az vm availability-set create \
  --resource-group <rg> \
  --name app-aset
```

### Create a zonal VM in zone 1

```bash
az vm create \
  --resource-group <rg> \
  --name app-vm-01 \
  --image Ubuntu2204 \
  --zone 1 \
  --admin-username azureadmin \
  --generate-ssh-keys
```

### Check zone support for a VM size

```bash
az vm list-skus \
  --location australiaeast \
  --resource-type virtualMachines \
  --query "[?name=='Standard_D2s_v5'].locationInfo[].zones" \
  -o tsv
```

---

## Best Practices

1. Deploy at least **two instances** for workloads requiring uptime.
2. Prefer **availability zones** when the business needs stronger resilience and the region supports them.
3. Combine distributed placement with **load balancing** and **health probes**.
4. Validate storage, app state, and network dependencies — not just the VM placement.
5. Test failover behavior before a real outage occurs.

---

## Troubleshooting Checklist

If a supposedly resilient workload is still fragile:

1. Confirm whether there is **one VM or multiple VMs**.
2. Verify whether the VMs are actually in an availability set or across zones.
3. Check load balancer health probe status and backend membership.
4. Confirm the VM size is supported in the chosen zone.
5. Identify other single points of failure in storage, DNS, or application state.

---

## Common Pitfalls

- Thinking an availability set protects against a complete datacenter outage.
- Deploying only one VM and assuming high availability benefits still apply.
- Confusing availability sets with availability zones.
- Ignoring zone support constraints for the selected SKU or region.
- Forgetting that compute redundancy does not replace app-level resilience.

---

## Key Takeaways

- **Availability Sets** use **fault domains** and **update domains** to reduce local failure impact.
- **Availability Zones** spread workloads across separate datacenter locations within a region.
- Zones usually provide stronger resilience, but they require regional and SKU support.
- High availability needs **multiple instances, traffic distribution, and operational validation**.

---

## Advanced: Availability Architecture Decisions

### Fault Domain Awareness

- Availability sets protect against host/rack-level failures within a datacenter
- Availability zones protect against datacenter-level failures in a region
- Design must align to actual fault isolation required by workload

### Quorum and State Considerations

- Stateful workloads need replication and quorum-aware topology
- Stateless tiers can scale across zones more easily
- Ensure dependency services share compatible availability design

### SLA to Implementation Traceability

- SLA targets must map to concrete architecture choices
- Validate that zone/region dependencies are redundant
- Include operational practices such as patch sequencing and failover drills

## Extended Troubleshooting Matrix (Availability Sets and Zones)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| No resilience gain after deployment | Instances not distributed as intended | Inspect placement and topology | Redeploy/resize with correct availability configuration |
| Maintenance causes full outage | Single fault domain pattern | Review VM placement and update domain spread | Re-architect into set/zone distribution |
| App unavailable during zone event | Dependencies not zone-redundant | Map dependency availability by zone | Add redundant dependencies across zones |
| SLA expectations not met | Architecture does not match SLA assumptions | Compare design to provider SLA conditions | Adjust architecture and operational controls |

## Production Readiness Checklist (Availability Design)

- Availability objective documented per application tier
- Placement strategy validated (set vs zone vs region)
- Dependency resilience reviewed and remediated
- Failover and recovery drills performed regularly
- Maintenance and patch windows coordinated safely
- SLA assumptions documented with architecture evidence


---

## Further Reading

- [Manage the availability of Windows and Linux virtual machines in Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/availability)
- [Availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)
- [Azure reliability overview](https://learn.microsoft.com/en-us/azure/reliability/overview)
