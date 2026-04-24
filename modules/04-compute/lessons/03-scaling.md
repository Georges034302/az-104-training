# Scaling in Azure: VM Scale Sets and App Service Plans

> Scaling means adjusting compute capacity to meet demand while balancing **performance, resilience, and cost**. For AZ-104, the key themes are **scale up vs scale out**, **VM Scale Sets**, and **App Service plan scaling**.

---

## Overview

Not every capacity problem should be solved the same way. Azure administrators must know when to:

- increase instance size
- add more instances
- use autoscale rules
- set safe cost limits while preserving service quality

The two most common compute scaling patterns in this module are:

- **Virtual Machine Scale Sets (VMSS)**
- **App Service Plan scaling**

---

## What You Will Learn

- The difference between vertical and horizontal scaling
- When to scale up versus scale out
- How VM Scale Sets are used for elastic VM workloads
- How App Service plans scale and how autoscale rules are tuned safely

---

## Scaling Mental Model

```text
[User demand / workload pressure]
              |
              v
      [Metrics + schedules]
              |
              v
        [Autoscale rules]
           |          |
           v          v
     [Scale out]  [Scale in]
           \          /
            v        v
       [Compute capacity]
          |            |
          v            v
        [VMSS]   [App Service Plan]
```

---

## Core Concepts

| Term | Meaning |
|---|---|
| **Scale up / down** | Change VM size or plan tier |
| **Scale out / in** | Add or remove instances |
| **Autoscale** | Automatic scale actions based on metrics or schedules |

### Simple distinction

- **Vertical scaling** = make one instance bigger or smaller
- **Horizontal scaling** = change the number of running instances

---

## When to Scale Up vs Scale Out

### Scale up / down
Use when:

- the workload is mainly single-instance
- the bottleneck is CPU or memory on one node
- the app does not easily support multiple active instances

### Scale out / in
Use when:

- the workload supports multiple instances
- you want higher resilience as well as higher capacity
- traffic varies over time and benefits from autoscale

> In many production scenarios, **scale out** is preferred because it improves both **capacity** and **availability**.

---

## VM Scale Sets (VMSS)

VM Scale Sets are designed for groups of similar VMs managed as one scalable compute resource.

### Benefits

- consistent VM configuration
- easier horizontal scaling
- built-in autoscale support
- good fit for stateless or load-balanced application tiers

### Typical design pattern

A well-designed VMSS usually includes:

- a **minimum instance count**
- a **default instance count**
- a **maximum instance count**
- health probes and load balancing in front

For exam thinking: VMSS is the main Azure answer when the scenario says **many similar VMs should scale automatically**.

---

## App Service Plan Scaling

App Service scaling happens at the **App Service Plan**, not just the individual app.

### Important rule
If multiple web apps share the same plan:

- they share the same compute workers
- scaling the plan affects **all apps** in that plan

### Two scaling actions

| Action | Meaning |
|---|---|
| **Scale up** | Move to a higher pricing tier or bigger worker size |
| **Scale out** | Increase the number of workers (instances) |

This is a frequent AZ-104 exam point.

---

## Autoscale Rule Design

A good autoscale design normally includes:

1. a **scale-out trigger**
2. a **scale-in trigger**
3. a **cooldown period**
4. minimum and maximum boundaries
5. optional schedule-based rules for predictable peak hours

### Example logic

- if CPU > `70%` for 10 minutes → add 1 instance
- if CPU < `30%` for 20 minutes → remove 1 instance

Using different scale-out and scale-in thresholds reduces **flapping**.

---

## Example Scenarios

### 1. Web application with daytime traffic spikes

Use **App Service autoscale** with schedule-based and CPU-based triggers.

### 2. Stateless API backend on Linux VMs

Use **VM Scale Sets** with autoscale and a load balancer.

### 3. Legacy business app running on one server

You may need to **scale up** instead of out if the app is not multi-instance aware.

---

## Cost and Operations Guidance

Scaling improves performance, but it can raise cost quickly if it is not bounded.

