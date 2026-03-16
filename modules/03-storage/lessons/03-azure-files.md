# Azure Files: Managed SMB/NFS File Shares

## Overview

Azure Files provides fully managed file shares in Azure that can be mounted by cloud and on-premises clients. It is commonly used for lift-and-shift shared drives, application shared content, and hybrid file scenarios.

AZ-104 expects you to understand service purpose, protocol options, authentication choices, quotas, and common operational constraints.

---

## What You Will Learn

- What Azure Files is and where it fits
- SMB/NFS protocol considerations
- Share tiers and account choices
- Identity and key-based access patterns
- Hybrid extension with Azure File Sync
- Security and troubleshooting essentials

---

## Architecture View

```
 [Client VM / App / User]
      |
      +--> [SMB]
      +--> [NFS (supported scenarios)]
             |
             v
        [Azure File Share]
             |
             v
        [Storage Account]
             |
             v
        [Snapshots / Backup / Monitoring]
```

---

## Core Concepts

- **Azure File Share**: Managed file share resource inside a storage account.
- **Protocols**:
  - SMB: Broad Windows/Linux support for enterprise file sharing patterns.
  - NFS: Supported in specific Azure Files configurations and commonly associated with premium file share scenarios; verify feature compatibility before design decisions.
- **Share sizing and performance**: Depends on account/share tier and selected performance model.
- **Quota**: Share-level capacity controls available for governance/cost.
- **Snapshots**: Share snapshots support point-in-time recovery patterns and should be considered in operational protection design.

---

## Share Tiers and Performance Model

- **Standard file shares** are HDD-backed and typically used for general-purpose shared storage.
- **Premium file shares** are SSD-backed and intended for performance-sensitive workloads.
- Standard share tiers can differ in pricing/performance characteristics, while premium shares follow a different provisioning model.

Design implication: choose Azure Files tier based on workload IO, latency expectations, and protocol requirements rather than on capacity alone.

---

## Access and Identity

- Key-based access is simple but broad and should be tightly controlled.
- Identity-based access options exist for SMB scenarios and enterprise integration.
- SAS can be used for delegated, time-bound access patterns.

Important: Identity-based integration is primarily an SMB topic; protocol and authentication choices are not interchangeable across all Azure Files scenarios.

Operationally, SMB identity design and NFS access design should be treated as separate planning concerns.

Design principle: Prefer least privilege and avoid long-lived broad credentials.

---

## Hybrid Scenario: Azure File Sync

Azure File Sync can synchronize Azure file shares with Windows Server endpoints, enabling local caching and centralized cloud-backed namespace.

Use cases:
- branch office file access with local performance
- central cloud-backed storage with on-prem cache

Operational note: Azure File Sync is a hybrid caching/synchronization design, not a replacement for understanding share security, quota, and backup behavior.

Cloud tiering in File Sync can keep colder data in Azure while frequently used files remain cached locally, but it must be planned with recall behavior and on-prem capacity in mind.

---

## Operational Guidance

1. Pick account/share tier based on workload IO profile.
2. Define quotas and monitoring alerts early.
3. Restrict network exposure using firewall rules/private endpoints.
4. Plan backups/snapshots before onboarding critical data.
5. Rotate keys and avoid embedding them in scripts where possible.
6. Validate client protocol requirements before choosing account/share tier.
7. Confirm whether private connectivity, DNS, and firewall rules are required before production rollout.

---

## Common Pitfalls and Exam Traps

- Confusing blob containers with file shares.
- Ignoring SMB network prerequisites (for example, outbound port 445 restrictions in some environments).
- Overusing storage account keys instead of scoped/identity-based models.
- Skipping backup/snapshot strategy before production cutover.
- Assuming SMB and NFS use the same identity and connectivity model.
- Choosing standard vs premium without validating workload performance profile.

---

## Quick CLI Reference

```bash
# Create file share
az storage share-rm create \
  --resource-group <rg> \
  --storage-account <storage-account> \
  --name <share-name> \
  --quota <gb>

# List file shares
az storage share-rm list \
  --resource-group <rg> \
  --storage-account <storage-account> \
  -o table

# Create directory in share (data plane)
az storage directory create \
  --account-name <storage-account> \
  --share-name <share-name> \
  --name <directory-path> \
  --auth-mode login
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/storage/files/storage-files-introduction
- https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-overview
- https://learn.microsoft.com/en-us/azure/storage/file-sync/file-sync-introduction

