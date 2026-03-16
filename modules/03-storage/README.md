# Module 03 — Azure Storage

> **Focus**: Storage accounts, blob containers, Azure Files, lifecycle policies, and security

This module covers Azure storage services, including blob storage, file shares, redundancy options, and security mechanisms.

## 📖 Lessons

1. **[Storage Accounts & Redundancy](lessons/01-storage-accounts-redundancy.md)** - Account types, performance tiers, and replication options (LRS, GRS, ZRS, RA-GRS)
2. **[Blob Storage & Lifecycle Management](lessons/02-blob-lifecycle.md)** - Container management and automated tier transitions (Hot, Cool, Archive)
3. **[Azure Files](lessons/03-azure-files.md)** - SMB file shares for cloud and hybrid scenarios
4. **[Storage Security: SAS vs RBAC](lessons/04-storage-security-sas-rbac.md)** - Shared Access Signatures and role-based access comparison

## 🧪 Labs

1. **[Storage Account & Blob Container (CLI + ARM)](labs/cli-arm/01-storage-account-blob-container.md)** | **[Portal](labs/portal/01-storage-account-blob-container.md)** - Create storage account, upload and download blobs
2. **[Lifecycle Policy (CLI + ARM)](labs/cli-arm/02-lifecycle-policy.md)** | **[Portal](labs/portal/02-lifecycle-policy.md)** - Automate blob tier transitions based on age for cost optimization
3. **[Azure Files Share (CLI + ARM)](labs/cli-arm/03-azure-files-share.md)** | **[Portal](labs/portal/03-azure-files-share.md)** - Create and configure SMB file share with quota management
4. **[SAS vs RBAC (CLI + ARM)](labs/cli-arm/04-sas-vs-rbac.md)** | **[Portal](labs/portal/04-sas-vs-rbac.md)** - Compare delegation methods with SAS tokens and Azure RBAC roles

## Learning Outcomes

After completing this module, you will be able to:
- Create and configure storage accounts with appropriate redundancy
- Manage blob storage and implement lifecycle policies
- Deploy Azure Files for shared file storage scenarios
- Secure storage access with SAS tokens and RBAC
