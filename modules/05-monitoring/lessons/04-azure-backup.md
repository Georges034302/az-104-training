# Azure Backup for VM Protection

## Overview

Azure Backup provides managed data protection for Azure workloads, including virtual machines. In AZ-104, VM backup with Recovery Services vaults is a core operation and exam scenario.

---

## What You Will Learn

- Recovery Services vault role and design considerations
- Backup policy schedule and retention behavior
- Recovery point lifecycle basics
- Restore paths and validation strategy
- Backup governance and operational controls

---

## Architecture View

```
 [Azure VM]
    |
    v
 [Backup Policy]
    |
    v
 [Recovery Services Vault]
    |
    v
 [Recovery Points]
    |
    +--> [Restore VM]
    +--> [Restore Disks]
    +--> [File Recovery]
```

---

## Core Concepts

- **Recovery Services vault**:
  - Logical container for backup configuration and recovery metadata.
  - Security and lifecycle settings should be governed centrally.

- **Backup policy**:
  - Defines schedule frequency and retention periods.
  - Policy choice directly influences recovery capability and cost.

- **Recovery points**:
  - Point-in-time states available for restore operations.
  - Availability and retention depend on policy and successful jobs.

Important: Enabling backup is only the start; recoverability must be verified by restore testing.

---

## Restore Options

- **Create new VM** from a recovery point.
- **Restore disks** for controlled recovery workflows.
- **File recovery** for selective restore scenarios.

Operational guidance:

1. Prefer restore-to-new-target for validation and incident isolation.
2. Document restore runbooks before outages happen.
3. Track restore duration versus recovery objectives.

---

## Security and Governance

- Restrict vault operations with least-privilege RBAC.
- Protect critical vault resources with governance controls.
- Monitor backup job failures and policy drift.
- Validate that backup scope matches business-critical assets.

Design principle: Backup architecture must align with RPO/RTO goals, not only policy defaults.

---

## Common Pitfalls and Exam Traps

- Assuming backup enablement guarantees immediate recoverability.
- Ignoring first successful backup status before relying on restore.
- Confusing backup with full disaster recovery orchestration.
- Not testing restore paths.
- Leaving restored resources running and increasing cost unexpectedly.

---

## Quick CLI Reference

```bash
# List Recovery Services vaults in a resource group
az backup vault list \
  --resource-group <rg> \
  -o table

# List backup jobs in a vault
az backup job list \
  --resource-group <rg> \
  --vault-name <vault-name> \
  -o table
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/backup/backup-overview
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-introduction
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-arm-restore-vms
