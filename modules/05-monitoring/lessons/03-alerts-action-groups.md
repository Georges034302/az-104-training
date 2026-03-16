# Azure Alerts and Action Groups

## Overview

Azure alerting transforms monitoring data into operational response. In AZ-104, the important concepts are the right alert type for the signal, correct scope, and dependable action routing.

---

## What You Will Learn

- Alert rule types and when to use each
- Action Group design and response routing
- Threshold and suppression strategy
- Signal-to-noise optimization practices
- Common misconfiguration patterns

---

## Architecture View

```
 [Signal Source]
    |      |      |
    v      v      v
 [Metric] [Log] [Activity Event]
    |      |      |
    +------|------+
           v
      [Alert Rule]
           |
           v
      [Action Group]
        |    |    |
        v    v    v
     [Email][SMS][Webhook/Automation]
```

---

## Alert Rule Types

- **Metric alert**:
  - Best for fast threshold detection on numeric signals.
  - Typical examples: CPU high, availability drop, latency threshold.

- **Log alert**:
  - Uses KQL over Log Analytics data.
  - Best for pattern-based and correlation-aware detection.

- **Activity Log alert**:
  - Watches subscription-level control-plane events.
  - Useful for governance and security-sensitive operations.

Important: Choosing the wrong alert type usually creates delayed, noisy, or blind monitoring behavior.

---

## Action Groups

An Action Group defines what happens when an alert fires.

Common receiver patterns:

- human notification channels (email/SMS/push)
- webhook or ITSM integration
- automation paths for remediation workflows

Design principle: Keep Action Groups reusable and environment-aware (for example production vs non-production routing).

---

## Alert Design Guidance

1. Start from service-level risk, not from every available metric.
2. Use severity levels consistently across teams.
3. Apply suppression windows and evaluation settings to reduce storms.
4. Use asymmetric trigger/resolve logic where supported.
5. Review alert history regularly and tune thresholds.

---

## Operational Pitfalls

- Rules without Action Groups.
- Thresholds that are too sensitive for workload baseline.
- Scoping to the wrong resource or subscription.
- Creating many low-value alerts that train operators to ignore incidents.
- Never validating end-to-end notification delivery.

---

## Common Pitfalls and Exam Traps

- Confusing metric alerts with KQL-based log alerts.
- Assuming one alert type fits every monitoring requirement.
- Forgetting to include operational ownership and routing design.
- Treating alert creation as complete without tuning after observation.

---

## Quick CLI Reference

```bash
# Create action group (example)
az monitor action-group create \
  --resource-group <rg> \
  --name <ag-name> \
  --short-name <short>

# List alert rules in a resource group
az monitor metrics alert list \
  --resource-group <rg> \
  -o table
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview
- https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups
- https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-types
