# Log Analytics and KQL for Operations

> Log Analytics is the Azure Monitor investigation platform for centralized log analysis. **Kusto Query Language (KQL)** is the query language used to search, filter, aggregate, and correlate operational data.

---

## Overview

AZ-104 does not require advanced data engineering, but it does require solid administrator-level query skills. You should be comfortable using KQL to:

- verify whether data is arriving
- investigate service or VM issues
- summarize operational trends
- correlate changes and symptoms across tables

Good KQL use turns raw monitoring data into practical troubleshooting evidence.

---

## What You Will Learn

- How Log Analytics workspaces and tables are organized
- Core KQL operators used in admin workflows
- Common operational tables and query patterns
- Time-range and ingestion considerations
- Common mistakes that lead to misleading query results

## Acronyms and Terms (Do Not Assume)

- KQL = Kusto Query Language
- LA = Log Analytics
- UTC = Coordinated Universal Time
- RBAC = Role-Based Access Control
- SOC = Security Operations Center
- NRT = Near Real-Time

These terms appear frequently in monitoring investigations and runbooks.

---

## Log Analytics Mental Model

```text
[Resources / agents / services]
        |
        v
[Log Analytics workspace]
        |
        +--> [Heartbeat]
        +--> [Perf / InsightsMetrics]
        +--> [AzureActivity]
        +--> [Resource-specific tables]
        |
        v
    [KQL query pipeline]
        |
        v
 [Results -> investigation -> alerts -> workbooks]
```

---

## Workspace and Table Model

A **workspace** stores collected logs in structured tables.

Each table has:

- its own schema
- its own ingestion path
- its own operational meaning

### Common tables administrators should recognize

| Table | Common use |
|---|---|
| **Heartbeat** | Agent health / last-seen monitoring |
| **Perf** / **InsightsMetrics** | Performance trends and counters |
| **AzureActivity** | Control-plane operations and changes |
| **Resource-specific log tables** | Service-specific behaviors and diagnostics |

> Meaningful analysis starts by choosing the **correct workspace and table**.

---

## Collection Path Precision

This is a key operational concept.

- guest telemetry often comes from **AMA + DCR**
- platform resource logs often come from **diagnostic settings**
- `AzureActivity` appears only when the subscription activity path is connected to the workspace correctly

### Important rule
If a table is empty, do **not** assume “nothing happened.” First verify whether the collection path is actually configured.

---

## KQL Fundamentals for Administrators

The KQL pipeline flows **left to right**.

### Core operators you should know

| Operator | Purpose |
|---|---|
| `where` | Filter records |
| `project` | Keep only useful columns |
| `summarize` | Aggregate and count data |
| `order by` | Sort results |
| `join` | Correlate data across tables |
| `extend` | Create calculated columns |
| `take` / `limit` | Quickly preview records |

### Good query habit
Apply **time and scope filters early** to reduce noise and improve performance.

## KQL Query Quality Framework

Use this framework to keep operational queries correct and reusable:

1. **Scope first**: select the right workspace, table, and time window.
2. **Filter early**: reduce scan size with `where` before heavy operations.
3. **Shape output**: use `project` and friendly field names for runbook use.
4. **Summarize for decisions**: aggregate before drilling into raw events.
5. **Correlate deliberately**: use `join` only when timing and keys are validated.

## Advanced KQL Patterns for Operations

### Baseline and anomaly-style view

Use `summarize` and `bin()` to establish trend baseline quickly:

```kusto
Perf
| where TimeGenerated > ago(24h)
| where CounterName == "% Processor Time"
| summarize AvgCPU=avg(CounterValue), P95CPU=percentile(CounterValue,95) by Computer, bin(TimeGenerated, 15m)
| order by TimeGenerated desc
```

### Change-correlation view

Correlate symptoms with recent control-plane changes:

```kusto
let RecentChanges = AzureActivity
| where TimeGenerated > ago(2h)
| project ChangeTime=TimeGenerated, Caller, OperationNameValue, ResourceGroup;

Heartbeat
| where TimeGenerated > ago(2h)
| summarize LastSeen=max(TimeGenerated) by Computer, ResourceGroup
| join kind=leftouter RecentChanges on ResourceGroup
| order by LastSeen asc
```

