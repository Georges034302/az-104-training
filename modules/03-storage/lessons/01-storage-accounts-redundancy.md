# Azure Storage Accounts and Redundancy

> A **storage account** is the top-level administrative boundary for Azure Storage. The account type, performance model, and redundancy choice directly affect cost, durability, availability, and disaster recovery behavior.

---

## Overview

Azure Storage is used for several data services:

- **Blob** for object storage
- **Files** for managed SMB/NFS file shares
- **Queue** for simple message storage
- **Table** for NoSQL key/attribute data

In AZ-104, administrators must be able to choose the right storage account design based on:

- workload type
- redundancy requirements
- zone or region failure tolerance
- performance expectations
- security and network requirements

---

## What You Will Learn

- What a storage account is and what services it can host
- The difference between standard and premium performance models
- When to use `StorageV2` and other account types
- How LRS, ZRS, GRS, and GZRS differ
- Practical selection guidance, CLI usage, and exam traps

---

## Storage Account Mental Model

```text
[Storage Account]
      |
      +--> [Blob service]
      +--> [File service]
      +--> [Queue service]
      +--> [Table service]
      |
      +--> [Performance: Standard / Premium]
      +--> [Redundancy: LRS / ZRS / GRS / RA-GRS / GZRS / RA-GZRS]
      +--> [Security: RBAC / SAS / Firewall / Private Endpoint]
```

---

## Core Concepts

### Storage account basics

- A storage account is the **management boundary** for Azure Storage services.
- The name must be **globally unique**, use only **lowercase letters and numbers**, and be **3-24 characters** long.
- For most AZ-104 scenarios, **general-purpose v2 (`StorageV2`)** is the default and recommended choice.

### Common service endpoints

A single storage account can expose service endpoints such as:

- `https://<account>.blob.core.windows.net`
- `https://<account>.file.core.windows.net`
- `https://<account>.queue.core.windows.net`
- `https://<account>.table.core.windows.net`

Applications connect to these endpoints, so DNS, firewall rules, private endpoints, and failover behavior all matter.

---

## Account Types and Performance

| Option | Typical use | Notes |
|---|---|---|
| **StorageV2** | Default general-purpose account | Best starting point for most workloads |
| **Premium Block Blob** | Performance-sensitive blob workloads | SSD-backed specialized blob scenarios |
| **FileStorage** | Premium Azure Files | Used for high-performance file shares |

### Performance models

| Tier | Backing | Best for |
|---|---|---|
| **Standard** | HDD-based | General-purpose storage, most labs and business workloads |
| **Premium** | SSD-based | Low-latency, high-throughput scenarios |

> Choose the account based on **capability requirements first**, then optimize for cost.

---

## Redundancy Options Explained

Azure redundancy determines how many copies of data are maintained and where those copies live.

| Redundancy | Zone resilient? | Secondary region? | Read secondary? | Typical use |
|---|---|---|---|---|
| **LRS** | No | No | No | Lowest-cost local resilience |
| **ZRS** | Yes | No | No | Production workloads needing zone resilience |
| **GRS** | No | Yes | No | Regional DR with asynchronous replication |
| **RA-GRS** | No | Yes | Yes | GRS plus readable secondary endpoint |
| **GZRS** | Yes | Yes | No | Combined zone + regional resilience |
| **RA-GZRS** | Yes | Yes | Yes | Highest resilience with readable secondary |

### Key meaning of each option

- **LRS**: Keeps multiple copies in one datacenter in one region.
- **ZRS**: Spreads copies across multiple availability zones in one region.
- **GRS**: Replicates to a paired region asynchronously for disaster recovery.
- **RA-GRS**: Same as GRS, but the secondary endpoint can be read.
- **GZRS / RA-GZRS**: Add zone resilience in the primary region plus geo-replication.

> **Geo-replication is asynchronous**, so a regional disaster can still result in some recent-data loss depending on timing.

## Deep Dive: Explain Each Redundancy Type

This section gives the practical, administrator-level behavior for each redundancy option.

### 1. LRS (Locally Redundant Storage)

**Acronym**: LRS = Locally Redundant Storage

How it works:
- Azure maintains multiple copies of your data inside one physical location in one Azure region.
- Protection scope is local hardware/rack/node failures.

What it does not protect against:
- Availability Zone outage
- Regional disaster

When to use LRS:
- Development/test workloads
- Non-critical data
- Cost-sensitive workloads where business accepts limited resilience

Professional note:
- LRS can still meet high durability expectations, but its availability profile is weaker than zone-aware options.

### 2. ZRS (Zone-Redundant Storage)

**Acronym**: ZRS = Zone-Redundant Storage

How it works:
- Data copies are spread across multiple Availability Zones in the same region.
- If one zone has a power/network/datacenter issue, data remains available from other zones.

