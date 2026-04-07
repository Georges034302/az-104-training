# Azure Backup for VM Protection and Recovery

> Azure Backup provides managed data protection for Azure workloads, including virtual machines. In AZ-104, the most important administrator scenario is protecting VMs with a **Recovery Services vault**, backup policies, and tested restore procedures.

---

## Overview

Azure Backup is part of a broader resilience strategy.

It helps recover from:

- accidental deletion
- corruption
- ransomware or destructive change
- operational mistakes

But backup is **not the same thing** as high availability or disaster recovery. Backup gives you a point-in-time recovery path; it does not automatically keep a workload online during an outage.

---

## What You Will Learn

- The role of the Recovery Services vault in VM backup
- How backup policies define schedule and retention
- What recovery points are and how restore options differ
- Backup governance and security best practices
- Common AZ-104 mistakes around backup versus DR

---

## Backup Mental Model

```text
[Azure VM]
    |
    v
[Backup policy]
    |
    v
[Recovery Services vault]
    |
    v
[Recovery points]
    |
    +--> [Restore VM]
    +--> [Restore disks]
    +--> [File recovery]
```

---

## Core Concepts

### Recovery Services vault

A **Recovery Services vault** is the management boundary used in many Azure Backup and Site Recovery scenarios that administrators encounter in AZ-104.

It helps organize:

- protected items
- backup configuration
- recovery metadata
- restore operations

Because restore and deletion operations are security-sensitive, vault access should be tightly controlled.

### Backup policy

A backup policy defines:

- how often backups run
- how long recovery points are retained
- the balance between recoverability and cost

### Recovery points

A **recovery point** is a point-in-time backup state from which a workload can be restored.

> Enabling backup is only the beginning. Real recoverability must be verified by testing restores.

---

## Restore Options

Common restore paths include:

- **Create a new VM** from a recovery point
- **Restore disks** for controlled rebuild or investigation scenarios
- **File recovery** when selective recovery is supported and more efficient than full VM restore

### Operational guidance

1. prefer restoring to a new target during validation or investigation
2. document restore runbooks before an incident occurs
3. compare restore duration with the business recovery objective

---

## Backup vs High Availability vs DR

| Capability | Main purpose |
|---|---|
| **Backup** | Recover data or workloads from a prior point in time |
| **High availability** | Reduce downtime through redundancy |
| **Disaster recovery** | Restore service after major site/region disruption |

These controls work best **together**, not as substitutes for one another.

---

## Example Scenario

A production VM is accidentally misconfigured and becomes unusable:

- backup provides a recovery point to restore from
- high availability could reduce user impact if another instance exists
- disaster recovery is relevant only if the issue affects a broader site or region scenario

This distinction is frequently tested in AZ-104.

---

## Restore Planning and Cost Considerations

Backup design is not only about creating a policy—it is also about understanding how recovery behaves in practice.

### Planning points administrators should know

- the **first successful backup job** may take time before a usable recovery point appears
- longer retention and higher backup storage consumption can increase cost over time
- restore operations may take longer than expected during large recovery events
- test restores should usually target a **new VM or alternate location** to avoid accidental overwrite
- any restored disks or temporary recovery artifacts should be deleted after validation

---

## Security and Governance

Good backup administration includes:

- least-privilege RBAC for vault operations
- monitoring backup failures and missed jobs
- validating that all business-critical VMs are protected
- aligning retention with compliance and operational requirements

Design principle:

> A backup design should be driven by **RPO/RTO requirements**, not only by default policy settings.

---

## Azure CLI Examples

### List Recovery Services vaults in a resource group

```bash
az backup vault list \
  --resource-group <rg> \
  -o table
```

### List backup jobs in a vault

```bash
az backup job list \
  --resource-group <rg> \
  --vault-name <vault-name> \
  -o table
```

---

## Best Practices

1. protect critical VMs with clearly defined policies
2. verify the **first successful backup** before relying on recovery
3. test restore procedures regularly
4. secure vault operations and monitor for configuration drift
5. avoid assuming that backup alone satisfies all resilience requirements

---

## Common Pitfalls and Exam Traps

- Assuming backup enablement guarantees immediate recoverability.
- Ignoring first successful backup status before relying on restore.
- Confusing backup with full disaster recovery orchestration.
- Never testing restore paths.
- Leaving restored resources running and increasing cost unexpectedly.

---

## Key Takeaways

- Azure Backup protects workloads through **vaults, policies, and recovery points**.
- The restore path matters as much as the backup job itself.
- Backup solves recoverability, not necessarily uptime.
- Administrators should treat backup as both an **operations** and **security** responsibility.

---

## Further Reading

- [Azure Backup overview](https://learn.microsoft.com/en-us/azure/backup/backup-overview)
- [Backup for Azure VMs](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-introduction)
- [Restore Azure VMs from backups](https://learn.microsoft.com/en-us/azure/backup/backup-azure-arm-restore-vms)
