# Azure Blob Storage and Lifecycle Management

## Overview

Azure Blob Storage is object storage for unstructured data such as backups, logs, media, and application artifacts. Lifecycle management helps you automate cost optimization and retention behavior based on object age and access patterns.

In AZ-104, you are expected to understand blob tiers, lifecycle rules, and protection features well enough to design safe and cost-effective storage.

---

## What You Will Learn

- Blob fundamentals and container model
- Access tiers and practical trade-offs
- Lifecycle policy structure and actions
- Data protection controls (soft delete, versioning)
- Operational patterns and common misconfigurations

---

## Architecture View

```
 [Storage Account]
      |
      v
 [Blob Container]
      |
      v
 [Blobs]
   |       |
   v       v
 [Access Tier]   [Lifecycle Rule]
   |               |
   v               v
 [Hot/Cool/Archive] -> [Tiering / Delete Actions]
```

---

## Core Concepts

- **Container**: Logical grouping for blobs.
- **Blob data types (high level)**:
  - Block blob: common for files and streaming uploads.
  - Append blob: append-heavy logging scenarios.
  - Page blob: random read/write patterns (for example, VHD scenarios).
- **Access tiers**:
  - Hot: frequent access.
  - Cool: infrequent access with lower storage cost and higher access cost.
  - Cold: lower storage cost than Cool for more infrequently accessed online data, with higher access cost and different retention economics.
  - Archive: offline tier for long-term retention; retrieval is not immediate.
- **Default account access tier**: For supported standard blob workloads, the storage account can have a default access tier, but archive remains an explicit blob-level choice rather than a general account default.
- **Archive rehydration**: Archived blobs must be rehydrated before normal online access; retrieval is asynchronous and should be planned rather than assumed as immediate.

---

## Tier Scope and Practical Constraints

- Hot, Cool, and Cold are online access tiers for supported blob scenarios.
- Archive is an offline tier and behaves differently from normal online tiers.
- Access tiering decisions should reflect both storage cost and data retrieval cost/latency.
- Lifecycle rules do not execute instantly at the exact threshold; they are evaluated and applied asynchronously by the platform.

---

## Lifecycle Management

Lifecycle rules are JSON-based policies that evaluate blob properties and apply actions automatically.

Typical actions include:
- Move from Hot to Cool after N days
- Move from Cool to Cold after N days when appropriate
- Move to Archive after N days
- Delete after retention threshold

Typical filters include:
- Prefix match (for path-like segmentation)
- Blob type scope
- Optional conditions by modification age

Important: Lifecycle policies are powerful, but tiering and deletion should be aligned with recovery, legal retention, and actual access patterns.

Lifecycle design should consider not only age, but also restore expectations, legal hold/immutability requirements, and operational rollback needs.

---

## Data Protection Features

- **Blob soft delete**: Recover deleted blobs within retention window.
- **Container soft delete**: Recover deleted containers within retention window.
- **Versioning**: Keeps previous versions when blobs are modified.
- **Blob snapshots**: Point-in-time copies that can support recovery and operational protection patterns.
- **Change feed**: Immutable log of changes for audit/integration use cases.
- **Immutability options**: In supported scenarios, time-based retention or legal hold can prevent changes/deletion for regulated data.
- **Point-in-time restore considerations**: Recovery features are strongest when versioning, soft delete, and related protections are enabled before critical data is written.

Design principle: Cost optimization (lifecycle) and data protection (soft delete/versioning) should be configured together.

---

## Operational Guidance

1. Classify datasets by access frequency and retention requirements.
2. Start lifecycle rules conservatively and observe impact.
3. Test restore/recovery path before production incidents occur.
4. Keep legal/compliance retention separate from cost-only cleanup logic.
5. Use least-privilege data-plane roles for blob operations.
6. Account for early deletion charges and retrieval delay when using lower-cost tiers.

---

## Common Pitfalls and Exam Traps

- Tiering actively used data to Cool/Archive and increasing access costs/latency.
- Assuming Archive data is instantly readable.
- Enabling lifecycle deletes without recovery safeguards.
- Confusing management-plane role assignment with data-plane access permissions.
- Forgetting that lower-cost tiers can have minimum retention or early deletion cost implications.
- Mixing cost-optimization rules with compliance retention requirements without clearly separating them.

---

## Quick CLI Reference

```bash
# Create container
az storage container create \
  --name <container> \
  --account-name <storage-account> \
  --auth-mode login

# Upload a blob
az storage blob upload \
  --account-name <storage-account> \
  --container-name <container> \
  --name <blob-name> \
  --file <local-file> \
  --auth-mode login

# Set access tier on a blob
az storage blob set-tier \
  --account-name <storage-account> \
  --container-name <container> \
  --name <blob-name> \
  --tier Cool \
  --auth-mode login

# Apply lifecycle policy from JSON
az storage account management-policy create \
  --account-name <storage-account> \
  --resource-group <rg> \
  --policy @policy.json
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
- https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview
- https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview

