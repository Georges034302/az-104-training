# Storage Security: SAS vs Azure RBAC

> Azure Storage security is strongest when you separate **who is allowed to access data** from **how the network path is restricted**. For AZ-104, the key comparison is **identity-based Azure RBAC** versus **delegated Shared Access Signatures (SAS)**.

---

## Overview

Azure Storage authorization is often confusing because there are multiple layers involved:

- **management plane** permissions to create or modify storage resources
- **data plane** permissions to read or write blobs, files, queues, and tables
- **network controls** such as firewalls, VNet rules, and private endpoints

The two main data access models you must know are:

- **Azure RBAC data roles**
- **Shared Access Signatures (SAS)**

---

## What You Will Learn

- Management plane vs data plane access
- When Azure RBAC is the better choice
- When SAS is appropriate and how to limit it safely
- Why user delegation SAS is preferred where supported
- How network controls complement authorization

## Acronyms and Terms (Do Not Assume)

- RBAC = Role-Based Access Control
- SAS = Shared Access Signature
- ACL = Access Control List
- ADLS Gen2 = Azure Data Lake Storage Gen2
- IAM = Identity and Access Management
- JWT = JSON Web Token

These terms appear constantly in storage security architecture and troubleshooting.

---

## Security Mental Model

```text
[User / App Identity]
        |
        +--> [Azure RBAC data role] -------> [Storage data access]
        |
        +--> [SAS token] ------------------> [Storage data access]

[Firewall / VNet rules / Private Endpoint] -> [Restrict network path]
```

---

## Management Plane vs Data Plane

| Plane | What it controls | Example |
|---|---|---|
| **Management plane** | Create, update, delete storage resources | Create a storage account, change firewall settings |
| **Data plane** | Read, write, delete actual data | Upload a blob, download a file, list containers |

### Critical exam point
Having a role like **Contributor** on the storage account does **not automatically** give permission to read or write the actual blob data. You often need a **data role** such as `Storage Blob Data Reader` or `Storage Blob Data Contributor`.

---

## Azure RBAC for Storage Data Access

RBAC is the preferred choice for most internal and long-lived access patterns.

### Common data roles

| Role | Typical use |
|---|---|
| **Storage Blob Data Reader** | Read blob data only |
| **Storage Blob Data Contributor** | Read/write/delete blob data |
| **Storage Blob Data Owner** | Full blob data control, including ownership-related actions |
| **Storage File Data SMB Share Reader/Contributor** | Azure Files SMB access scenarios |

### Why RBAC is preferred

- identity-based and auditable
- aligned with Microsoft Entra ID lifecycle
- easier to govern with least privilege
- avoids widespread sharing of account keys

### Professional RBAC design pattern

1. Assign roles to security groups, not individuals.
2. Scope assignments as narrowly as practical (container/resource group instead of subscription where possible).
3. Separate read, write, and admin personas.
4. Periodically review assignments for stale access.

---

## SAS: Delegated Time-Bound Access

A **Shared Access Signature (SAS)** is a signed token that delegates limited permissions for a limited time.

### SAS types

| SAS type | Best use | Risk profile |
|---|---|---|
| **User delegation SAS** | Blob/Data Lake temporary access using Entra identity | Preferred where supported |
| **Service SAS** | Access to a specific blob, container, file share, or similar resource | Narrower than account SAS |
| **Account SAS** | Broader service-level delegation across the account | Highest risk; use carefully |

### SAS controls you should limit

- **permissions** (`r`, `w`, `d`, etc.)
- **expiry time**
- **start time**
- **IP restriction**
- **HTTPS-only access**

> For Blob Storage, **user delegation SAS** is usually the most secure delegation model because it avoids direct reliance on storage account keys.

### SAS hardening checklist

When issuing SAS tokens:

1. Set shortest feasible expiry time.
2. Grant minimum permissions required.
3. Restrict allowed IP ranges where possible.
4. Enforce HTTPS only.
5. Avoid account SAS unless genuinely required.
6. Log issuance and ownership for incident response.

---

## When to Use RBAC vs SAS

| Requirement | Better choice | Why |
|---|---|---|
| Internal employee/app access | **RBAC** | Identity-based, auditable, easier to govern |
| Temporary external download link | **SAS** | Short-lived delegated access without permanent role assignment |
| Automated internal workload using managed identity | **RBAC** | No secrets or account keys needed |
| Short-term upload for a partner or process | **SAS** | Narrow permissions and expiry can be enforced |

### Simple rule of thumb

- Choose **RBAC** for normal ongoing access
- Choose **SAS** for **temporary delegated** access

## Decision Framework: RBAC vs SAS vs Keys

| Requirement | Preferred model | Notes |
|---|---|---|
| Internal workforce access | RBAC | Best governance and auditability |
| Managed identity workload | RBAC | Avoids secrets and token sprawl |
| Short-lived external file exchange | SAS | Time-bound delegation without role assignment |
| Legacy app requiring key auth | Shared key (temporary) | Plan migration to RBAC/SAS where possible |

Professional note:
- Shared keys are high blast-radius credentials. Treat them like privileged secrets and rotate aggressively.

---

## ADLS Gen2 Note: RBAC and ACLs

For Blob/Data Lake Storage Gen2 scenarios with hierarchical namespace enabled:

