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

---

## Azure CLI Examples

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

## Common Pitfalls and Exam Traps

- Assigning `Contributor` and expecting blob data access.
- Issuing long-lived, over-permissive SAS tokens.
- Treating network restrictions as a substitute for authorization.
- Using account-level shared keys when RBAC or user delegation SAS would be safer.
- Troubleshooting ADLS Gen2 access only at the RBAC layer and forgetting ACLs.

---

## Key Takeaways

- **RBAC** is the preferred model for identity-based storage access.
- **SAS** is best for temporary, delegated access.
- Management-plane roles and data-plane roles are not the same thing.
- Strong storage security combines **identity + least privilege + network restriction**.

---

## Further Reading

- [Authorize access to Azure Storage data](https://learn.microsoft.com/en-us/azure/storage/common/authorize-data-access)
- [Shared Access Signatures overview](https://learn.microsoft.com/en-us/azure/storage/common/storage-sas-overview)
- [Storage network security](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security)
- [Authorize with Microsoft Entra ID](https://learn.microsoft.com/en-us/azure/storage/common/authorize-data-access-microsoft-entra-id)
