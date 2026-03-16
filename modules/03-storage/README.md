# Module 03 — Azure Storage

> **Focus**: Storage account design, redundancy, blob lifecycle, Azure Files, and secure data access

This module covers the Azure Storage topics most relevant to AZ-104: storage account planning, redundancy choices, blob data management, Azure Files design, and secure data-plane access.

## 📖 Lessons

1. **[Storage Accounts & Redundancy](lessons/01-storage-accounts-redundancy.md)** - Storage account capabilities, performance models, and redundancy choices including LRS, ZRS, GRS, and GZRS variants
2. **[Blob Storage & Lifecycle Management](lessons/02-blob-lifecycle.md)** - Blob types, access tiers, lifecycle rules, and data protection controls
3. **[Azure Files](lessons/03-azure-files.md)** - Azure Files architecture, SMB/NFS considerations, share tiers, and hybrid file scenarios
4. **[Storage Security: SAS vs RBAC](lessons/04-storage-security-sas-rbac.md)** - Data-plane authorization with Azure RBAC, SAS, and supporting network controls

## 🧪 Labs

1. **[Storage Account & Blob Container (CLI + ARM)](labs/cli-arm/01-storage-account-blob-container.md)** | **[Portal](labs/portal/01-storage-account-blob-container.md)** - Create a private blob container, upload content, and validate download flow
2. **[Lifecycle Policy (CLI + ARM)](labs/cli-arm/02-lifecycle-policy.md)** | **[Portal](labs/portal/02-lifecycle-policy.md)** - Configure and validate a lifecycle rule that moves block blobs to Cool storage
3. **[Azure Files Share (CLI + ARM)](labs/cli-arm/03-azure-files-share.md)** | **[Portal](labs/portal/03-azure-files-share.md)** - Create an SMB-based Azure file share, set quota, and validate file upload
4. **[SAS vs RBAC (CLI + ARM)](labs/cli-arm/04-sas-vs-rbac.md)** | **[Portal](labs/portal/04-sas-vs-rbac.md)** - Compare delegated SAS access with identity-based Azure RBAC authorization

## Lab Standards

- **CLI + ARM track**: Fully parameterized with `.env`, explicit validation, and cleanup.
- **Portal track**: Detailed step-by-step procedures aligned to the same learning outcome as the CLI track.
- **Architecture diagrams**: Text-only boxes/arrows (no Mermaid).
- **Safety**: Every lab uses a dedicated resource group and includes cleanup commands.

## Learning Outcomes

After completing this module, you will be able to:
- Design storage accounts with the right durability, availability, and feature set
- Manage blob data with access tiers, lifecycle rules, and recovery protections
- Deploy Azure Files with appropriate share, protocol, and quota decisions
- Secure Azure Storage data access with RBAC, SAS, and network restrictions