- RBAC grants access at Azure role scope
- **ACLs** can further restrict access at the file or directory level

This means effective access might depend on **both** RBAC and ACLs. This is a common troubleshooting nuance in analytics-style storage workloads.

---

## Defense in Depth

Authorization should be combined with network restrictions such as:

- **storage firewall rules**
- **selected networks only**
- **private endpoints**
- **trusted Microsoft services** where appropriate
- disabling or limiting **shared key access** when the workload supports it

Network controls reduce exposure, but they do **not** replace RBAC or SAS.

### Defense-in-depth operating model

Use all three layers together:

1. Identity layer: RBAC/SAS least privilege
2. Network layer: firewall rules, private endpoints, selected networks
3. Data governance layer: immutability, soft delete, monitoring, alerting

A failure in one layer should not result in immediate full data exposure.

---

## CLI Reference

### Assign a blob data role

```bash
az role assignment create \
  --assignee-object-id <principal-object-id> \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope <storage-account-resource-id>
```

### Generate a user delegation SAS for a blob

```bash
az storage blob generate-sas \
  --account-name <storage-account> \
  --container-name <container> \
  --name <blob-name> \
  --permissions r \
  --expiry 2026-12-31T23:59Z \
  --https-only \
  --as-user \
  --auth-mode login \
  -o tsv
```

### Review role assignments

```bash
az role assignment list \
  --scope <storage-account-resource-id> \
  -o table
```

---

## Best Practices

1. Default to **RBAC** for internal and long-lived access.
2. Use **short-lived SAS** with the minimum required permissions.
3. Prefer **user delegation SAS** over account-key-based SAS when possible.
4. Avoid distributing storage account keys broadly.
5. Combine authorization with firewall rules or private endpoints.
6. Review old role assignments and stale SAS usage patterns regularly.

---

## Troubleshooting Checklist

If storage access is denied unexpectedly:

1. Confirm whether the problem is **management plane** or **data plane**.
2. Check whether the principal has the correct **data role**, not just `Contributor`.
3. Validate SAS expiry, permissions, IP restrictions, and HTTPS requirements.
4. Review storage firewall, VNet rules, or private endpoint configuration.
5. For ADLS Gen2, check whether **ACLs** are further restricting access.

---

## Common Pitfalls

- Assigning `Contributor` and expecting blob data access.
- Issuing long-lived, over-permissive SAS tokens.
- Treating network restrictions as a substitute for authorization.
- Using account-level shared keys when RBAC or user delegation SAS would be safer.
- Troubleshooting ADLS Gen2 access only at the RBAC layer and forgetting ACLs.

## Exam Traps and Real-World Failure Modes

1. Contributor role does not imply blob data read/write permissions.
2. Long-lived SAS tokens become unmanaged shadow credentials.
3. Private endpoint configured but DNS unresolved to private IP causes access failures.
4. RBAC appears correct, but ADLS Gen2 ACL still blocks access.
5. Management-plane success is mistaken for data-plane authorization success.

---

## Key Takeaways

- **RBAC** is the preferred model for identity-based storage access.
- **SAS** is best for temporary, delegated access.
- Management-plane roles and data-plane roles are not the same thing.
- Strong storage security combines **identity + least privilege + network restriction**.

---

## Advanced: Authorization Model Hardening

### Plane-Aware Access Control

Separate governance by control plane and data plane:

- Management actions handled through Azure RBAC scope assignments
- Data operations controlled by storage data roles, SAS, and ACLs where applicable
- Avoid broad Contributor roles when data-specific roles are sufficient

### SAS Governance

SAS should be constrained and auditable:

- Short lifetimes and least privilege permissions
- Prefer user delegation SAS when possible
- Rotation and revocation procedures documented

### Defense in Depth

- Restrict network access with private endpoints/firewalls
- Enforce secure transfer and encryption settings
- Monitor anomalous data operations and token use patterns

## Extended Troubleshooting Matrix (Storage Security)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| User can manage account but not read blob data | Data plane role missing | Check assigned storage data roles | Grant required data role at correct scope |
| SAS works for some operations only | Token permissions or resource type too narrow | Decode SAS parameters and operation intent | Regenerate SAS with minimum required scope |
| Access denied from approved identity | Token audience/credential path mismatch | Validate auth method and token context | Use correct credential flow and scope |
| Authorized identity still blocked | Network restrictions override identity permissions | Review firewall/private endpoint settings | Align network policy with access design |

## Production Readiness Checklist (Storage Security)

- Data-plane and management-plane roles clearly separated
- SAS issuance policy with expiry and approval workflow enforced
- Network restrictions and private access controls validated
- Encryption, secure transfer, and audit logging enabled
- Regular access reviews performed for principals and tokens
- Incident response runbook includes token revocation steps


---

## Further Reading

- [Authorize access to Azure Storage data](https://learn.microsoft.com/en-us/azure/storage/common/authorize-data-access)
- [Shared Access Signatures overview](https://learn.microsoft.com/en-us/azure/storage/common/storage-sas-overview)
- [Storage network security](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security)
- [Authorize with Microsoft Entra ID](https://learn.microsoft.com/en-us/azure/storage/common/authorize-data-access-microsoft-entra-id)
