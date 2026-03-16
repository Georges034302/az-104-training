# Availability and Resilience Strategy in Azure

## Overview

Availability and resilience are architecture outcomes, not single-resource settings. AZ-104 requires clear reasoning about uptime design, recoverability, and risk trade-offs.

---

## What You Will Learn

- SLA interpretation and architectural impact
- RTO and RPO as design inputs
- Relationship between high availability, backup, and disaster recovery
- Region and zone strategy considerations
- Operational validation practices

---

## Architecture View

```
 [Business Requirements]
      |
      +--> [Availability Target / SLA]
      +--> [RTO]
      +--> [RPO]
               |
               v
      [Architecture Decisions]
         |       |        |
         v       v        v
 [HA Design] [Backup] [Disaster Recovery]
         \       |        /
          v      v       v
        [Resilience Outcome]
```

---

## Core Concepts

- **SLA**:
  - Service availability commitment for a given configuration.
  - Higher availability usually requires multi-instance architecture.

- **RTO (Recovery Time Objective)**:
  - Maximum acceptable service restoration time.

- **RPO (Recovery Point Objective)**:
  - Maximum acceptable data loss window.

Key principle: SLA does not replace recovery planning. Availability commitment and recoverability objectives are related but different.

---

## Availability vs Backup vs DR

- **High availability (HA)**:
  - Reduces downtime from localized failures.
  - Usually involves redundancy and health-based traffic handling.

- **Backup**:
  - Protects data for point-in-time recovery.
  - Does not by itself provide immediate service continuity.

- **Disaster recovery (DR)**:
  - Restores service in major outage scenarios, often across regions.
  - Includes replication and failover orchestration design.

Operational rule: Use HA + Backup + DR together according to business impact and risk tolerance.

---

## Region and Zone Strategy

- Availability zones improve datacenter-level resilience within supported regions.
- Multi-region strategy improves recovery options for regional incidents.
- Region pair awareness helps planning for platform-level continuity and data residency constraints.

Design implication: Infrastructure redundancy must be paired with dependency mapping (identity, networking, data services).

---

## Reliability Math (Simple View)

For independent components in series, effective availability is multiplicative:

$$
A_{system} = A_1 \times A_2 \times \dots \times A_n
$$

This explains why architecture and dependency choices strongly affect end-to-end availability.

---

## Operational Validation

1. Test backup restore paths regularly.
2. Run failover simulations where DR is required.
3. Validate monitoring and alert coverage for critical dependencies.
4. Keep runbooks current with ownership and escalation paths.

Resilience is proven by tests and operational readiness, not documentation alone.

---

## Common Pitfalls and Exam Traps

- Assuming single-instance deployments satisfy high availability goals.
- Confusing backup strategy with full DR capability.
- Designing for uptime without testing restore/failover procedures.
- Ignoring dependency failures outside the primary compute tier.
- Treating SLA numbers as guaranteed business continuity outcomes.

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/reliability/overview
- https://learn.microsoft.com/en-us/azure/well-architected/reliability/
- https://learn.microsoft.com/en-us/azure/architecture/guide/design-principles/reliability
