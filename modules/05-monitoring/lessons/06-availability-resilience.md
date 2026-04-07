# Availability and Resilience Strategy in Azure

> Availability and resilience are **architecture outcomes**, not single-resource settings. AZ-104 expects administrators to reason clearly about uptime design, recoverability, and the trade-offs behind resilience decisions.

---

## Overview

Resilience in Azure is built from multiple layers working together:

- high availability design
- backup and restore capability
- disaster recovery planning
- monitoring and validation

The main lesson is simple:

> A service is resilient only when it can **stay available or recover within business expectations**.

---

## What You Will Learn

- How to interpret SLA, RTO, and RPO
- The difference between HA, backup, and DR
- How zones and regions affect resilience strategy
- Why operational validation is essential
- Common AZ-104 planning mistakes to avoid

---

## Resilience Mental Model

```text
[Business requirements]
      |
      +--> [Availability target / SLA]
      +--> [RTO]
      +--> [RPO]
               |
               v
      [Architecture decisions]
         |        |         |
         v        v         v
   [HA design] [Backup] [DR plan]
         \        |         /
          v       v        v
       [Resilience outcome]
```

---

## Core Concepts

### SLA (Service Level Agreement)

An SLA is the vendor’s availability commitment for a service under defined conditions.

Important note:

- the SLA often depends on the way the workload is deployed
- a single-instance design may not meet the same availability target as a redundant design

### RTO (Recovery Time Objective)

The maximum acceptable time to restore service after disruption.

### RPO (Recovery Point Objective)

The maximum acceptable amount of data loss measured in time.

Key principle:

SLA does **not** replace recovery planning. Availability commitment and recoverability objectives are related, but not identical.

---

## High Availability vs Backup vs DR

| Capability | What it helps with | Example |
|---|---|---|
| **High availability (HA)** | Reduces downtime from localized failures | Multiple VMs behind a load balancer |
| **Backup** | Restores prior data state | Recover deleted or corrupted files/VM data |
| **Disaster recovery (DR)** | Restores service after major site or region failure | Failing over to another region |

Operational rule:

Use **HA + Backup + DR** together based on business impact and risk tolerance.

---

## Region and Zone Strategy

### Availability zones

- improve resilience against datacenter-level failure within supported regions
- are useful when you need stronger in-region redundancy

### Multi-region design

- improves options for regional outage recovery
- supports broader business continuity planning

### Design implication

Redundancy must include dependency awareness, such as:

- identity services
- networking paths
- data services
- DNS and application dependencies

---

## Practical Design Questions

When assessing a workload, ask:

1. what happens if a VM fails?
2. what happens if a zone fails?
3. what happens if the whole region fails?
4. can the data be restored if corruption occurs?
5. have these assumptions been tested, not just documented?

These questions drive better architecture decisions than simply enabling isolated features.

---

## Reliability Math (Simple View)

For independent components in series, effective availability is multiplicative:

$$
A_{system} = A_1 \times A_2 \times \dots \times A_n
$$

This explains why a workload’s end-to-end availability is affected by all of its dependencies, not only the main compute service.

---

## Operational Validation

1. test backup restores regularly
2. run failover simulations where DR is required
3. validate monitoring and alert coverage for critical dependencies
4. keep runbooks current with ownership and escalation paths

Resilience is proven by **testing and operational readiness**, not by documentation alone.

---

## Common Pitfalls and Exam Traps

- Assuming single-instance deployments satisfy high availability goals.
- Confusing backup strategy with full DR capability.
- Designing for uptime without testing restore or failover procedures.
- Ignoring dependency failures outside the primary compute tier.
- Treating SLA numbers as guaranteed business continuity outcomes.

---

## Key Takeaways

- Resilience is driven by **business requirements plus architecture choices**.
- **SLA, RTO, and RPO** should shape the design from the start.
- High availability, backup, and DR solve different failure scenarios.
- A resilience plan is credible only when it has been tested.

---

## Further Reading

- [Azure reliability overview](https://learn.microsoft.com/en-us/azure/reliability/overview)
- [Well-Architected reliability guidance](https://learn.microsoft.com/en-us/azure/well-architected/reliability/)
- [Azure reliability design principles](https://learn.microsoft.com/en-us/azure/architecture/guide/design-principles/reliability)
