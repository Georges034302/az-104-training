# Storage Security: SAS vs Azure RBAC (Data Plane Access)

## Overview

Azure Storage access control is often misunderstood because two permission models are used:

- **Azure RBAC (data roles)** for identity-based authorization
- **Shared Access Signatures (SAS)** for delegated, time-bound token access

Strong designs combine identity, least privilege, and network controls.

---

## What You Will Learn

- Difference between management plane and data plane permissions
- When RBAC should be preferred
- When SAS is appropriate
- SAS types and risk controls
- How network controls complement identity controls

---

## Security Model View

```
 [User/App Identity] ---> [Azure RBAC Data Role] ---> [Storage Data Access]
         |
         +--> [SAS Token (delegated/time-bound)] ---> [Storage Data Access]

 [Firewall / Private Endpoint / VNet Rules] ---> [Network Path Restriction]
```

---

## Core Concepts

- **Management plane vs data plane**:
  - Management plane: create/update storage resources.
  - Data plane: read/write blobs/files/queues/tables.
- **RBAC data roles** (examples):
  - Storage Blob Data Reader
  - Storage Blob Data Contributor
  - Storage Blob Data Owner
- **File data roles also exist** for Azure Files scenarios; role selection must match the service and protocol path you are securing.
- **SAS**: Signed token that delegates limited access parameters (scope, permissions, start/expiry, optional IP/protocol constraints).

---

## RBAC Scope and Data Authorization Nuance

- Data-plane RBAC can be assigned at broad or narrower scopes depending on the resource type and service path.
- For Blob/Data Lake scenarios, authorization can involve more than one layer: RBAC grants access at Azure control/data role level, and in hierarchical namespace scenarios ACLs can further restrict effective access.
- Effective access must be evaluated at the correct service plane and resource scope.

---

## SAS Types (High-Level)

- **User delegation SAS**
  - Based on Microsoft Entra credentials for Blob service.
  - Preferred over account key-based SAS when feasible.
  - Relevant to Blob/Data Lake scenarios rather than all storage services.
- **Service SAS**
  - Delegates access to a specific service resource.
- **Account SAS**
  - Broadest scope; use cautiously.
- **Stored access policies** can be used in supported SAS scenarios to centralize expiry/permission control for revocation and management.

Design implication: user delegation SAS is usually the strongest delegation option when Blob-based workloads support it, because it avoids direct dependency on account keys.

---

## When To Use RBAC vs SAS

- Use **RBAC** when:
  - Access is internal or long-lived.
  - You can manage identity lifecycle through Entra ID.
  - You need auditable role-based governance.

- Use **SAS** when:
  - You need temporary, delegated access.
  - External systems/users need constrained short-term access.
  - You must grant narrow, time-bound permissions without permanent role assignment.

---

## Defense In Depth

Combine authorization with network controls:
- private endpoints
- storage firewall/network ACLs
- trusted endpoint restrictions where appropriate
- disabling or limiting Shared Key authorization where design and workload support it

For sensitive workloads, reducing shared key dependency is often a meaningful security improvement because account keys grant very broad access if exposed.

Important: Network controls reduce exposure but do not replace authorization.

---

## Operational Guidance

1. Default to RBAC for first-party/internal access patterns.
2. Use short-lived SAS with minimum permissions.
3. Prefer HTTPS-only and limit SAS scope to required resources.
4. Avoid distributing storage account keys broadly.
5. Review role assignments and token issuance patterns regularly.
6. Prefer user delegation SAS over account key-based SAS when Blob access patterns support it.
7. When using Data Lake-style hierarchical namespace scenarios, evaluate RBAC and ACL behavior together.

---

## Common Pitfalls and Exam Traps

- Assigning `Contributor` and expecting blob data access (wrong plane role expectation).
- Issuing long-lived, over-permissive SAS tokens.
- Treating network restrictions as a replacement for RBAC/SAS controls.
- Forgetting to remove stale role assignments or old delegation patterns.
- Using account-level shared keys as the default access model when narrower delegated or identity-based options are available.
- Ignoring ACL effects in hierarchical namespace workloads and troubleshooting access only at RBAC layer.

---

## Quick CLI Reference

```bash
# Assign blob data contributor role at storage scope
az role assignment create \
  --assignee-object-id <principal-object-id> \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope <storage-account-resource-id>

# Generate a blob SAS token (service SAS example)
az storage blob generate-sas \
  --account-name <storage-account> \
  --container-name <container> \
  --name <blob-name> \
  --permissions r \
  --expiry <UTC-datetime> \
  --https-only \
  --account-key <account-key> \
  -o tsv

# List role assignments at storage scope
az role assignment list --scope <storage-account-resource-id> -o table
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/storage/common/authorize-data-access
- https://learn.microsoft.com/en-us/azure/storage/common/storage-sas-overview
- https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security

