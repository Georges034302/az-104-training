# Azure Monitor Foundations: Metrics, Logs, Alerts, and Insights

> Azure Monitor is the core observability platform in Azure. It collects, stores, and correlates telemetry so administrators can **detect issues, investigate root cause, and automate response**.

---

## Overview

In AZ-104, Azure Monitor is a foundational topic because it connects several operational capabilities together:

- platform metrics
- activity and resource logs
- Log Analytics investigation
- alerts and Action Groups
- backup, health, and service visibility

The goal is not just to “collect data,” but to route the right signals to the right place and make them useful during real incidents.

---

## What You Will Learn

- The major Azure Monitor signal types and how they differ
- How telemetry is routed with diagnostic settings and DCRs
- How Log Analytics fits into investigation workflows
- How alerts and insights depend on correct collection design
- Common exam traps and operational mistakes to avoid

---

## Azure Monitor Mental Model

```text
[Azure resource / VM / service]
      |
      +--> [Platform metrics] -------> [Metric alerts]
      |
      +--> [Activity Log] -----------> [Activity log alerts]
      |
      +--> [Resource logs]
                 |
                 v
        [Diagnostic settings / DCRs]
            |        |        |
            v        v        v
   [Log Analytics] [Storage] [Event Hub]
            |
            v
   [KQL queries / Workbooks / Log alerts]
```

---

## Core Signal Types

### 1. Platform metrics

- numeric time-series data
- optimized for fast threshold alerting
- common examples: CPU percentage, transaction count, latency, availability

Best when you need near-real-time operational monitoring.

### 2. Activity Log

- subscription-level **control-plane** events
- records operations such as create, update, delete, policy action, and service health events
- useful for governance, auditing, and change tracking

### 3. Resource logs

- service-specific logs from resource providers
- usually need **diagnostic settings** to send them to destinations
- useful for detailed behavior, access analysis, and troubleshooting

### 4. Guest OS telemetry

- VM-level telemetry collected using **Azure Monitor Agent (AMA)** and **Data Collection Rules (DCRs)**
- used for guest performance counters, events, and other machine-level insights

> Not all telemetry is collected or routed automatically. Configuration matters.

---

## Diagnostic Settings vs DCRs

This distinction is a common AZ-104 point.

| Feature | Used for | Typical scenario |
|---|---|---|
| **Diagnostic settings** | Platform resource logs and export routing | Storage account logs, Key Vault logs, activity exports |
| **Data Collection Rules (DCRs)** | Guest/agent-based data collection via AMA | VM performance counters, Windows events, syslog |

### Simple memory aid

- **PaaS/platform logs** → often **diagnostic settings**
- **VM guest data** → typically **AMA + DCR**

---

## Common Data Destinations

Azure Monitor data is often sent to one or more of these targets:

- **Log Analytics workspace** for KQL investigation and correlation
- **Storage account** for longer-term archival patterns
- **Event Hub** for streaming or integration with external tools

### Operational guidance

1. define a baseline collection pattern for important resource types
2. centralize investigation data in a manageable workspace strategy
3. align retention and cost controls with business and compliance needs

---

## Azure Monitor Insights and Operational Use

Azure Monitor also powers higher-level experiences such as:

- **VM Insights**
- **Workbooks**
- **Application and infrastructure dashboards**
- **Alerting and incident response**

These experiences depend on correct data collection. If the data path is missing, the insight view may look empty or incomplete.

---

## Alert Integration and Response

Azure Monitor supports several alert types:

- **metric alerts** for numeric thresholds
- **log alerts** for KQL-based conditions
- **activity log alerts** for control-plane change events

Those alerts are then connected to **Action Groups** for notifications or automation.

Design principle:

> An alert without clear ownership or an action path is only noise.

---

## Example Operational Workflow

When investigating an incident:

1. check **metrics** for health degradation or saturation
2. review **Activity Log** for recent changes, policy actions, or service events
3. query **resource logs** in Log Analytics for detailed behavior
4. correlate timing across these signals before concluding root cause

This avoids jumping to conclusions based on a single data source.

---

## Azure CLI Examples

### List metric definitions for a resource

```bash
az monitor metrics list-definitions \
  --resource <resource-id> \
  -o table
```

### List diagnostic settings on a resource

```bash
az monitor diagnostic-settings list \
  --resource <resource-id> \
  -o jsonc
```

### Show a Log Analytics workspace

```bash
az monitor log-analytics workspace show \
  --resource-group <rg> \
  --workspace-name <workspace-name> \
  -o table
```

---

## Best Practices

1. Collect only the telemetry that supports an operational purpose.
2. Route important logs to **Log Analytics** for centralized investigation.
3. Standardize diagnostic settings and DCR use across environments.
4. Align retention with cost and compliance expectations.
5. Build alerting around signals that operators can actually act on.

---

## Common Pitfalls and Exam Traps

- Assuming all required logs are collected by default.
- Confusing **diagnostic settings** with **DCR-based guest collection**.
- Treating metrics as a full replacement for detailed logs.
- Building alert rules with no clear action routing.
- Ignoring ingestion delays in some log-based workflows.
- Generating too many low-value alerts and training teams to ignore them.

---

## Key Takeaways

- Azure Monitor combines **metrics, logs, alerts, and investigation tools**.
- Metrics, Activity Log, resource logs, and guest telemetry are different signal types with different purposes.
- Good observability depends on correct **routing**, not just turning monitoring “on.”
- Operational maturity comes from being able to **correlate signals**, not only view them separately.

---

## Further Reading

- [Azure Monitor overview](https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/overview)
- [Azure Monitor metrics data platform](https://learn.microsoft.com/en-us/azure/azure-monitor/platform/data-platform-metrics)
- [Diagnostic settings in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings)
- [Azure Monitor Agent overview](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-overview)