### Good operational habits

- define a clear **maximum instance count**
- review autoscale history and activity logs
- confirm the bottleneck is really compute-related
- avoid using autoscale to mask bad application architecture

Autoscale is evaluation-based, not immediate. There is always a small reaction delay.

---

## CLI Reference

### Create a VM Scale Set

```bash
az vmss create \
  --resource-group <rg> \
  --name web-vmss \
  --image Ubuntu2204 \
  --instance-count 2 \
  --upgrade-policy-mode automatic
```

### Create autoscale settings for VMSS

```bash
az monitor autoscale create \
  --resource-group <rg> \
  --resource web-vmss \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name web-vmss-autoscale \
  --min-count 2 \
  --max-count 6 \
  --count 2
```

### Scale an App Service plan out

```bash
az appservice plan update \
  --resource-group <rg> \
  --name <plan-name> \
  --number-of-workers 3
```

---

## Best Practices

1. Prefer **scale out** for resilient multi-instance workloads when possible.
2. Use **cooldown periods** and asymmetric thresholds to avoid flapping.
3. Set clear **min/max boundaries** for cost control.
4. Validate whether the bottleneck is actually compute before scaling.
5. Remember App Service scaling is tied to the **plan**, not only one app.

---

## Troubleshooting Checklist

If scaling is not behaving as expected:

1. Check whether the resource or pricing tier supports autoscale.
2. Review the autoscale rule conditions and thresholds carefully.
3. Confirm metrics cross the trigger values for long enough to take action.
4. Check activity history for scale actions and failures.
5. Verify the real bottleneck is not storage, database, or network related.

---

## Common Pitfalls

- Confusing **scale out** with **scale up**.
- Assuming App Service scales per app rather than per plan.
- Setting thresholds too close together and causing flapping.
- Forgetting to define a max limit for cost control.
- Expecting autoscale to react instantly at the exact threshold moment.

---

## Key Takeaways

- **Scale up** changes size; **scale out** changes instance count.
- **VMSS** is Azure’s main platform for elastic VM-based horizontal scaling.
- **App Service Plan** is the actual scaling boundary for App Service workloads.
- Good autoscale design balances **performance, resilience, and cost**.

---

## Advanced: Scaling Policy Engineering

### Trigger Design

Autoscale triggers should reflect user experience and system health:

- Combine resource metrics with workload indicators where possible
- Use different thresholds for scale-out and scale-in to prevent oscillation
- Define cooldown periods based on startup characteristics

### Capacity Envelope

- Establish minimum, default, and maximum instance bounds
- Reserve headroom for burst patterns
- Validate regional quota limits before production events

### Economic Efficiency

- Evaluate cost per transaction under scale scenarios
- Use schedule-based scaling for predictable workloads
- Continuously tune rules based on real telemetry

## Extended Troubleshooting Matrix (Scaling)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Autoscale never triggers | Wrong metric namespace or threshold | Review autoscale rule evaluation history | Correct metric and threshold configuration |
| Frequent scale flapping | No hysteresis/cooldown tuning | Analyze rapid in/out events | Increase cooldown and separate thresholds |
| Scale-out occurs but errors persist | Downstream bottleneck unchanged | Trace dependency saturation | Scale dependent tiers or optimize bottleneck |
| Quota blocks scaling | Subscription/regional limits reached | Check quota usage and failed scale actions | Request quota increase and adjust capacity plan |

## Production Readiness Checklist (Scaling)

- Autoscale policy tied to validated performance indicators
- Min/max bounds align to SLA and budget constraints
- Dependency tiers tested under scale conditions
- Quota and capacity planning documented
- Scale event monitoring and alerting enabled
- Post-incident rule tuning process defined


---

## Further Reading

- [Virtual Machine Scale Sets overview](https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview)
- [Autoscale in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/autoscale/autoscale-overview)
- [Scale up an app in Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/manage-scale-up)
- [Scale an app in Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/manage-scale-up#scale-out)
