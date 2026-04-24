# Azure Site Recovery (ASR) for Disaster Recovery

> Azure Site Recovery provides disaster recovery orchestration by replicating workloads and enabling **failover to a target location**. In AZ-104, the key focus is understanding replication, failover models, failback, and the difference between ASR and backup.

---

## Overview

ASR supports business continuity when a datacenter, site, or region becomes unavailable.

It helps administrators:

- replicate supported workloads to a recovery site
- bring services online during major disruption
- validate disaster recovery readiness through testing
- return operations to the primary location after recovery

ASR is about **continuity of service**, not long-term point-in-time retention.

---

## What You Will Learn

- The role of ASR in business continuity strategy
- Replication and failover lifecycle basics
- Test failover versus planned and unplanned failover
- Failback expectations and operational planning
- How ASR differs from Azure Backup

---

## ASR Mental Model

```text
[Primary workload]
       |
       v
[Replication policy + ASR]
       |
       v
[Target region replica]
       |
       +--> [Test failover]
       +--> [Planned failover]
       +--> [Unplanned failover]
       |
       v
    [Failback]
```

---

## Core Concepts

### Replication

Replication moves workload data and configuration to the target site according to the protection design.

Its purpose is to reduce recovery time and improve continuity during severe incidents.

### Failover types

- **Test failover**: validates DR readiness safely
- **Planned failover**: used for controlled maintenance or migration events
- **Unplanned failover**: used during unexpected outage conditions

### Failback

After the primary environment is restored, **failback** returns workloads to the normal operating site.

Important:

> DR planning is incomplete if it only covers failover and ignores failback.

---

## ASR vs Backup

| Capability | Main purpose |
|---|---|
| **Azure Site Recovery** | Keep services running or restore them quickly in another location |
| **Azure Backup** | Recover from an earlier point in time after corruption, deletion, or data loss |

A mature resilience design commonly needs **both**.

---

## Operational Workflow

1. define DR requirements such as **RTO**, **RPO**, and workload priority
2. configure replication and target environment settings
3. run regular **test failovers** in isolated networks
4. validate application dependencies, identity, networking, and runbooks
5. improve the recovery plan based on actual test evidence

---

## Design and Governance Guidance

Good ASR design should:

- prioritize mission-critical workloads
- include network mapping and dependency awareness
- track replication health continuously
- document role ownership and communication steps during failover
- treat DR exercises as mandatory operational proof

---

## Planned vs Unplanned Failover Considerations

This distinction is important for both real operations and AZ-104 questions.

- **planned failover** is used when the environment is still reachable and the move can be coordinated, which usually improves order and reduces data-loss risk
- **unplanned failover** is used during real outage conditions, where the priority is restoring service quickly with the best recovery point available
- **failback** often takes more planning than candidates expect because applications, networking, and data paths must be returned to the primary site safely

> Exam tip: ASR supports continuity during disruption, but it does not replace a backup strategy for point-in-time recovery.

---

## Example Scenario

A regional outage affects the primary application environment:

- ASR helps activate the replicated workload in a secondary region
- monitoring and alerts confirm service behavior during the event
- backup remains important if the incident also includes corruption or unwanted data changes

This separation of responsibilities is a common AZ-104 exam theme.

---

## Quick Operational Checks

- replication health state for protected workloads
- visibility of the latest successful replication point
- recovery plan readiness and recent test history

---

## Common Pitfalls

- Treating ASR as identical to backup.
- Enabling replication without testing failover.
- Ignoring application dependency mapping during DR planning.
- Underestimating the cost and complexity of broad replication scope.
- Missing runbooks for sequencing, communication, and ownership.

---

## Key Takeaways

- ASR provides **disaster recovery orchestration**, not traditional backup retention.
- Test failover, planned failover, unplanned failover, and failback each serve different purposes.
- DR readiness depends on documentation, testing, and dependency-aware planning.
- Backup and ASR solve related but different resilience problems.

---

## Advanced: Disaster Recovery Operating Model

### DR Scope and Prioritization

- Prioritize replication for business-critical workloads first
- Group systems by dependency to preserve application integrity
- Define failover sequence and ownership explicitly

### Replication and Failover Discipline

- Validate replication health continuously
- Use recovery plans to orchestrate service start order
- Regularly test planned and unplanned failover scenarios

### Post-Failover Operations

- Document failback prerequisites and timing
- Validate data consistency and application state after failover
- Capture lessons learned from each DR exercise

## Extended Troubleshooting Matrix (Azure Site Recovery)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Replication unhealthy | Connectivity, agent, or capacity issue | Check replication health and event logs | Resolve connectivity/agent issues and re-sync |
| Failover test incomplete | Recovery plan misses dependencies | Validate boot order and dependency mapping | Update recovery plan and retest |
| Application starts but is unusable | Data or service dependency not ready | Run post-failover validation checklist | Add dependency sequencing and readiness checks |
| Failback delayed | Missing reverse replication readiness | Review failback prerequisites | Prepare target environment and execute controlled failback |

## Production Readiness Checklist (Azure Site Recovery)

- Critical workloads prioritized with documented DR tiers
- Recovery plans include dependency-aware sequencing
- Regular failover drills executed and reviewed
- RPO/RTO performance measured during exercises
- Failback process documented and tested
- DR governance integrated with change management


---

## Further Reading

- [Azure Site Recovery overview](https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-overview)
- [Fail over and fail back workloads](https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-failover)
- [Run a test failover to Azure](https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-test-failover-to-azure)
