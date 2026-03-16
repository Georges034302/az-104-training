# Azure Monitor Foundations (Metrics, Logs, Alerts, and Insights)

## Overview

Azure Monitor is the core observability platform in Azure. It collects and correlates telemetry for infrastructure and platform services so administrators can detect issues, investigate root cause, and automate response.

In AZ-104, you are expected to understand where telemetry comes from, where it is stored, and how it is used for alerting and troubleshooting.

---

## What You Will Learn

- Azure Monitor signal types and data flow
- Differences between metrics, activity logs, and resource logs
- Role of Log Analytics workspaces in investigation workflows
- Alert integration with operational response
- Common design and operational mistakes to avoid

---

## Architecture View

```
 [Azure Resource]
      |
      +--> [Platform Metrics] ----> [Metric Alerts]
      |
      +--> [Activity Log] --------> [Activity Log Alerts]
      |
      +--> [Resource Logs]
                 |
                 v
       [Diagnostic Settings]
          |      |      |
          v      v      v
 [Log Analytics] [Storage] [Event Hub]
          |
          v
    [KQL + Workbooks + Log Alerts]
```

---

## Core Signal Types

- **Platform metrics**:
  - Numeric time-series data.
  - Optimized for near-real-time threshold alerting.
  - Typical examples: CPU percentage, transactions, response time.

- **Activity Log**:
  - Subscription-level control-plane events.
  - Useful for auditing operations such as create, update, delete.
  - Commonly used for governance and security change visibility.

- **Resource logs**:
  - Service-specific logs emitted by resource providers.
  - Often need diagnostic settings to route data to destinations.
  - Useful for deeper behavioral and access-level analysis.

- **Guest OS telemetry (VM-level)**:
  - Collected through Azure Monitor Agent (AMA) and Data Collection Rules (DCRs).
  - Separate from platform diagnostic settings used by many PaaS resources.

Important: Not all telemetry appears automatically in one place without configuration.

---

## Data Routing and Storage

- **Diagnostic settings** determine where many platform resource logs and exports are sent.
- **DCRs** determine how guest-level telemetry (for example VM performance/event data through AMA) is collected and routed.
- Common destinations:
  - Log Analytics workspace for query and correlation
  - Storage account for longer-term archival patterns
  - Event Hub for streaming/integration scenarios

Operational guidance:

1. Define a standard diagnostic baseline per resource type.
2. Centralize investigation data in one or few workspaces per operating model.
3. Keep retention and cost controls aligned with compliance and operations needs.

---

## Alerts and Operational Response

Azure Monitor supports multiple alert models:

- **Metric alerts** for threshold-based numeric conditions.
- **Log alerts** for KQL-based conditions over workspace data.
- **Activity log alerts** for control-plane event detection.

Action Groups connect alerts to notifications and automation targets.

Design principle: Alerting is useful only when routed to an action path with clear ownership.

---

## Troubleshooting Workflow

1. Check metric trends for service health and saturation signals.
2. Check Activity Log for recent changes or policy actions.
3. Query resource logs in Log Analytics for detailed behavior.
4. Correlate timing across all signal types before concluding root cause.

This sequence helps avoid single-signal bias during incidents.

---

## Common Pitfalls and Exam Traps

- Assuming all required logs are collected by default.
- Confusing diagnostic settings with DCR-based guest data collection.
- Building alert rules without action routing ownership.
- Treating metrics as a full replacement for detailed logs.
- Ignoring ingestion delay realities for some log scenarios.
- Over-alerting with low-value thresholds that create noise.

---

## Quick CLI Reference

```bash
# List metric definitions for a resource
az monitor metrics list-definitions \
  --resource <resource-id> \
  -o table

# List diagnostic settings for a resource
az monitor diagnostic-settings list \
  --resource <resource-id> \
  -o jsonc

# Show Log Analytics workspace summary
az monitor log-analytics workspace show \
  --resource-group <rg> \
  --workspace-name <workspace-name> \
  -o table
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/overview
- https://learn.microsoft.com/en-us/azure/azure-monitor/platform/data-platform-metrics
- https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings
