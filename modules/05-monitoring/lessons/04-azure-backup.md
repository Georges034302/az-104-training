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

## Acronyms and Terms (Do Not Assume)

- RPO = Recovery Point Objective
- RTO = Recovery Time Objective
- BCDR = Business Continuity and Disaster Recovery
- MFA = Multi-Factor Authentication
- RBAC = Role-Based Access Control
- WORM = Write Once Read Many (immutability concept)

These terms define backup policy quality and recovery expectations.

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

## Deep Dive: Backup Policy Engineering

A professional backup policy should specify:

1. Workload tier (critical, important, non-critical)
2. Backup frequency per tier
3. Retention windows (daily/weekly/monthly/yearly where required)
4. Restore testing cadence
5. Ownership for backup failure remediation

Example policy model:
- Tier 1 critical VMs: daily backup, longer retention, quarterly restore drill
- Tier 2 business VMs: daily backup, moderate retention, semiannual restore drill
- Tier 3 dev/test VMs: lower retention and simpler restore requirements

## Vault Security Hardening

Protect backup assets as security-critical infrastructure:

1. Restrict vault permissions with least privilege RBAC.
2. Require strong identity controls for privileged operations.
3. Monitor and alert on policy changes, stop-protection events, and deletions.
4. Use immutable/locked backup patterns where compliance or ransomware risk requires it.

Backup systems are high-value targets during attacks; security posture must reflect that.

## Restore Runbook Minimum Content

Every critical VM should have a tested restore runbook including:

1. Recovery point selection criteria
2. Restore target choice (new VM, disk restore, file recovery)
3. Network and DNS validation steps after restore
4. Application-level health checks
5. Rollback/cleanup steps if validation fails

This turns backup configuration into operational recovery capability.

## Deep Dive Use Cases: Backup, DR, Migration, and Azure Files

### Use case 1: Backup-first protection for business VMs

Scenario:
- Line-of-business VM hosts application and local data.
- Business requires point-in-time recovery for accidental deletion or ransomware.

Design:
- Protect VM with Recovery Services vault policy.
- Use longer retention for monthly/quarterly compliance.
- Run periodic restore drills to alternate resource group.

Why this works:
- Backup gives recovery to known-good state.
- It protects from logical/data corruption where HA alone does not help.

### Use case 2: DR with backup as a safety layer

Scenario:
- Critical workload has high uptime requirements and regional risk.

Design:
- Use ASR for service continuity/failover.
- Use Azure Backup for point-in-time restoration.

Operational insight:
- ASR handles continuity during outage.
- Backup handles corruption, accidental deletion, and forensic restore.
- Mature BCDR combines both rather than replacing one with the other.

### Use case 3: Migration safety net

Scenario:
- Team is migrating VM workload or app stack and needs rollback safety.

Design:
- Take and validate recent backup before migration cutover.
- Keep recovery points through migration window.
- Use restore as rollback option if post-migration validation fails.

Professional note:
- Backup is not migration tooling itself; it is migration risk control.

### Use case 4: Azure Files backup and recovery

Scenario:
- Organization uses Azure Files (SMB/NFS shares) for shared application data.
- Needs restore for deleted files, corruption, and ransomware events.

Design considerations:
- Configure Azure Files backup in Recovery Services vault.
- Define share-level retention policy aligned to business requirements.
- Test item-level and share-level restore procedures.
- Combine backup with snapshots and access hardening.

When this is especially important:
- Lift-and-shift file server migrations
- Branch office shares with Azure File Sync
- Shared application content with high change rate

### Backup Use-Case Decision Guide

| Objective | Primary control | Secondary control |
|---|---|---|
| Recover deleted/corrupted data | Azure Backup | Snapshots, soft-delete features where applicable |
| Keep service online during regional outage | ASR / HA architecture | Backup for post-incident data recovery |
| Reduce migration rollback risk | Pre-cutover backup | Staged validation and runbook approvals |
| Protect Azure Files shares | Azure Files backup policy | Share snapshots and access governance |

## Dedicated End-to-End Scenarios

### Scenario A: Ransomware recovery for business-critical VM

Objective:
- Restore service quickly with minimal data loss after encryption event.

Environment:
- Production VM with daily backup policy in Recovery Services vault.
- Security operations detects malicious encryption activity.

Execution flow:
1. Isolate compromised VM from network.
2. Identify clean recovery point before attack timestamp.
3. Restore to a new VM in quarantine resource group.
4. Validate OS integrity, app health, and data consistency.
5. Promote restored VM to production path after approval.

Validation checklist:
- Recovery point age within RPO target.
- Service restored within RTO target.
- Root cause recorded and hardening actions applied.

### Scenario B: Migration rollback safety for line-of-business app

Objective:
- Execute planned migration with proven fallback option.

Environment:
- Legacy VM app migrating to new network/app topology.

Execution flow:
1. Take pre-cutover backup and validate backup job success.
2. Perform migration cutover and post-cutover health checks.
3. If validation fails, restore from pre-cutover recovery point.
4. Re-run migration after remediation.

Why this scenario matters:
- Backup enables safe experimentation and controlled rollback during migration windows.

### Scenario C: Azure Files recovery after accidental share cleanup

Objective:
- Recover deleted files and restore business operations for shared content workload.

Environment:
- Azure Files share used by application and branch-office users.
- Backup policy enabled for file share via Recovery Services vault.

Execution flow:
1. Identify impacted folders and deletion window.
2. Restore required file set or full share from appropriate recovery point.
3. Validate ACL and access behavior for user groups.
4. Reconcile restored content with recent valid changes if needed.

Operational lessons:
- Azure Files backup must be tested at both item-level and full-share recovery level.
- Permission validation is mandatory after restore to avoid hidden access incidents.

---

## CLI Reference

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

## Common Pitfalls

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

## Advanced: Backup Governance and Recovery Confidence

### Policy Design

- Classify workloads by criticality and retention obligations
- Define backup frequency and retention by data change profile
- Include immutable and secure backup options where required

### Recovery-Centric Validation

- Backup success is not equivalent to recovery success
- Perform periodic restore drills for representative systems
- Measure actual RTO and data consistency outcomes

### Security Posture

- Protect backup vault access with least privilege and MFA
- Monitor and alert on backup policy changes
- Include ransomware-resilience controls in design

## Extended Troubleshooting Matrix (Azure Backup)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Backup job fails repeatedly | Agent/extension or policy configuration issue | Review job logs and policy assignment | Correct config and rerun backup |
| Restore takes longer than expected | Recovery plan not optimized | Measure restore path and bottlenecks | Refine restore process and pre-stage dependencies |
| Missing restore points | Schedule or retention misconfiguration | Audit backup schedule and retention settings | Correct policy and validate future points |
| Unauthorized backup change risk | Excessive permissions on vault | Review RBAC and audit logs | Reduce privileges and enforce controls |

## Production Readiness Checklist (Azure Backup)

- Backup policies aligned to workload RPO/RTO requirements
- Restore drills executed and documented
- Vault access governance and MFA enforced
- Monitoring configured for backup job failures
- Retention and compliance requirements verified
- Incident runbooks include backup and restore procedures


---

## Further Reading

- [Azure Backup overview](https://learn.microsoft.com/en-us/azure/backup/backup-overview)
- [Backup for Azure VMs](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-introduction)
- [Restore Azure VMs from backups](https://learn.microsoft.com/en-us/azure/backup/backup-azure-arm-restore-vms)
