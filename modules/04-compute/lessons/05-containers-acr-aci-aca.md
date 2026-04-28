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

## Acronyms and Terms (Do Not Assume)

- ACR = Azure Container Registry
- ACI = Azure Container Instances
- ACA = Azure Container Apps
- AKS = Azure Kubernetes Service
- OCI = Open Container Initiative
- CI/CD = Continuous Integration / Continuous Delivery
- CPU = Central Processing Unit
- RAM = Random Access Memory
- SLA = Service Level Agreement
- mTLS = mutual Transport Layer Security

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

## Deep Dive: Compute Models for Containers on Azure

Containerized workloads can run on several Azure compute models. Selection should be based on required control, operations model, and scaling complexity.

| Model | Control level | Operations overhead | Best fit |
|---|---|---|---|
| ACI | Low-medium | Low | Burst jobs, simple tasks, ad-hoc container runs |
| ACA | Medium | Low-medium | Microservices, APIs, event-driven apps, revision-based rollouts |
| AKS | High | Medium-high | Complex orchestration, custom networking/policy, platform teams |
| App Service (Containers) | Medium | Low | Web/API container hosting with App Service operational model |

Professional guidance:
- Start with the simplest model that satisfies requirements.
- Move to AKS only when orchestration complexity truly demands it.
- For web/API workloads, compare ACA and App Service container hosting based on release and networking needs.

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

### Enterprise image governance

1. Enforce immutable release tags (for example `1.4.2`) for production deployments.
2. Retain digest references for high-assurance releases.
3. Scan images before deployment.
4. Implement retention policies to control storage costs.
5. Limit push rights to CI pipelines and trusted engineering groups.

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

### Practical ACI examples

Example 1: Nightly CSV transformation job
- Trigger from automation
- Run container for 10 minutes
- Output to storage
- Container stops; no always-on compute needed

Example 2: Incident response toolkit
- Security team starts temporary diagnostics container in isolated subnet
- Pulls signed image from ACR
- Exports report and exits

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

### ACA operational strengths

- Revision model for controlled rollout and rollback
- HTTP and event-driven scaling patterns
- Supports modern microservice decomposition
- Reduces orchestration burden compared to self-managed clusters

### ACA example architecture

```text
[API container]  [worker container]
     |                |
     +-------> [ACA environment] <-------+
             |
           [autoscale]
             |
          [ACR images]
```

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

## Compare ACA vs App Service (Containers)

Both can run containerized web applications, but they optimize for different operational models.

| Decision area | ACA | App Service (Containers) |
|---|---|---|
| Application style | Microservices/event-driven patterns | Traditional web/API hosting model |
| Release style | Revision-based traffic splitting options | Slot-based swap and plan-based operations |
| Scaling model | Request/event-driven replicas | Plan worker scale (shared plan boundary) |
| Team fit | Cloud-native teams | Teams already standardized on App Service |

Use this comparison in architecture reviews and exam scenarios where both services seem plausible.

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

### Secure pull checklist

1. Use managed identity where supported.
2. Grant only `AcrPull` to runtime identity.
3. Disable broad admin-credential usage in production workflows.
4. Validate network access path to ACR (private endpoint/firewall patterns where required).
5. Pin deployment to tested tags or digests.

---

## Example Scenarios

### 1. Private image for a quick batch task

Use **ACR + ACI**.

### 2. Containerized web API with autoscaling needs

Use **ACR + ACA**.

### 3. Enterprise image repository for multiple teams

Use **ACR** as the central image store with RBAC-based access control and clear tag/version standards.

### 4. Full CI/CD container release pattern

1. Developer commits code
2. Pipeline builds and tests image
3. Security scan runs
4. Image pushed to ACR with version tag
5. Deployment updates ACA/App Service container target
6. Health checks validate rollout
7. Roll back to prior tag if required

This pattern improves release repeatability and incident response speed.

---

## CLI Reference

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

## Common Pitfalls

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

## Advanced: Container Platform Decision and Governance

### Runtime Selection Criteria

- ACI for fast, simple, short-lived or single workload containers
- ACA for microservices/event-driven apps with autoscaling and revisions
- Escalate to orchestrators when workload complexity outgrows platform capabilities

### Supply Chain Security

- Enforce image scanning and signed artifact policies
- Limit registry pull rights via managed identity and least privilege
- Track image provenance from build to runtime deployment

### Operational Reliability

- Define probe/readiness semantics and failure handling
- Use revision and rollback strategy for safe releases
- Monitor cold-start, scaling latency, and dependency health

## Extended Troubleshooting Matrix (ACR, ACI, ACA)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Image pull fails | Missing auth or network access to registry | Check identity permissions and registry firewall | Grant pull role and allow network path |
| Container crashes repeatedly | Bad startup command or missing env config | Inspect container logs and revision settings | Correct startup/env settings and redeploy |
| Scale behavior does not match demand | Incorrect scale rule configuration | Review scaler metrics and thresholds | Tune scale rules and cooldown settings |
| New revision receives errors | Dependency mismatch or config drift | Compare revision config and dependency status | Roll back revision and remediate config |

## Production Readiness Checklist (Containers on Azure)

- Runtime platform chosen based on workload characteristics
- Registry security, scanning, and identity controls enforced
- Deployment rollback and revision strategy documented
- Health probes and observability configured end-to-end
- Scale rules validated with load tests
- Incident playbooks defined for image/runtime failures


---

## Further Reading

- [Azure Container Registry overview](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro)
- [Azure Container Instances overview](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-overview)
- [Azure Container Apps overview](https://learn.microsoft.com/en-us/azure/container-apps/overview)
- [Authenticate with Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication)
