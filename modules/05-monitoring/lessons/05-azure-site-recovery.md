# Azure Site Recovery (ASR) for Disaster Recovery

## Overview

Azure Site Recovery provides disaster recovery orchestration by replicating workloads and enabling failover to a target location. In AZ-104, the expected depth is strong conceptual and operational understanding of replication and failover workflows.

---

## What You Will Learn

- ASR role in business continuity strategy
- Replication and failover lifecycle
- Test failover versus planned/unplanned failover
- Failback expectations and operational planning
- Distinction between ASR and backup services

---

## Architecture View

```
 [Primary Workload]
        |
        v
 [Replication Policy + ASR]
        |
        v
 [Target Region Replica]
        |
        +--> [Test Failover]
        +--> [Planned Failover]
        +--> [Unplanned Failover]
        |
        v
      [Failback]
```

---

## Core Concepts

- **Replication**:
  - Continuous/periodic data movement to target site per policy.
  - Designed to reduce recovery time during major incidents.

- **Failover types**:
  - Test failover for safe validation.
  - Planned failover for controlled maintenance/migration scenarios.
  - Unplanned failover for outage response.

- **Failback**:
  - Return workflow after primary environment recovery.
  - Requires operational planning and validation.

Important: ASR is not a backup replacement. It addresses service continuity, while backup addresses point-in-time data recovery.

---

## Operational Workflow

1. Define DR requirements (RPO, RTO, scope).
2. Configure recovery infrastructure and replication settings.
3. Run regular test failovers in isolated networks.
4. Validate application behavior, dependencies, and runbooks.
5. Refine recovery plans based on test evidence.

---

## Design and Governance Guidance

- Prioritize mission-critical workloads for replication scope.
- Ensure network mapping and identity dependencies are part of DR design.
- Track replication health and alerts continuously.
- Treat DR tests as mandatory operational evidence, not optional exercises.

---

## Common Pitfalls and Exam Traps

- Treating ASR as identical to backup.
- Enabling replication without testing failover.
- Ignoring application dependency mapping during DR planning.
- Underestimating cost and operational complexity of broad replication scope.
- Missing runbooks for failover communications and sequencing.

---

## Quick Operational Checks

- Replication health state per protected workload
- Last successful replication point visibility
- Recovery plan readiness and test history

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-overview
- https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-failover
- https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-test-failover-to-azure