When to use ZRS:
- Production applications that require in-region zone resilience
- Workloads with strict availability targets but no cross-region mandate

Trade-off:
- Higher cost than LRS
- No paired-region copy by default

### 3. GRS (Geo-Redundant Storage)

**Acronym**: GRS = Geo-Redundant Storage

How it works:
- Primary region stores local copies.
- Data is replicated asynchronously to the Azure paired region.

Operational impact:
- Supports regional disaster recovery strategy.
- Secondary region is not directly readable by default.

Critical behavior:
- Replication is asynchronous, so recent writes may not exist in secondary during failover scenarios.

### 4. RA-GRS (Read-Access Geo-Redundant Storage)

**Acronym**: RA-GRS = Read-Access Geo-Redundant Storage

How it works:
- Same replication model as GRS.
- Adds read access to the secondary endpoint.

When to use:
- Read-heavy analytics/reporting from secondary region
- Business continuity patterns requiring read-only fallback access

Trade-off:
- Higher cost than GRS
- Write operations still target primary

### 5. GZRS (Geo-Zone-Redundant Storage)

**Acronym**: GZRS = Geo-Zone-Redundant Storage

How it works:
- In primary region: zone-level replication (like ZRS)
- Across regions: asynchronous geo replication (like GRS)

This combines:
- Zone failure resilience
- Regional disaster resilience

When to use:
- Critical production workloads with strong availability and disaster recovery requirements

### 6. RA-GZRS (Read-Access Geo-Zone-Redundant Storage)

**Acronym**: RA-GZRS = Read-Access Geo-Zone-Redundant Storage

How it works:
- Same as GZRS for resilience architecture
- Adds readable secondary endpoint

When to use:
- Mission-critical workloads that need zone + geo resilience and read continuity from secondary

Trade-off:
- Highest cost in this family
- Requires clear operating model for primary/secondary reads

## Redundancy Decision Matrix (Professional View)

| Requirement | Recommended option | Why |
|---|---|---|
| Lowest cost, non-critical | LRS | Local resilience only, minimal cost |
| Survive zone outage in one region | ZRS | Multi-zone replication in-region |
| Regional DR needed (no secondary reads) | GRS or GZRS | Paired-region replication |
| Regional DR plus readable secondary | RA-GRS or RA-GZRS | Secondary endpoint for read scenarios |
| Strict production BC/DR with zone and region resilience | GZRS or RA-GZRS | Strongest architecture in this set |

## Failure Scenarios and Behavior

| Failure event | LRS | ZRS | GRS | RA-GRS | GZRS | RA-GZRS |
|---|---|---|---|---|---|---|
| Disk/node failure in one datacenter | Survives | Survives | Survives | Survives | Survives | Survives |
| Single zone outage | At risk | Survives | At risk | At risk | Survives | Survives |
| Full regional outage | Fails | Fails | Recoverable via geo copy | Read secondary, recover via geo copy | Recoverable via geo copy | Read secondary, recover via geo copy |
| Read from secondary region without failover | No | No | No | Yes | No | Yes |

## RPO and RTO Guidance

**Acronyms**:
- RPO = Recovery Point Objective (maximum acceptable data loss window)
- RTO = Recovery Time Objective (maximum acceptable restoration time)

Practical guidance:
- LRS/ZRS reduce local and zone-level risk but do not provide cross-region disaster recovery.
- GRS/GZRS families improve disaster recovery posture, but asynchronous replication means non-zero RPO.
- Redundancy choice alone does not guarantee target RTO; runbooks, DNS failover, and application failover are required.

## Exam Traps and Professional Pitfalls

1. Assuming geo-redundancy is synchronous: it is asynchronous.
2. Confusing durability with application uptime: they are not the same metric.
3. Choosing RA options without a plan for how applications use the secondary read endpoint.
4. Picking lowest cost SKU before defining business continuity objectives.
5. Expecting redundancy to replace backups and restore testing.

---

## Durability vs Availability vs Recoverability

These terms are related, but they are not the same:

- **Durability**: probability the data remains intact
- **Availability**: probability the service stays reachable
- **Recoverability**: how quickly the workload can be restored and used again

A more redundant SKU improves resilience, but it does **not** replace application failover planning, backup strategy, or testing.

---

## How to Choose the Right Redundancy

Use this simple decision flow:

1. **Need only low-cost local protection?** → `LRS`
2. **Need resilience to zonal failures in one region?** → `ZRS`
3. **Need regional disaster recovery?** → `GRS` or `GZRS`
4. **Need read access to the secondary region?** → `RA-GRS` or `RA-GZRS`

### Example scenarios

| Scenario | Good choice | Why |
|---|---|---|
| Lab or dev/test storage | `Standard_LRS` | Lowest cost and simplest setup |
| Production app in a zonal architecture | `Standard_ZRS` | Survives a single-zone issue |
| Critical production data with regional DR | `Standard_GZRS` | Stronger resilience across zones and regions |
| Read-heavy reporting from secondary region | `RA-GRS` / `RA-GZRS` | Secondary endpoint can be read |

---

## Feature Compatibility Matters

Not all combinations support every feature. Validate requirements such as:

- **hierarchical namespace (ADLS Gen2)**
- **NFS support**
- **SFTP support**
- **premium file shares**
- **large file shares**
- **private endpoints and network controls**

A design can fail not because the storage account exists, but because the selected SKU or redundancy does not support the needed feature set.

---

## CLI Reference

### Create a general-purpose v2 storage account

```bash
az storage account create \
  --name <storage-name> \
  --resource-group <rg> \
  --location australiaeast \
  --kind StorageV2 \
  --sku Standard_LRS
```

### Review account configuration

```bash
az storage account show \
  --name <storage-name> \
  --resource-group <rg> \
  --query "{kind:kind,sku:sku.name,location:location,accessTier:accessTier,publicNetworkAccess:publicNetworkAccess}" \
  -o table
```

### Change redundancy when supported

```bash
az storage account update \
  --name <storage-name> \
  --resource-group <rg> \
  --sku Standard_ZRS
```

---

## Best Practices

1. Use **`StorageV2`** unless the workload clearly needs a specialized premium account.
2. Choose redundancy based on **business continuity**, not just cost.
3. Validate whether required features are supported by the selected SKU.
4. Apply **network restrictions**, RBAC, and private connectivity early.
5. Tag storage accounts by **environment**, **owner**, and **data classification**.

---

## Troubleshooting Checklist

If a storage account design is not behaving as expected:

1. Confirm the **account kind** and **SKU** actually match the requirement.
2. Check whether the desired feature is supported with the chosen redundancy.
3. Verify network access settings, firewall rules, or private endpoints.
4. Confirm the application is using the correct endpoint (`blob`, `file`, etc.).
5. Review whether the workload needs backup or failover planning in addition to replication.

---

## Common Pitfalls

- Confusing **durability** with **availability**.
- Assuming geo-replication is synchronous.
- Choosing the cheapest option without considering RPO/RTO.
- Forgetting storage account names must be **globally unique**.
- Assuming a redundancy choice alone creates a full disaster recovery plan.
- Ignoring feature compatibility for NFS, Data Lake, or premium file workloads.

---

## Key Takeaways

- A storage account is the main Azure boundary for Blob, Files, Queue, and Table services.
- **`StorageV2`** is the default choice for most AZ-104 scenarios.
- Redundancy choices trade off **cost**, **zone resilience**, and **regional DR capability**.
- Good storage design combines **redundancy + security + operational recovery planning**.

---

## Advanced: Redundancy Strategy and Recovery Objectives

### Align Redundancy to Business Requirements

Redundancy choice should map to explicit objectives:

- RPO: acceptable data loss window
- RTO: acceptable restoration time
- Compliance: geographic and sovereignty constraints

### Replication Trade-offs

- LRS offers local durability at lowest complexity and cost
- ZRS improves zone-level resilience in-region
- GRS/GZRS add regional recovery capabilities with higher cost and operational planning requirements

### Failover and Application Readiness

- Geo-redundancy does not remove need for application failover planning
- Validate client retry, DNS, and dependency recovery behavior
- Document operational runbooks for incident scenarios

## Extended Troubleshooting Matrix (Storage Redundancy)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Unexpected durability gap in design review | Redundancy type mismatched to requirement | Compare selected SKU to RPO/RTO targets | Reprovision with appropriate redundancy |
| Application latency increase | Cross-region access pattern or network bottleneck | Measure client path and storage metrics | Optimize region placement and client behavior |
| Feature unavailable after account creation | Selected redundancy/performance combo unsupported for feature | Review account capability matrix | Adjust account type or architecture |
| DR drill fails operationally | Runbook incomplete for failover path | Execute controlled failover simulation | Update runbook and automation steps |

## Production Readiness Checklist (Storage Accounts and Redundancy)

- RPO and RTO objectives mapped to storage redundancy type
- Data residency and compliance constraints validated
- Client retry and failover behavior tested
- Monitoring in place for replication and availability signals
- DR runbook documented and periodically exercised
- Cost impact of redundancy choice reviewed and approved


---

## Further Reading

- [Azure storage account overview](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- [Azure Storage redundancy](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy)
- [Disaster recovery and failover for Azure Storage](https://learn.microsoft.com/en-us/azure/storage/common/storage-disaster-recovery-guidance)
