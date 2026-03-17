# Module 05 — Monitoring & Backup

> **Focus**: Azure Monitor observability, operational alerting, backup recoverability, and resilience planning

This module covers end-to-end monitoring and resilience operations for AZ-104: telemetry flow, KQL investigation, alert response wiring, backup validation, and DR design reasoning.

## Module Standards

- Lessons include operational guidance and exam-relevant pitfalls.
- CLI + ARM labs are parameterized with `.env`, use reusable variables, and include explicit validation and cleanup.
- Portal labs are written as detailed step-by-step procedures, not high-level summaries.

## 📖 Lessons

1. **[Azure Monitor Foundations](lessons/01-azure-monitor.md)** - Signal types, routing paths, diagnostics vs DCR collection models, and incident correlation workflow
2. **[Log Analytics & KQL](lessons/02-log-analytics-kql.md)** - Workspace/table model, KQL operator patterns, and data-ingestion precision checks
3. **[Alerts & Action Groups](lessons/03-alerts-action-groups.md)** - Metric/log/activity alert selection, threshold strategy, and response routing patterns
4. **[Azure Backup](lessons/04-azure-backup.md)** - Recovery Services architecture, policy/retention behavior, restore options, and governance controls
5. **[Azure Site Recovery](lessons/05-azure-site-recovery.md)** - Replication and failover lifecycle, failback planning, and DR testing practices
6. **[Availability & Resilience](lessons/06-availability-resilience.md)** - SLA, RTO, RPO, and how to combine HA, backup, and DR for business continuity

## 🧪 Labs

1. **[Enable VM Insights (CLI + ARM)](labs/cli-arm/01-enable-vm-insights.md)** | **[Portal](labs/portal/01-enable-vm-insights.md)** - Build VM + Log Analytics telemetry path, onboard VM Insights, and validate Heartbeat/KQL
2. **[Create Alert & Action Group (CLI + ARM)](labs/cli-arm/02-create-alert-action-group.md)** | **[Portal](labs/portal/02-create-alert-action-group.md)** - Create reusable Action Group and CPU metric alert with full rule/action verification
3. **[Backup & Restore VM (CLI + ARM)](labs/cli-arm/03-backup-and-restore-vm.md)** | **[Portal](labs/portal/03-backup-and-restore-vm.md)** - Enable VM protection in Recovery Services vault and validate restore workflow safely
4. **[Service Health + Resource Health Alerts (CLI + ARM)](labs/cli-arm/04-service-health-resource-health-alerts.md)** | **[Portal](labs/portal/04-service-health-resource-health-alerts.md)** - Build subscription-scope health alerts routed through a shared Action Group

## Learning Outcomes

After completing this module, you will be able to:
- Distinguish and route Azure telemetry correctly across metrics, activity logs, resource logs, and guest telemetry
- Query Log Analytics with practical KQL patterns for operational troubleshooting
- Configure alert rules and Action Groups with clear ownership and low-noise behavior
- Implement backup protection and validate recoverability through restore workflows
- Explain DR planning and resilience trade-offs using SLA, RTO, and RPO inputs
