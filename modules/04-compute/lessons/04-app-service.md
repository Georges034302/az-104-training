# Azure App Service: Web Apps, Configuration, and Deployment Slots

## Overview

Azure App Service is a fully managed platform for hosting web apps and APIs without managing virtual machines directly. AZ-104 expects administrators to understand runtime hosting, plan-based scaling, application configuration, and safe deployment operations.

---

## What You Will Learn

- App Service resource model (app, plan, slot)
- Runtime and configuration management patterns
- Deployment slot behavior and swap strategy
- Security, networking, and diagnostics essentials

---

## Architecture View

```
 [Clients]
    |
    v
 [App Service App]
    |
    +--> [Production Slot]
    +--> [Staging Slot]
             |
             v
          [Swap]
    |
    v
 [App Service Plan (Compute)]
```

---

## Core Concepts

- **App Service app**: Logical web/API application resource.
- **App Service Plan**: Compute boundary for one or more apps.
- **Deployment slots**: Additional app instances (for example staging) with swap capability.
- **App settings**: Configuration values exposed to app runtime as environment variables.
- **Connection strings**: Structured configuration entries for data dependencies.

Key operational point: scaling and pricing are primarily tied to the App Service Plan.

---

## Plan Tier and Feature Awareness

- App Service capabilities differ by plan tier.
- Features such as deployment slots and autoscale depend on supported plan levels.
- Consolidating multiple apps into one plan can reduce cost, but noisy-neighbor effects and scaling coupling must be considered.

---

## Configuration and Secrets

- Keep environment-specific values in app settings, not in source code.
- Use slot settings for values that must stay with a specific slot during swap.
- For sensitive values, use managed identity and secure secret stores when possible.

Design implication: configuration strategy is part of deployment safety, not only an app developer concern.

---

## Deployment Slots and Swap

Typical safe deployment flow:

1. deploy new version to staging slot
2. validate functionality and health
3. swap staging with production
4. monitor post-swap behavior

Slot behavior to remember:

- some settings can be marked as slot-specific
- swap moves content and most non-slot-specific configuration between slots

Incorrect slot-setting decisions are a common root cause of post-swap incidents.

Operational precision: Always validate slot-specific settings before swap, especially connection endpoints, secrets, and environment identifiers.

---

## Networking and Access Controls

Common App Service networking controls include:

- access restrictions for inbound filtering
- private endpoint patterns for private inbound exposure
- VNet integration for outbound access to private network dependencies

Important: inbound private endpoint and outbound VNet integration solve different traffic directions.

Common design correction: outbound VNet integration does not make inbound access private by itself.

---

## Observability and Reliability Practices

- Enable logs and metrics to monitor deployment and runtime behavior.
- Use health checks to improve resilience during instance restarts and upgrades.
- Track response time, error rate, and dependency failures after release operations.

Administrators should verify operational visibility before production release, not after issues occur.

---

## Common Pitfalls and Exam Traps

- Editing configuration in wrong slot and causing production drift.
- Forgetting to mark slot-specific settings before swap.
- Treating web app and plan as independent scaling boundaries.
- Assuming App Service networking settings are equivalent to VM networking constructs.
- Assuming swap safety without verifying slot-specific configuration boundaries.

---

## Quick CLI Reference

```bash
# Create App Service plan
az appservice plan create \
  --resource-group <rg> \
  --name <plan-name> \
  --sku P1v3 \
  --is-linux

# Create web app
az webapp create \
  --resource-group <rg> \
  --plan <plan-name> \
  --name <app-name>

# Create staging slot
az webapp deployment slot create \
  --resource-group <rg> \
  --name <app-name> \
  --slot staging

# Swap staging to production
az webapp deployment slot swap \
  --resource-group <rg> \
  --name <app-name> \
  --slot staging \
  --target-slot production
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/app-service/overview
- https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots
- https://learn.microsoft.com/en-us/azure/app-service/configure-common
