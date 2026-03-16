# Log Analytics and KQL for Operations

## Overview

Log Analytics is the Azure Monitor data platform for centralized log investigation. Kusto Query Language (KQL) is used to search, filter, aggregate, and correlate telemetry for operational analysis.

AZ-104 does not require deep data engineering patterns, but it does require reliable operational query skills.

---

## What You Will Learn

- Workspace and table model fundamentals
- KQL pipeline basics for investigation
- Common operational tables and scenarios
- Time-range and ingestion considerations
- Query quality and troubleshooting practices

---

## Architecture View

```
 [Resources + Agents + Services]
        |
        v
 [Log Analytics Workspace]
        |
        +--> [Tables]
        |      |
        |      +--> [Heartbeat]
        |      +--> [InsightsMetrics/Perf]
        |      +--> [AzureActivity*]
        |
        v
    [KQL Query Pipeline]
        |
        v
 [Results -> Alerts -> Workbooks]
```

\* `AzureActivity` availability depends on how subscription activity logs are routed to the workspace.

---

## Workspace and Table Model

- A **workspace** stores collected logs in structured tables.
- Each table has its own schema and ingestion pattern.
- Most operational analysis starts with:
  - TimeGenerated filtering
  - scope filtering (resource, computer, operation)
  - summarization for trend and anomaly detection

Key point: You must query the correct workspace and relevant table for meaningful results.

---

## Collection Path Precision

- VM guest telemetry is typically collected with AMA + DCR and then lands in workspace tables.
- Platform resource logs are commonly sent through diagnostic settings.
- Activity log data appears only when connected to the selected workspace path.

Operational rule: If a table is empty, validate collection path before assuming "no events".

---

## KQL Fundamentals for Administrators

Common operators in operational workflows:

- `where` for filtering
- `project` for selecting useful columns
- `summarize` for aggregation
- `order by` for prioritization and chronology
- `join` for cross-table correlation when needed

KQL pipeline is left-to-right. Keep filtering early to reduce noise and improve query performance.

---

## Operational Query Patterns

1. **Agent health**:
  - Use Heartbeat to identify stale or missing agents.
2. **Performance trends**:
  - Use Perf and/or platform metrics depending on monitoring configuration.
3. **Control-plane event review**:
  - Use AzureActivity for administrative operations.
4. **Incident correlation**:
  - Correlate timestamps across tables to align symptoms and changes.

---

## Time and Ingestion Precision

- Always define explicit time windows in queries.
- Newly enabled data sources may show delay before first useful records.
- For incident analysis, compare both short and wider windows to avoid false conclusions.

Design principle: Time scope is part of query correctness, not just convenience.

---

## Common Pitfalls and Exam Traps

- Querying the wrong workspace.
- Forgetting TimeGenerated filter in noisy tables.
- Misreading no-result output as system healthy without validating ingestion path.
- Assuming every subscription event automatically appears in `AzureActivity` in every workspace.
- Overusing wide time ranges for real-time troubleshooting.
- Assuming all VM telemetry appears without proper monitoring configuration.

---

## Quick KQL Examples

```kusto
// Heartbeat in last 30 minutes
Heartbeat
| where TimeGenerated > ago(30m)
| summarize LastSeen=max(TimeGenerated) by Computer
| order by LastSeen desc

// Activity operations by caller in last 24h
AzureActivity
| where TimeGenerated > ago(24h)
| summarize Ops=count() by Caller
| order by Ops desc
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-query-overview
- https://learn.microsoft.com/en-us/azure/azure-monitor/logs/get-started-queries
- https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/heartbeat
