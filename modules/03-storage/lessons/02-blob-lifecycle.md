# Azure Blob Storage and Lifecycle Management

> Azure Blob Storage is the object storage platform for unstructured data such as documents, backups, logs, images, and application artifacts. Lifecycle management helps administrators reduce cost without losing control of retention and recovery.

---

## Overview

Blob Storage is one of the most important Azure services for AZ-104. Administrators are expected to understand:

- containers and blob types
- access tiers and cost trade-offs
- lifecycle management policies
- soft delete, versioning, and recovery protections
- how to secure and manage blob data over time

---

## What You Will Learn

- How Blob Storage is organized inside a storage account
- The difference between block, append, and page blobs
- How Hot, Cool, Cold, and Archive tiers are used
- How lifecycle rules automate tiering and cleanup
- How to combine cost optimization with data protection

---

## Blob Storage Mental Model

```text
[Storage Account]
      |
      v
[Blob Container]
      |
      +--> [Block blobs]
      +--> [Append blobs]
      +--> [Page blobs]
      |
      +--> [Access tier: Hot / Cool / Cold / Archive]
      +--> [Lifecycle policy]
      +--> [Protection: soft delete / versioning / immutability]
```

---

## Core Concepts

### Containers and blobs

- A **container** is a logical grouping of blobs.
- A **blob** is an individual object stored in Azure.

### Blob types

| Blob type | Best for | Notes |
|---|---|---|
| **Block blob** | Documents, images, backups, application files | Most common blob type |
| **Append blob** | Logging workloads | Optimized for append operations |
| **Page blob** | Random read/write patterns such as VHD scenarios | Common in infrastructure-related usage |

---

## Access Tiers

Blob Storage supports multiple cost/performance tiers.

| Tier | Access pattern | Cost profile | Key note |
|---|---|---|---|
| **Hot** | Frequently accessed data | Highest storage cost, lowest access cost | Default for active data |
| **Cool** | Infrequently accessed data | Lower storage cost, higher access cost | Good for short-term retention |
| **Cold** | Rarely accessed online data | Lower storage cost than Cool | Still online, but less economical for frequent reads |
| **Archive** | Very infrequent long-term retention | Lowest storage cost | Offline tier; retrieval is not immediate |

### Important behavior

- `Hot`, `Cool`, and `Cold` are **online** tiers.
- `Archive` is an **offline** tier.
- Archived data must be **rehydrated** before normal access.
- Lower-cost tiers may have **minimum retention periods** and **early deletion charges**.

---

## Lifecycle Management

Lifecycle management uses **JSON policies** to automatically move or delete blobs based on conditions such as age.

### Common actions

- move blobs from **Hot** to **Cool**
- move blobs to **Archive** after long retention
- delete blobs after a defined retention period

### Common filters

- prefix-based path matching
- blob type selection
- days since modification or creation

### Example lifecycle policy

```json
{
  "rules": [
    {
      "name": "tier-and-delete-logs",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["logs/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 180
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          }
        }
      }
    }
  ]
}
```

> Lifecycle policies are **asynchronous**. They do not run exactly at the minute a blob crosses the threshold.

---

## Data Protection Features

Cost optimization should be paired with recovery protection.

| Feature | Purpose |
|---|---|
| **Blob soft delete** | Recover deleted blobs during the retention window |
| **Container soft delete** | Recover deleted containers |
| **Versioning** | Keep earlier versions when a blob changes |
| **Snapshots** | Point-in-time copies for recovery or rollback |
| **Change feed** | Immutable log of blob changes |
| **Immutability / legal hold** | Prevent changes or deletion for regulated data |

### Design principle
A good design uses **lifecycle rules** for cost control and **soft delete/versioning** for safety.

---

## Example Scenarios

### 1. Daily app logs

- write logs to a `logs/` container
- move to **Cool** after 30 days
- archive after 180 days
- delete after 1 year

### 2. Active website media

- keep in **Hot** tier because users read files frequently
- do not archive unless usage truly drops

### 3. Long-term compliance backup

- consider **Archive** tier plus immutability where required
- make sure restore expectations are documented because rehydration takes time

---

## Azure CLI Examples

### Create a private container

```bash
az storage container create \
  --name appdata \
  --account-name <storage-account> \
  --public-access off \
  --auth-mode login
```

### Upload a blob

```bash
az storage blob upload \
  --account-name <storage-account> \
  --container-name appdata \
  --name sample.txt \
  --file ./sample.txt \
  --auth-mode login
```

### Move a blob to Cool tier

```bash
az storage blob set-tier \
  --account-name <storage-account> \
  --container-name appdata \
  --name sample.txt \
  --tier Cool \
  --auth-mode login
```

### Apply a lifecycle policy

```bash
az storage account management-policy create \
  --account-name <storage-account> \
  --resource-group <rg> \
  --policy @policy.json
```

---

## Best Practices

1. Classify data by **access pattern**, **retention**, and **recovery need**.
2. Start lifecycle rules conservatively, then tune based on real usage.
3. Enable **soft delete** and **versioning** before applying aggressive delete rules.
4. Keep compliance retention separate from cost-only lifecycle cleanup.
5. Use least-privilege **data-plane RBAC roles** for blob operations.

---

## Troubleshooting Checklist

If blob access or lifecycle behavior looks wrong:

1. Confirm the blob is in the expected **container** and **tier**.
2. Check whether the lifecycle policy scope and prefix filters match the blob path.
3. Remember lifecycle actions are **not immediate**.
4. Verify that archived data has been **rehydrated** before expecting normal reads.
5. Check RBAC, SAS, firewall rules, or private endpoints if the problem is access-related.

---

## Common Pitfalls and Exam Traps

- Moving active data to Cool or Archive too early.
- Assuming Archive data is instantly readable.
- Enabling delete rules without recovery protections in place.
- Confusing management-plane roles with blob **data-plane** permissions.
- Ignoring minimum retention or early deletion cost implications for lower-cost tiers.

---

## Key Takeaways

- Blob Storage is Azure’s object store for unstructured data.
- Access tiers help balance **cost** against **retrieval speed and frequency**.
- Lifecycle management automates tiering and cleanup, but it must be designed carefully.
- Protection features like **soft delete** and **versioning** are essential safety controls.

---

## Further Reading

- [Introduction to Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)
- [Lifecycle management overview](https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview)
- [Soft delete for blobs](https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview)
- [Blob versioning](https://learn.microsoft.com/en-us/azure/storage/blobs/versioning-overview)
