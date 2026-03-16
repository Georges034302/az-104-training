# Azure Storage Accounts and Redundancy (LRS, ZRS, GRS, GZRS)

## Overview

A **storage account** is the management boundary for Azure Storage services such as Blob, Files, Queue, and Table. In AZ-104, this topic is critical because design choices at storage-account level affect:

- durability and availability
- data residency and disaster recovery behavior
- performance and cost
- supported features for workloads

---

## What You Will Learn

- Storage account fundamentals and service scope
- Performance/account types relevant to AZ-104
- Redundancy options and when to choose each
- Practical design decisions based on RPO/RTO and cost
- Common operational checks and exam pitfalls

---

## Architecture View

```
 [Storage Account]
      |
      +--> [Blob]
      +--> [Files]
      +--> [Queue]
      +--> [Table]
      |
      v
 [Redundancy Choice]
   |      |      |      |
   v      v      v      v
 [LRS]  [ZRS]  [GRS]  [GZRS]
```

---

## Core Concepts

- **Storage account**: Top-level Azure resource that hosts one or more storage services.
- **Name rules**: Must be globally unique, 3-24 characters, lowercase letters and numbers.
- **Account kind (AZ-104 focus)**: `StorageV2` (general-purpose v2) is the default for most scenarios.
- **Service endpoints**: A storage account exposes service-specific endpoints such as Blob, File, Queue, and Table. Some redundancy and failover behaviors matter because applications connect to these endpoints, not just to the storage account conceptually.
- **Hierarchical namespace (HNS)**: When enabled, the storage account supports Azure Data Lake Storage Gen2 semantics for analytics-style hierarchical access patterns. This affects feature planning and security behavior for supported workloads.
- **Performance tiers**:
  - Standard: HDD-backed, cost-efficient for most workloads.
  - Premium: SSD-backed for low-latency, high-throughput scenarios (service-specific constraints apply).

---

## Capability and Compatibility Planning

Not every storage feature is available in every account/performance/redundancy combination. Before deployment, verify whether your design depends on capabilities such as:

- premium file shares
- NFS support
- hierarchical namespace
- SFTP support
- large file shares
- zone or geo redundancy combinations

Design principle: choose the storage account shape based on workload capability requirements first, then optimize for cost and resilience.

---

## Redundancy Options Explained

- **LRS (Locally Redundant Storage)**
  - Replicates data within a single datacenter in one region.
  - Lowest cost option.
  - No zone-level or cross-region resilience.

- **ZRS (Zone-Redundant Storage)**
  - Replicates across multiple availability zones in one region.
  - Better resilience for zonal failures.
  - Region-scoped, not cross-region DR.

- **GRS (Geo-Redundant Storage)**
  - Keeps primary copies in one region and asynchronously replicates to paired secondary region.
  - Improves regional disaster recovery capability.
  - Secondary endpoint is not readable unless read-access is enabled.

- **RA-GRS (Read-Access GRS)**
  - Same replication model as GRS, plus read access to secondary endpoint.
  - Useful for read-heavy or reporting/failover-read patterns.

- **GZRS (Geo-Zone-Redundant Storage)**
  - Combines zone redundancy in primary region with asynchronous geo-replication to secondary region.
  - Stronger combined zonal + regional resilience profile.

- **RA-GZRS**
  - GZRS plus read access to secondary endpoint.

Important: Geo-replication is asynchronous; design with realistic RPO expectations.

---

## Durability, Availability, and Recoverability

- **Durability**: Likelihood your data remains intact.
- **Availability**: Likelihood the service endpoint remains reachable.
- **Recoverability**: How quickly and safely you can resume service after failure.

These are related but not identical. Higher redundancy improves resilience, but true recoverability also depends on application failover design, data protection settings, and operational readiness.

---

## Failover and Read Access

- **Read-access variants** (`RA-GRS`, `RA-GZRS`) expose a readable secondary endpoint.
- **Geo-failover** is not the same thing as normal replication; failover changes the writable primary region for the account.
- Applications that require read access to the secondary region must be designed to use the secondary endpoint intentionally.
- Secondary region replicas are not a replacement for application-level DR planning, testing, and endpoint handling.

Design implication: choosing RA-GRS or RA-GZRS does not automatically make applications multi-region aware.

---

## How To Choose Redundancy (Practical)

1. Start with business continuity requirements: target RPO/RTO.
2. Decide if zone-level resilience is required.
3. Decide if regional DR is required.
4. Decide if secondary region read access is needed.
5. Compare cost and feature compatibility before production rollout.

Typical pattern:
- Dev/test: LRS (cost-first)
- Production with zone resilience: ZRS
- Production with regional DR: GRS/GZRS variants

---

## Operational Guidance

- Tag storage accounts by owner, environment, and data classification.
- Validate account configuration after creation (sku, kind, network/public access settings).
- Not all redundancy changes are supported in all scenarios; validate conversion path before committing.
- Confirm whether features like hierarchical namespace, premium-only capabilities, or protocol-specific features affect the account design before deployment.
- Consider network controls and identity model early; storage design is not only redundancy.

---

## Common Pitfalls and Exam Traps

- Confusing **durability** with **availability**.
- Assuming geo-replication is synchronous (it is asynchronous).
- Choosing redundancy solely by cost, ignoring recovery requirements.
- Forgetting naming constraints and global uniqueness.
- Expecting every feature/tier combination to be supported in every redundancy mode.
- Assuming replication choice alone is a complete DR design; application failover behavior still has to be planned.
- Designing for resilience without validating whether the selected account configuration supports the required protocols/features.

---

## Quick CLI Reference

```bash
# Create storage account (example)
az storage account create \
  --name <storage-name> \
  --resource-group <rg> \
  --location <region> \
  --kind StorageV2 \
  --sku Standard_LRS

# Show account kind/sku/redundancy
az storage account show \
  --name <storage-name> \
  --resource-group <rg> \
  --query "{kind:kind,sku:sku.name,location:location,accessTier:accessTier}" \
  -o table

# Update redundancy sku (when supported)
az storage account update \
  --name <storage-name> \
  --resource-group <rg> \
  --sku Standard_ZRS
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview
- https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy

