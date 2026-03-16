# Containers on Azure: ACR, ACI, and ACA

## Overview

Azure provides multiple container services with different operational models. AZ-104 focuses on understanding what each service does, how images are stored and pulled securely, and which runtime fits a given requirement.

---

## What You Will Learn

- Role of Azure Container Registry (ACR)
- Runtime differences between Azure Container Instances (ACI) and Azure Container Apps (ACA)
- Authentication and authorization flow for image pulls
- Practical service selection guidance for AZ-104-level scenarios

---

## Architecture View

```
 [Source Code]
      |
      v
 [Container Image Build]
      |
      v
 [Azure Container Registry]
      |                |
      v                v
 [Azure Container Instances]   [Azure Container Apps]
```

---

## Core Concepts

- **ACR**: Private registry for storing and managing container images.
- **ACI**: Serverless container runtime for straightforward, on-demand container execution.
- **ACA**: Managed container application platform with revision model and built-in scaling behavior.

Key point: ACR is image storage; ACI/ACA are execution environments.

---

## Azure Container Registry (ACR)

Operational topics:

- registry naming and login server format
- repositories, tags, and image version discipline
- image pull authentication using roles and identities

Security guidance:

- prefer role-based pull access (`AcrPull`) over broad registry admin usage in production
- maintain clear image tag strategy to avoid deploying ambiguous versions

Operational nuance: ACR admin user credentials are useful for simple labs, but production workflows should prefer identity-based pull authorization.

---

## Azure Container Instances (ACI)

ACI characteristics:

- quick container startup without VM management
- suitable for simple jobs, burst workloads, and isolated runtime tasks
- container group model for one or more containers sharing lifecycle/network context

Practical limitations to remember in planning:

- not a full microservices platform
- scaling and traffic routing behavior is simpler than app platforms

---

## Azure Container Apps (ACA)

ACA characteristics:

- managed app platform for containerized services
- revision-based deployment model
- built-in scaling capabilities (including HTTP and event-driven patterns)

Design implication: ACA is often the better fit for modern app workloads that need managed scaling and app-level deployment control.

Operational nuance: If images are private in ACR, ACA deployment must include registry configuration (server and identity/credentials) in addition to the image reference.

---

## Choosing Between ACI and ACA

Choose **ACI** when:

- you need fast, simple container execution
- workload is short-lived or operationally straightforward
- advanced app platform features are not required

Choose **ACA** when:

- workload needs managed scale behavior and revision-driven releases
- app-level ingress and modern runtime controls are required
- you want platform-managed container app operations without Kubernetes cluster management

---

## Identity and Access for Image Pulls

Typical secure flow:

1. image stored in ACR
2. runtime identity or principal granted pull permissions
3. service pulls image from ACR login server

Operational checks:

- registry name/login server correctness
- role assignment scope and propagation
- image tag existence
- runtime identity or credentials actually configured on the target service

---

## Common Pitfalls and Exam Traps

- Treating ACR as a runtime service rather than image registry.
- Using weak tag hygiene (for example always deploying `latest` without release control).
- Confusing ACI and ACA capabilities in scenario selection questions.
- Assuming pull failures are runtime bugs when permissions or login server naming is wrong.
- Using invalid naming conventions for registry resources.
- Referencing a private ACR image in ACA/ACI without configuring registry authentication.

---

## Quick CLI Reference

```bash
# Create ACR
az acr create \
  --resource-group <rg> \
  --name <acr-name> \
  --sku Standard

# List repositories
az acr repository list \
  --name <acr-name> \
  -o table

# Create ACI container group from ACR image (example)
az container create \
  --resource-group <rg> \
  --name <aci-name> \
  --image <acr-name>.azurecr.io/<repo>:<tag> \
  --cpu 1 --memory 1.5 \
  --registry-login-server <acr-name>.azurecr.io \
  --registry-username <acr-username> \
  --registry-password <acr-password>

# Create ACA app from container image (example)
az containerapp create \
  --resource-group <rg> \
  --name <app-name> \
  --environment <aca-env-name> \
  --image <acr-name>.azurecr.io/<repo>:<tag> \
  --registry-server <acr-name>.azurecr.io \
  --registry-username <acr-username> \
  --registry-password <acr-password> \
  --target-port 80 \
  --ingress external
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro
- https://learn.microsoft.com/en-us/azure/container-instances/container-instances-overview
- https://learn.microsoft.com/en-us/azure/container-apps/overview
