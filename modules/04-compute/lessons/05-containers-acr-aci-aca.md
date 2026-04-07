# Containers on Azure: ACR, ACI, and ACA

> Azure provides several container services with different operational models. For AZ-104, the main goal is to understand **where images are stored**, **how they are pulled securely**, and **which runtime fits which scenario**.

---

## Overview

Azure container administration usually involves three core services:

- **Azure Container Registry (ACR)** for storing images
- **Azure Container Instances (ACI)** for simple on-demand container execution
- **Azure Container Apps (ACA)** for managed containerized applications with built-in scaling and revisions

The most important conceptual rule is:

> **ACR stores images; ACI and ACA run them.**

---

## What You Will Learn

- The role of Azure Container Registry
- The difference between ACI and ACA
- How image pull authentication works securely
- How to choose the right Azure container service for a workload
- Common admin mistakes and troubleshooting steps

---

## Container Mental Model

```text
[Source code]
      |
      v
[Container image build]
      |
      v
[Azure Container Registry]
      |                |
      v                v
[Azure Container Instances]   [Azure Container Apps]
```

---

## Service Comparison

| Service | Purpose | Best for |
|---|---|---|
| **ACR** | Private image registry | Secure image storage, versioned deployment artifacts |
| **ACI** | Simple serverless container runtime | Short-lived jobs, burst tasks, single-container or small grouped workloads |
| **ACA** | Managed container app platform | Modern apps, microservices, HTTP/event-driven scale, revisions |

---

## Azure Container Registry (ACR)

ACR is Azure’s private registry for container images.

### What it provides

- private storage for container images
- repositories and tags for version control
- integration with Azure identities and role-based access
- enterprise-friendly image distribution workflows

### Operational guidance

- keep a clear tagging strategy such as `v1.0.0`, `2026-04`, or environment-labeled releases
- avoid relying only on `latest` in production deployment logic
- prefer **`AcrPull`** / **`AcrPush`** role assignments over broad admin credentials

### Important note
The **admin user** for ACR is useful in simple lab scenarios, but production designs should prefer identity-based authentication where possible.

---

## Azure Container Instances (ACI)

ACI is a fast, lightweight way to run containers without managing VMs or orchestrators.

### Good use cases

- simple one-off jobs
- burst or ad-hoc container execution
- small container groups with shared lifecycle/network context
- rapid testing of container images

### Limitations to remember

- not a full application platform for complex microservice patterns
- simpler scaling and ingress story than ACA
- typically better for straightforward execution rather than long-lived app platform needs

---

## Azure Container Apps (ACA)

ACA is a managed platform for running containerized applications with modern app features.

### Key characteristics

- revision-based deployments
- built-in scaling behavior
- support for HTTP and event-driven scale patterns
- managed environment for app-style container hosting

### Good use cases

- APIs and web apps
- microservices-style workloads
- apps that need safer rollout behavior and managed scaling
- teams that want container benefits without managing Kubernetes clusters

If the scenario emphasizes **managed app platform behavior**, **revisions**, or **built-in autoscale**, ACA is often the better fit.

---

## Choosing Between ACI and ACA

### Choose **ACI** when:

- you need fast and simple container execution
- the workload is short-lived, isolated, or operationally simple
- advanced routing and app platform features are not required

### Choose **ACA** when:

- the workload needs managed scaling or revision-driven releases
- you need app-style ingress behavior
- the service is more than a one-off container task

---

## Secure Image Pulls and Identity

A typical secure image flow looks like this:

1. build or push the image into **ACR**
2. grant the runtime identity **pull permission**
3. configure the runtime to use the ACR login server
4. deploy the image by tag or version

### Common secure pattern

- store the image in ACR
- assign `AcrPull` to the consuming identity
- let ACI or ACA pull the image without exposing registry passwords broadly

---

## Example Scenarios

### 1. Private image for a quick batch task

Use **ACR + ACI**.

### 2. Containerized web API with autoscaling needs

Use **ACR + ACA**.

### 3. Enterprise image repository for multiple teams

Use **ACR** as the central image store with RBAC-based access control and clear tag/version standards.

---

## Azure CLI Examples

### Create an Azure Container Registry

```bash
az acr create \
  --resource-group <rg> \
  --name <acr-name> \
  --sku Standard
```

### List repositories in ACR

```bash
az acr repository list \
  --name <acr-name> \
  -o table
```

### Run a container in ACI from an ACR image

```bash
az container create \
  --resource-group <rg> \
  --name <aci-name> \
  --image <acr-name>.azurecr.io/<repo>:<tag> \
  --cpu 1 \
  --memory 1.5 \
  --registry-login-server <acr-name>.azurecr.io \
  --registry-username <acr-username> \
  --registry-password <acr-password>
```

### Create a Container App from a private image

```bash
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

## Best Practices

1. Treat **ACR** as the trusted image source and keep tags disciplined.
2. Prefer **identity-based pull access** over broad registry admin credentials.
3. Use **ACI** for simple or short-lived container execution.
4. Use **ACA** for modern, managed application-style container workloads.
5. Validate registry name, image tag, and pull permissions before assuming a runtime problem.

---

## Troubleshooting Checklist

If a container deployment fails:

1. Confirm the image exists in the expected **repository and tag**.
2. Check the **ACR login server** name.
3. Verify the runtime has the correct **pull permissions** or credentials.
4. Confirm ingress and target port settings for app-style workloads.
5. Make sure the chosen platform matches the workload complexity.

---

## Common Pitfalls and Exam Traps

- Treating **ACR** as if it were a runtime service.
- Using weak tag hygiene such as always deploying `latest`.
- Confusing the capabilities of **ACI** and **ACA**.
- Assuming image pull failures are app bugs when they are really permission or registry issues.
- Referencing a private ACR image without configuring authentication correctly.

---

## Key Takeaways

- **ACR** stores container images securely.
- **ACI** is for simple, fast container execution.
- **ACA** is for managed container applications with scaling and revision features.
- Good Azure container administration depends on **service selection, image discipline, and secure pull authorization**.

---

## Further Reading

- [Azure Container Registry overview](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro)
- [Azure Container Instances overview](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-overview)
- [Azure Container Apps overview](https://learn.microsoft.com/en-us/azure/container-apps/overview)
- [Authenticate with Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication)