Professional note:
- Correlation helps generate hypotheses, but operators should validate causation with multiple signals.

---

## Common Operational Query Patterns

### 1. Agent health
Use `Heartbeat` to check whether monitored machines are still reporting.

### 2. Performance trends
Use `Perf` or `InsightsMetrics` when investigating sustained CPU, memory, or disk patterns.

### 3. Administrative change review
Use `AzureActivity` to identify who changed what and when.

### 4. Incident correlation
Use timestamps and, where needed, `join` to connect operational symptoms with recent control-plane changes.

---

## Time and Ingestion Precision

Time scope is part of query correctness.

### Best practice
- always define an explicit time window
- use a short window for fresh incidents
- widen the window if you suspect ingestion delay or missed context

Newly enabled data sources may take time before useful records appear.

---

## KQL Examples

### Heartbeat in the last 30 minutes

```kusto
Heartbeat
| where TimeGenerated > ago(30m)
| summarize LastSeen=max(TimeGenerated) by Computer
| order by LastSeen desc
```

### Activity operations by caller in the last 24 hours

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| summarize Ops=count() by Caller
| order by Ops desc
```

### Recent CPU-style performance trend example

```kusto
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU=avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

---

## Best Practices

1. Query the correct **workspace** first.
2. Always filter by **TimeGenerated** in busy tables.
3. Keep KQL simple and readable for operational reuse.
4. Validate collection paths before concluding that “there are no logs.”
5. Use summarized views first, then drill into raw events.

---

## Troubleshooting Checklist

If KQL results look wrong or empty:

1. Confirm you are in the correct **workspace**.
2. Check the selected **time range**.
3. Confirm the expected table actually receives that data source.
4. Validate DCR or diagnostic settings if ingestion seems missing.
5. Compare short and wide time windows before drawing conclusions.

---

## Common Pitfalls

- Querying the wrong workspace.
- Forgetting a `TimeGenerated` filter in noisy tables.
- Misreading “no results” as proof that the system is healthy.
- Assuming all subscription events automatically appear in every `AzureActivity` table.
- Using overly wide time ranges for near-real-time troubleshooting.
- Assuming VM guest data appears without proper monitoring configuration.

---

## Key Takeaways

- Log Analytics stores monitoring data in **workspaces and tables**.
- KQL is the main Azure admin tool for **searching, filtering, summarizing, and correlating** logs.
- Good troubleshooting depends on choosing the correct **workspace, table, and time range**.
- Empty results often mean **collection or scope issues**, not necessarily “no incident.”

---

## Advanced: Query Engineering for Operations

### Query Reliability

- Use explicit time windows and table filters early
- Parse and project only required fields for performance
- Build reusable query patterns for common incidents

### Data Quality and Schema Discipline

- Normalize field naming and ingestion mappings
- Track schema drift after agent or pipeline changes
- Validate data completeness for critical services

### Operationalization

- Convert high-value queries into workbooks and alerts
- Document expected baselines and anomaly thresholds
- Version-control critical queries used in runbooks

## Extended Troubleshooting Matrix (Log Analytics and KQL)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Query returns no data | Wrong time range or workspace/table mismatch | Validate workspace scope and time filter | Correct query scope and timeframe |
| Query too slow | Excessive scan and late filtering | Review query plan and filter placement | Apply early filters and project narrow fields |
| Alert query inconsistent | Ingestion delay not accounted for | Compare event time vs ingestion time | Adjust lookback and aggregation windows |
| Results differ between teams | Different query versions and assumptions | Compare saved query definitions | Standardize and version shared queries |

## Production Readiness Checklist (Log Analytics and KQL)

- Critical operational queries documented and reviewed
- Query performance tuned for production use
- Ingestion delay handling built into alert logic
- Workbooks and alerts aligned to incident response needs
- Access governance applied to sensitive log tables
- Query library version-controlled and maintained


---

## Further Reading

- [Log query overview in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-query-overview)
- [Get started with KQL queries](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/get-started-queries)
- [Heartbeat table reference](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/heartbeat)
- [Kusto Query Language overview](https://learn.microsoft.com/en-us/kusto/query/)
