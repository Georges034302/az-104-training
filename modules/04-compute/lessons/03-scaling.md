# Scaling in Azure: VM Scale Sets and App Service Plans

## Overview

Scaling is the ability to adapt compute capacity to demand while balancing performance, reliability, and cost. AZ-104 focuses on horizontal and vertical scale patterns, VM Scale Sets autoscaling, and App Service plan scaling behavior.

---

## What You Will Learn

- Difference between scale out and scale up
- VM Scale Sets architecture and autoscale model
- App Service plan scaling and operational impact
- Rule design, cooldown strategy, and cost guardrails

---

## Architecture View

```
 [Workload Demand]
      |
      v
 [Metrics + Schedules]
      |
      v
 [Autoscale Rules]
   |             |
   v             v
 [Scale Out]   [Scale In]
      \         /
       v       v
   [Compute Capacity]
       |            |
       v            v
    [VMSS]   [App Service Plan]
```

---

## Core Concepts

- **Scale out/in (horizontal)**: Increase or decrease instance count.
- **Scale up/down (vertical)**: Change instance size/tier.
- **Autoscale**: Rule-driven capacity changes based on metrics, schedules, or both.

Scaling decisions should be based on measurable bottlenecks and expected traffic shape, not only on average CPU.

---

## VM Scale Sets (VMSS)

VMSS provides managed orchestration for a set of similar VM instances.

Key ideas:

- instance-based elastic compute model
- supports autoscale policies
- designed for consistent, repeatable instance configuration

Practical guidance:

- define minimum, default, and maximum instance boundaries
- combine utilization metrics with realistic cooldown windows
- validate health and scaling outcomes after policy changes

Advanced operational note: VMSS orchestration and upgrade behavior influence how safely instances roll during model changes; review mode choice before production deployment.

---

## App Service Plan Scaling

App Service scaling is applied at the **App Service Plan**, not to an individual web app in isolation.

- **Scale up**: Move plan to larger pricing tier/instance size.
- **Scale out**: Increase instance count in the plan.

Design implication: multiple apps in one plan can be affected by plan-level scaling decisions.

Scale precision:

- scale-up operations can trigger restarts/recycling behavior
- autoscale capabilities depend on plan tier support

---

## Autoscale Rule Design

A robust autoscale policy usually includes:

1. scale-out trigger threshold
2. scale-in trigger threshold
3. cooldown period to prevent oscillation
4. max-capacity protection for cost control
5. schedule-based overrides for predictable demand windows

Use asymmetric thresholds where appropriate so scale-out and scale-in do not fight each other.

Autoscale behavior is evaluation-based, not instantaneous at exact threshold crossing; expect short control-loop delay.

---

## Operational Guidance

- Track autoscale action history and correlate with workload metrics.
- Start with conservative bounds, then tune after observing production behavior.
- Validate whether bottleneck is compute, storage, network, or external dependency before scaling.
- Use budgets and alerts alongside autoscale to prevent unexpected cost growth.

---

## Common Pitfalls and Exam Traps

- Confusing scale out with scale up in scenario questions.
- Configuring narrow thresholds that cause frequent scale flapping.
- Setting high max instance count without financial guardrails.
- Assuming app-level scaling in App Service when the plan is the actual scaling unit.
- Using autoscale assumptions on plan tiers that do not support full autoscale behavior.

---

## Quick CLI Reference

```bash
# Create VM scale set (example)
az vmss create \
  --resource-group <rg> \
  --name <vmss-name> \
  --image Ubuntu2204 \
  --instance-count 2 \
  --upgrade-policy-mode automatic

# Create autoscale settings
az monitor autoscale create \
  --resource-group <rg> \
  --resource <vmss-name> \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name <autoscale-name> \
  --min-count 2 \
  --max-count 6 \
  --count 2

# Scale App Service plan out
az appservice plan update \
  --resource-group <rg> \
  --name <plan-name> \
  --number-of-workers 3
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview
- https://learn.microsoft.com/en-us/azure/azure-monitor/autoscale/autoscale-overview
- https://learn.microsoft.com/en-us/azure/app-service/manage-scale-up
