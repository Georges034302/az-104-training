# Azure Alerts and Action Groups

> Azure alerting turns monitoring signals into **operational response**. For AZ-104, the critical skill is choosing the right alert type, setting the correct scope, and routing it to a dependable action path.

---

## Overview

Monitoring without alerting is passive. Alerting without ownership is noise.

A good Azure alerting design answers three questions:

1. **What signal matters?**
2. **When should it be considered a real issue?**
3. **Who or what should respond?**

Azure answers this through **alert rules** and **Action Groups**.

---

## What You Will Learn

- The main alert rule types and when to use each
- How Action Groups route notifications and automation
- How to set thresholds, severity, and suppression carefully
- How to reduce alert fatigue and false positives
- Common exam traps and real-world misconfigurations

---

## Alerting Mental Model

```text
[Signal source]
   |       |       |
   v       v       v
[Metric] [Log] [Activity event]
   |       |       |
   +-------|-------+
           v
      [Alert rule]
           |
           v
      [Action Group]
        |      |       |
        v      v       v
     [Email] [SMS] [Webhook / Automation]
```

---

## Alert Rule Types

### 1. Metric alert

Best for:

- numeric thresholds
- near-real-time conditions
- service health saturation patterns

Examples:

- CPU percentage too high
- latency too high
- availability too low

### 2. Log alert

Best for:

- KQL-based detection logic
- correlation across logs
- pattern-based operational checks

Examples:

- no heartbeat from a VM for 15 minutes
- repeated failed sign-in events
- error pattern found in resource logs

### 3. Activity Log alert

Best for:

- control-plane change detection
- governance and security-sensitive operations
- service health or resource health events

Examples:

- resource deletion
- role assignment changes
- service health incidents in a subscription

> Choosing the wrong alert type often leads to delayed, noisy, or incomplete monitoring behavior.

---

## Action Groups

An **Action Group** defines what happens when an alert fires.

### Common action types

- email or SMS notifications
- push notification
- webhook integration
- automation or remediation workflows
- ITSM or ticketing integration

### Design principle
Keep Action Groups:

- **reusable**
- **environment-aware** (production vs non-production)
- aligned to **clear ownership**

An alert that fires but reaches nobody useful has almost no operational value.

---

## Alert Design Guidance

A good alert design should:

1. start from a business or service risk
2. choose the correct signal type
3. use consistent severity levels
4. avoid thresholds that are too sensitive
5. be reviewed and tuned after real observation

### Good threshold example

- CPU > `80%` for 10 minutes → fire alert
- CPU must stay low for a longer window before resolving or scaling back

This helps avoid “flapping” or alert storms from short spikes.

---

## Noise Reduction and Signal Quality

Too many alerts create alert fatigue.

### Good practices for signal quality

- alert on meaningful symptoms, not every minor fluctuation
- use evaluation windows and suppression thoughtfully
- reuse severity standards across teams
- periodically disable or tune alerts that do not help operations

The goal is **actionable signal**, not maximum volume.

---

## Example Scenarios

### 1. VM CPU saturation

Use a **metric alert** because CPU is a numeric, near-real-time signal.

### 2. Missing VM agent heartbeat

Use a **log alert** over `Heartbeat` data in Log Analytics.

### 3. Resource group deletion or role assignment change

Use an **Activity Log alert** because it is a subscription-level control-plane event.

---

## CLI Reference

### Create an Action Group

```bash
az monitor action-group create \
  --resource-group <rg> \
  --name <ag-name> \
  --short-name <short>
```

### List metric alert rules in a resource group

```bash
az monitor metrics alert list \
  --resource-group <rg> \
  -o table
```

---

## Best Practices

1. Start from **risk and ownership**, not from “every available metric.”
2. Use **severity levels** consistently.
3. Make Action Groups reusable and environment-specific where needed.
4. Validate end-to-end notification delivery after creation.
5. Tune thresholds after observing real workload behavior.

---

## Troubleshooting Checklist

If alerts are too noisy, silent, or unreliable:

1. confirm the **correct alert type** was chosen
2. check the rule **scope** and evaluation settings
3. verify the threshold and time window match the workload baseline
4. test whether the **Action Group** actually delivers notifications
5. review alert history to tune or remove low-value rules

---

## Common Pitfalls

- Confusing metric alerts with KQL-based log alerts.
- Assuming one alert type fits every monitoring scenario.
- Creating rules without useful Action Groups.
- Scoping the rule to the wrong resource or subscription.
- Treating alert creation as finished without tuning after observation.

---

## Key Takeaways

- Alerts turn monitoring data into **response**.
- The correct alert type depends on whether the signal is a **metric**, **log pattern**, or **control-plane event**.
- Action Groups are the link between alert detection and real operational action.
- Good alerting is defined by **accuracy, ownership, and low noise**.

---

## Advanced: Alerting Strategy and Response Engineering

### Alert Fidelity

- Alert on symptoms that matter to users and service objectives
- Use dynamic thresholds where workload baselines vary
- Include context fields that speed triage decisions

### Routing and Escalation

- Align action groups to support ownership boundaries
- Use severity-based channels and escalation timelines
- Validate on-call coverage and redundancy

### Noise Governance

- Suppress duplicate and low-value alerts
- Implement maintenance windows and alert processing rules
- Review alert quality metrics regularly

## Extended Troubleshooting Matrix (Alerts and Action Groups)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Alert not firing | Rule scope or condition mismatch | Check evaluated resources and criteria | Correct scope and thresholds |
| Alert floods team | Threshold too sensitive or no suppression | Analyze alert frequency and context | Tune thresholds and add suppression rules |
| Notifications not delivered | Action group endpoint failure | Validate action history and endpoint health | Fix receiver config and retry path |
| Slow response to critical incidents | Missing escalation workflow | Review incident timeline and routing | Implement escalation and ownership mapping |

## Production Readiness Checklist (Alerts and Action Groups)

- Alert inventory mapped to service criticality
- Action groups validated for all severity levels
- Alert noise reduction controls in place
- Test alerts executed and response verified
- Escalation paths documented and rehearsed
- Periodic alert quality review process active


---

## Further Reading

- [Azure Monitor alerts overview](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview)
- [Action Groups in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups)
- [Types of Azure Monitor alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-types)
- [Create and manage alert rules](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-create-new-alert-rule)
