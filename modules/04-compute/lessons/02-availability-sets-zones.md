# Availability in Azure: Sets, Zones, and Design Trade-offs

## Overview

Compute availability design in Azure is about reducing planned and unplanned downtime. AZ-104 emphasizes understanding the difference between availability sets and availability zones, and knowing when each model is appropriate.

---

## What You Will Learn

- Fault domains and update domains in availability sets
- Zone-based resilience and region support constraints
- Practical design choices for VM high availability
- Operational patterns and common assumptions to avoid

---

## Architecture View

```
 [Application Tier]
      |
      +--> [Availability Set]
      |         |
      |         +--> [Fault Domains]
      |         +--> [Update Domains]
      |
      +--> [Availability Zones]
                |
                +--> [Zone 1 Datacenter]
                +--> [Zone 2 Datacenter]
                +--> [Zone 3 Datacenter]
```

---

## Core Concepts

- **Availability Set**:
  - Logical grouping for VMs in one datacenter context.
  - Distributes VMs across fault and update domains to reduce correlated host/rack and maintenance impact.

- **Fault Domain (FD)**:
  - Represents a failure boundary such as shared power/network hardware segment.

- **Update Domain (UD)**:
  - Represents maintenance grouping for planned platform updates.

- **Availability Zone**:
  - Physically separate datacenter location within a region.
  - Zone deployment improves resilience for datacenter-level failures.

Important: Availability sets and availability zones are different resilience models; they are not interchangeable terms.

Constraint to remember: A VM cannot be simultaneously configured as both zonal and inside an availability set.

---

## Availability Sets vs Zones

Choose **availability sets** when:

- zonal deployment is not required or not available
- workload design is based on intra-datacenter domain separation
- legacy patterns or constraints favor set-based placement

Choose **availability zones** when:

- workload requires higher resilience to datacenter-level disruption
- region and selected VM SKU support zone deployment
- architecture can handle zone-aware networking and balancing patterns

Operational rule: If one instance failure is unacceptable, use at least two instances and a load balancing approach.

---

## Platform and Design Nuances

- Availability sets primarily address host and planned maintenance distribution in a datacenter context.
- Availability zones address datacenter-level failure domains within supported regions.
- Higher infrastructure resilience still requires application-aware design (for example retry logic, state strategy, and health-based traffic distribution).
- Validate that dependent resources (networking, load balancing, data tier) support your intended zonal resilience pattern.

---

## Design Dependencies Often Missed

- VM SKU and image must be available for chosen zone(s).
- Supporting resources may need zone-aware design depending on service behavior.
- Load balancing and health probe strategy must align with multi-instance deployment.

Resilience is an architecture property, not a checkbox on one VM.

---

## Operational Guidance

1. Validate regional zone support before final design.
2. Deploy at least two instances for any highly available VM workload.
3. Use health-probed traffic distribution so unhealthy instances are bypassed.
4. Test failure behavior, not only deployment success.
5. Document expected recovery behavior and operational runbooks.

---

## Common Pitfalls and Exam Traps

- Expecting availability set placement to protect from full datacenter/zone outage.
- Creating one VM and assuming availability SLA benefits of distributed design.
- Ignoring zone support constraints for chosen SKU/image.
- Forgetting that platform resiliency does not replace application-level resilience.
- Mixing terms in scenario questions and selecting availability sets when zonal failure tolerance is explicitly required.

---

## Quick CLI Reference

```bash
# Create availability set
az vm availability-set create \
  --resource-group <rg> \
  --name <aset-name>

# Create zonal VM (example zone 1)
az vm create \
  --resource-group <rg> \
  --name <vm-name> \
  --image Ubuntu2204 \
  --zone 1 \
  --admin-username <admin-user> \
  --generate-ssh-keys

# List zone support for VM sizes in region
az vm list-skus \
  --location <region> \
  --resource-type virtualMachines \
  --query "[?name=='<vm-size>'].locationInfo[].zones" \
  -o tsv
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/virtual-machines/availability
- https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview
