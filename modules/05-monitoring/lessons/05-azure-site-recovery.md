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

## Acronyms and Terms (Do Not Assume)

- ASR = Azure Site Recovery
- DR = Disaster Recovery
- RPO = Recovery Point Objective
- RTO = Recovery Time Objective
- BCDR = Business Continuity and Disaster Recovery
- DNS = Domain Name System

These terms are required for designing and operating a DR program.

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

## Deep Dive: Recovery Plan Design

Recovery plans should orchestrate more than VM startup.

Include:
1. Boot sequence by dependency tier (identity, data, app, frontend)
2. Network mapping and subnet readiness
3. DNS and traffic redirection steps
4. Application validation checkpoints
5. Business-owner sign-off criteria

Without dependency-aware sequencing, failover may succeed technically but fail operationally.

## Test Failover Discipline

Test failover should be treated as a recurring control, not a one-time exercise.

Professional pattern:
1. Execute in isolated test network.
2. Validate app functionality, authentication, and data integrity.
3. Measure achieved RTO and RPO against targets.
4. Record gaps and assign remediation actions.
5. Repeat regularly after major architecture changes.

## Failback Planning Reality

Failback is often more complex than failover because:
- Primary-site dependencies may have changed during outage.
- Data reconciliation and timing decisions are required.
- Application maintenance windows may be needed.

Documenting failback prerequisites prevents prolonged split-site operations.

## Deep Dive Use Cases: Migration, DR, and Continuity

### Use case 1: Regional disaster recovery for tiered applications

Scenario:
- Multi-tier application (web, app, data) runs in primary region.
- Business requires continuity if region becomes unavailable.

ASR pattern:
1. Replicate dependent workloads to paired/target region.
2. Build recovery plan with dependency-aware boot order.
3. Run regular isolated test failovers.
4. Execute unplanned failover during actual outage.
5. Perform controlled failback after primary recovery.

Why this works:
- Reduces recovery time compared to manual rebuild.
- Provides orchestrated failover sequence across tiers.

### Use case 2: Planned failover for migration/cutover

Scenario:
- Organization is moving workloads from one site/region to another.

ASR usage:
- Planned failover can support controlled cutover with reduced disruption.
- Useful for datacenter exit or regional relocation projects.

Important distinction:
- ASR can support migration-style cutovers, but it is a DR platform.
- For discovery/assessment and broader migration planning, teams typically also use migration tooling and governance processes.

### Use case 3: DR drills and audit evidence

Scenario:
- Regulated organization must prove recoverability.

ASR pattern:
- Execute scheduled test failovers.
- Capture achieved RTO/RPO and validation evidence.
- Record issues and remediation actions in change process.

Operational value:
- Converts DR from policy document to measurable capability.

### Use case 4: Azure Files and DR considerations

Scenario:
- Workloads depend on Azure Files shares.

Design guidance:
- Protect file data with Azure Backup and storage resilience controls.
- Validate application dependency on file share availability during DR tests.
- Ensure DNS/network paths to file endpoints are included in recovery plan.

Professional note:
- ASR primarily orchestrates compute/workload failover.
- Data-layer services such as file shares require their own resilience and backup strategy.

## ASR Decision Guide: Migration vs DR vs Backup

| Need | Best-fit control | Why |
|---|---|---|
| Keep workload running during major outage | ASR | Orchestrated replication and failover |
| Recover historical point-in-time data | Azure Backup | Recovery points and restore workflows |
| Perform controlled site/region cutover | Planned failover (ASR) + migration governance | Operationally coordinated move with rollback planning |
| Protect file-share data used by apps | Azure Files backup + storage resilience | ASR does not replace file-data protection strategy |

## Dedicated End-to-End Scenarios

### Scenario A: Regional outage DR activation for three-tier application

Objective:
- Restore service availability during primary-region outage.

Environment:
- Web, app, and integration VMs replicated with ASR.
- Recovery plan defines dependency boot order.

Execution flow:
1. Detect outage and declare DR event.
2. Trigger unplanned failover using latest suitable recovery point.
3. Bring up tiers in dependency order (identity/integration -> app -> web).
4. Validate app transactions, authentication, and external dependencies.
5. Operate in DR region until primary is stable.

Validation metrics:
- Achieved RTO versus target.
- Data recency versus RPO expectation.
- Incident timeline and communication quality.

### Scenario B: Planned failover for datacenter exit migration

Objective:
- Perform controlled relocation with minimal business disruption.

Environment:
- Workloads currently hosted in legacy site/region.
- Target region prepared and validated.

Execution flow:
1. Schedule migration window and freeze non-essential changes.
2. Run planned failover sequence via ASR.
3. Execute functional tests in target region.
4. Update DNS/traffic paths and hand over to operations.
5. Keep rollback and failback decision gates documented.

Why this scenario matters:
- Shows how ASR can support migration-style cutovers while preserving DR discipline.

### Scenario C: DR test for app depending on Azure Files

Objective:
- Prove continuity for compute plus file-share dependencies.

Environment:
- Application VMs protected by ASR.
- Azure Files used for shared runtime content and user documents.

Execution flow:
1. Run isolated test failover for app VMs.
2. Validate DNS/network access to Azure Files endpoints.
3. Confirm read/write behavior, permissions, and app startup dependency checks.
4. Document data protection boundary: ASR for compute continuity, backup for file data restore.

Key lesson:
- DR success requires testing application dependencies, not only VM startup status.

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
