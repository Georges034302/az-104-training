# Azure App Service: Web Apps, Configuration, Deployment Slots, and Networking

> Azure App Service is a fully managed platform for hosting **web apps, APIs, and background web workloads** without managing VMs directly. For AZ-104, administrators must understand the **app**, the **plan**, the **slot model**, and how configuration and networking affect safe operations.

---

## Overview

App Service reduces infrastructure management, but it still requires strong administration for:

- plan and pricing tier selection
- application configuration and secrets
- scaling and deployment safety
- networking and access restrictions
- monitoring and troubleshooting

The core advantage is that Microsoft manages the underlying platform while you manage the app’s configuration, identity, release flow, and runtime behavior.

---

## What You Will Learn

- The App Service resource model: app, plan, and slot
- How scaling and pricing relate to the App Service Plan
- How to manage app settings and secrets safely
- How deployment slots and swap operations reduce release risk
- How App Service networking and diagnostics work in practice

---

## App Service Mental Model

```text
[Clients]
    |
    v
[Web App / API App]
    |
    +--> [Production slot]
    +--> [Staging slot]
             |
             v
          [Swap]
    |
    v
[App Service Plan (compute boundary)]
```

---

## Core Concepts

| Component | Purpose | Key note |
|---|---|---|
| **Web App / API App** | The application resource | Hosts the site or API runtime |
| **App Service Plan** | Compute boundary | Controls region, pricing tier, and scaling |
| **Deployment slot** | Staging or pre-production instance | Used for safer releases and swap workflows |
| **App settings** | Environment variables for runtime config | Best place for environment-specific config |
| **Connection strings** | Structured app configuration entries | Often used for database or service dependencies |
| **Managed identity** | App authentication to Azure services | Avoids storing secrets in app config |

### Critical operating rule
**Scaling and pricing are tied primarily to the App Service Plan**, not just to the app itself.

---

## Plan Tiers and Feature Awareness

App Service capabilities vary by plan tier.

Examples of feature differences include:

- autoscale support
- deployment slot availability
- networking features
- performance and instance scale limits

### Practical planning note
Putting multiple apps into one plan can reduce cost, but those apps also share the same compute resources. That can create noisy-neighbor behavior and shared scaling impact.

---

## Configuration and Secrets

Good App Service administration keeps environment-specific values **out of source code**.

### Best practice approach

- use **app settings** for configuration values
- mark sensitive or slot-specific values appropriately
- use **managed identity** and secure secret stores when possible

### Slot settings
Some settings should stay with a specific slot during swap. These are often called **slot settings**.

This matters for:

- database endpoints
- connection strings
- API keys
- environment identifiers

Bad slot-setting decisions are a common cause of production deployment incidents.

---

## Deployment Slots and Swap Strategy

Deployment slots let you test a new version before moving it into production.

### Typical safe release flow

1. deploy the new version to the **staging** slot
2. validate health, configuration, and connectivity
3. swap **staging** with **production**
4. monitor after swap and roll back if needed

### Important behavior

- the content is swapped between slots
- many settings move with the app unless marked as **slot-specific**
- slot support depends on the plan tier (commonly **Standard and above**)

---

## Networking and Access Controls

Common App Service networking controls include:

- **access restrictions** for inbound filtering
- **private endpoints** for private inbound access
- **VNet integration** for outbound access to private dependencies

### Critical distinction

| Feature | Direction solved |
|---|---|
| **Private endpoint** | Private **inbound** access to the app |
| **VNet integration** | Private **outbound** access from the app to other resources |

> Outbound VNet integration does **not** make the app privately accessible from inbound traffic by itself.

---

## Observability and Reliability Practices

A production App Service deployment should include:

- logs and metrics enabled
- health checks configured where supported
- monitoring for response time, error rate, and dependency failures
- post-deployment validation after every release or swap

You should verify visibility **before** production issues happen.

---

## Example Scenarios

### 1. Public web app with safe release process

- deploy the app to an App Service Plan
- use a **staging slot** for validation
- swap after confirming health and configuration

### 2. Internal API needing private outbound access to a database

- use **VNet integration** for outbound connectivity
- use app settings or managed identity for configuration and authentication

### 3. Security-sensitive app

- use access restrictions or private endpoint patterns
- avoid storing secrets directly in code or plain config files

---

## CLI Reference

### Create an App Service plan

```bash
az appservice plan create \
  --resource-group <rg> \
  --name <plan-name> \
  --sku P1v3 \
  --is-linux
```

### Create a web app

```bash
az webapp create \
  --resource-group <rg> \
  --plan <plan-name> \
  --name <app-name> \
  --runtime "PYTHON:3.11"
```

### Create a staging slot

```bash
az webapp deployment slot create \
  --resource-group <rg> \
  --name <app-name> \
  --slot staging
```

### Swap staging with production

```bash
az webapp deployment slot swap \
  --resource-group <rg> \
  --name <app-name> \
  --slot staging \
  --target-slot production
```

---

## Best Practices

1. Treat the **App Service Plan** as the real compute and scaling boundary.
2. Keep configuration in **app settings**, not in source code.
3. Use **deployment slots** for safer releases where the tier supports them.
4. Validate slot-specific settings before every swap.
5. Separate **private inbound** and **private outbound** networking requirements clearly.

---

## Troubleshooting Checklist

If an App Service deployment is failing or behaving unexpectedly:

1. Confirm the app is on the expected **plan** and **tier**.
2. Check app settings, connection strings, and slot-specific configuration.
3. Review deployment slot behavior if a swap recently happened.
4. Verify whether the networking issue is **inbound** or **outbound**.
5. Check logs, metrics, and health status before changing multiple settings at once.

---

## Common Pitfalls

- Editing configuration in the wrong slot and causing production drift.
- Forgetting to mark slot-specific settings before swap.
- Treating the app and plan as separate scaling boundaries.
- Assuming App Service networking behaves the same as VM networking.
- Expecting VNet integration alone to make inbound access private.

---

## Key Takeaways

- App Service is a managed web hosting platform, but it still requires disciplined administration.
- The **plan** controls the compute boundary, scale, and many features.
- **Deployment slots** are one of the safest ways to reduce release risk.
- Good App Service operations depend on **configuration discipline, secure networking, and monitoring**.

---

## Advanced: Application Platform Operations

### Configuration and Secret Hygiene

- Separate code from configuration across environments
- Store secrets in managed secret stores and reference securely
- Enforce configuration drift detection and approval workflows

### Deployment Safety

- Use slots for staged validation before production swap
- Define warm-up and health validation steps pre-swap
- Keep clear rollback criteria and fast rollback path

### Network and Security Controls

- Restrict ingress with access restrictions/private endpoints as needed
- Integrate managed identity for outbound service authentication
- Monitor TLS, certificate, and auth configuration continuously

## Extended Troubleshooting Matrix (App Service)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| App starts but fails on requests | Missing app settings or secret resolution | Review app configuration and startup logs | Correct settings and secret references |
| Slot swap causes outage | Slot configuration mismatch | Compare sticky settings and dependencies | Align slot settings and retry controlled swap |
| Intermittent 5xx responses | Instance saturation or dependency timeout | Inspect app metrics and dependency telemetry | Scale plan and optimize dependency handling |
| Access restrictions block valid users | Rule precedence or CIDR mismatch | Validate inbound rule order and client IP path | Correct allow rules and test access |

## Production Readiness Checklist (App Service)

- Slot-based deployment strategy implemented and tested
- Secret and config management standardized
- Managed identity used for service-to-service authentication
- Scaling and health monitoring configured for application SLOs
- Backup and rollback procedures validated
- Security controls and access restrictions reviewed periodically


---

## Further Reading

- [Azure App Service overview](https://learn.microsoft.com/en-us/azure/app-service/overview)
- [Set up staging environments in App Service](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots)
- [Configure an App Service app](https://learn.microsoft.com/en-us/azure/app-service/configure-common)
- [App Service networking features](https://learn.microsoft.com/en-us/azure/app-service/networking-features)
