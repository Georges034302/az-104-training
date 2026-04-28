# Azure Files: Managed SMB and NFS File Shares

> Azure Files provides fully managed cloud file shares that can be mounted from Azure VMs and, in supported scenarios, from on-premises systems. It is a core service for shared folders, lift-and-shift applications, and hybrid file environments.

---

## Overview

Azure Files is different from Blob Storage because it provides a **file share** experience rather than an object store. That makes it suitable for:

- shared application content
- user or team shared drives
- lift-and-shift workloads that expect SMB shares
- hybrid branch office file access with Azure File Sync

For AZ-104, you should understand protocols, performance tiers, security choices, and when Azure Files is the right tool.

---

## What You Will Learn

- What Azure Files is and when to use it
- SMB vs NFS considerations
- Standard vs premium file share decisions
- Authentication and authorization options
- Hybrid scenarios with Azure File Sync
- Operational best practices and troubleshooting steps

## Acronyms and Terms (Do Not Assume)

- SMB = Server Message Block (file-sharing protocol used heavily in Windows environments)
- NFS = Network File System (file-sharing protocol used heavily in Linux/Unix environments)
- IOPS = Input/Output Operations Per Second (storage performance metric)
- ACL = Access Control List (file/folder permissions)
- NTFS = New Technology File System (Windows file system with ACL model)
- AD DS = Active Directory Domain Services
- SLA = Service Level Agreement

Understanding these terms is essential for making correct Azure Files architecture decisions.

---

## Azure Files Mental Model

```text
[Client VM / User / App]
        |
        +--> [SMB access]
        +--> [NFS access in supported scenarios]
                    |
                    v
             [Azure File Share]
                    |
                    v
             [Storage Account]
                    |
                    +--> [Snapshots / Backup]
                    +--> [Firewall / Private Endpoint]
                    +--> [Monitoring / Quotas]
```

---

## When to Choose Azure Files

| Service | Best for | Avoid when |
|---|---|---|
| **Azure Files** | Shared folders, SMB/NFS-compatible apps, hybrid file shares | Workload is object-based rather than file-share based |
| **Blob Storage** | Object storage, backups, media, logs | App expects a mounted file system share |
| **Managed Disks** | VM operating systems and attached disks | Multiple systems need shared file access |

---

## Core Concepts

### Azure File Share
A file share lives inside a storage account and is accessed using SMB or NFS depending on the design.

### Protocol options

| Protocol | Common use | Important notes |
|---|---|---|
| **SMB** | Windows file shares, many lift-and-shift apps | Broadest compatibility; identity-based access is available |
| **NFS 4.1** | Linux and high-performance file scenarios | Supported in specific Azure Files configurations, commonly premium-focused |

### Protocol behavior differences (professional view)

| Area | SMB | NFS 4.1 |
|---|---|---|
| Typical platform | Windows-first, mixed enterprise | Linux-first workloads |
| Auth model | Identity integration options (AD DS / Entra scenarios) | Network and export-style controls dominate design |
| Permission model | Share permissions + NTFS ACL layering | POSIX-style expectations in Linux environments |
| Common use | Lift-and-shift apps, shared drives, user profiles | Linux applications, performance-sensitive file access |

Do not assume SMB and NFS can be managed with the same security playbook.

### Share capabilities

- **Quota** controls capacity at share level
- **Snapshots** support point-in-time recovery
- **Backup integration** helps protect critical shares
- **Private networking** can be used for secure access paths

---

## Standard vs Premium File Shares

| Tier | Backing | Best for |
|---|---|---|
| **Standard** | HDD-backed | General-purpose file shares, lower-cost workloads |
| **Premium** | SSD-backed | Performance-sensitive workloads with higher IOPS/throughput needs |

Design choice should be based on:

- latency expectations
- IO profile
- protocol requirements
- business importance of the workload

Do not choose a tier based only on storage size.

### Tier selection criteria

Use measurable workload characteristics:

- Average and peak IOPS
- Throughput requirements (MB/s)
- Latency tolerance
- Protocol requirements (SMB vs NFS)
- Recovery and backup objectives

If the workload has strict latency requirements or high transaction intensity, premium is often the safer production choice.

---

## Authentication and Access Models

### SMB access models

For SMB-based Azure Files, common access approaches include:

- **storage account keys**
- **SAS tokens**
- **identity-based SMB authentication** for supported enterprise scenarios

Identity-based access can integrate with:

- **Active Directory Domain Services (AD DS)**
- **Microsoft Entra Domain Services**
- **Microsoft Entra Kerberos** for supported scenarios

Professional security note:
- Prefer identity-based authorization over broad shared-key usage.
- Shared keys should be tightly controlled, rotated, and not embedded in application code.

### NFS access model

NFS access is typically designed around **network path controls** and service configuration rather than the same identity model used by SMB.

> SMB and NFS should be treated as different security and operational designs.

---

## Hybrid Use Case: Azure File Sync

Azure File Sync extends Azure Files to Windows Server environments.

### What it does

- synchronizes Azure file shares with Windows Servers
- keeps frequently used files cached locally
- stores colder data centrally in Azure

### Good use cases

- branch office file servers
- central file share with local office cache
- gradual migration of on-premises file infrastructure to Azure

Azure File Sync is a hybrid solution, not a replacement for planning security, quota, backup, and monitoring.

---

## Networking and Security Considerations

For production use, Azure Files is often combined with:

- **storage firewalls**
- **private endpoints**
- **RBAC and least privilege**
- **backups and snapshots**

### Important operational note
SMB access commonly depends on outbound **port 445** being allowed. Some corporate or ISP environments block it, which is a classic troubleshooting point.

### Enterprise network pattern

For sensitive workloads, combine:

- Private endpoints for private connectivity
- DNS validation for private endpoint resolution
- Firewall rules scoped to approved source networks
- Least-privilege share permissions and ACLs

This prevents exposing file shares broadly while preserving operational access.

## Permission Layer Model (Critical Troubleshooting Concept)

In SMB scenarios, effective access often depends on two permission layers:

1. Share-level permissions (who can access the share)
2. NTFS ACL permissions (what they can do to files/folders)

A user can be allowed at share level but denied by NTFS ACL. This is one of the most common real-world causes of "access denied" incidents.

## Exam Traps and Operational Pitfalls

1. Assuming Blob Storage and Azure Files are interchangeable for mounted shares.
2. Forgetting port 445 requirements in SMB deployments.
3. Picking standard tier for latency-sensitive workloads without performance validation.
4. Using shared keys broadly instead of identity-based authorization.
5. Ignoring dual-layer permission troubleshooting (share + ACL).

---

## Example Scenarios

### 1. Lift-and-shift application share

Use **SMB-based Azure Files** when the application already expects a Windows-style shared folder.

### 2. Shared content for Azure VMs

Use Azure Files when multiple VMs need the same shared application files.

### 3. Branch office hybrid file server

Use **Azure File Sync** so frequently used files stay cached locally while the authoritative copy is in Azure.

---

## CLI Reference

### Create a file share

```bash
az storage share-rm create \
  --resource-group <rg> \
  --storage-account <storage-account> \
  --name teamshare \
  --quota 512
```

### List file shares

```bash
az storage share-rm list \
  --resource-group <rg> \
  --storage-account <storage-account> \
  -o table
```

### Create a directory in the share

```bash
az storage directory create \
  --account-name <storage-account> \
  --share-name teamshare \
  --name projects/app1 \
  --auth-mode login
```

### Upload a file

```bash
az storage file upload \
  --account-name <storage-account> \
  --share-name teamshare \
  --source ./readme.txt \
  --path docs/readme.txt \
  --auth-mode login
```

---

## Best Practices

1. Choose **standard vs premium** based on real IO and latency needs.
2. Prefer **identity-based access** where supported instead of broadly sharing account keys.
3. Use **private endpoints** or firewall restrictions for sensitive shares.
4. Define **quotas**, snapshots, and backup strategy before production use.
5. Validate protocol compatibility and client requirements early.

---

## Troubleshooting Checklist

If Azure Files access fails:

1. Confirm the correct **share name**, **storage account**, and **protocol** are being used.
2. Check whether **port 445** is allowed for SMB scenarios.
3. Verify firewall, private endpoint, and DNS settings.
4. Confirm whether the issue is **authentication** or **network** related.
5. Check share quota, performance tier, and snapshot/backup expectations.

---

## Common Pitfalls

- Confusing **file shares** with **blob containers**.
- Assuming SMB and NFS use the same identity model.
- Using storage account keys everywhere instead of least-privilege access.
- Forgetting SMB port 445 requirements.
- Choosing standard or premium without checking the workload’s IO profile.

---

## Key Takeaways

- Azure Files provides managed **shared file storage** over SMB or NFS.
- It is ideal for shared-folder and hybrid file-server scenarios.
- Security planning must consider **protocol**, **network path**, and **authentication model** together.
- Azure File Sync is a strong hybrid extension for Windows Server environments.

---

## Advanced: Enterprise File Service Design

### Access Model Selection

Choose authentication model per environment:

- Entra Kerberos/AD DS for identity-integrated SMB access
- Shared key or SAS for controlled non-domain scenarios
- RBAC and share-level permissions designed together

### Performance and Throughput Planning

- Match standard or premium shares to IOPS/latency targets
- Account for burst and sustained workload behavior
- Validate client-side caching and protocol configuration

### Hybrid Operations with File Sync

- File Sync introduces tiering and edge-cache benefits
- Endpoint health and sync policies must be monitored continuously
- Plan server replacement and disaster scenarios in advance

## Extended Troubleshooting Matrix (Azure Files)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Share mount fails | Network path, firewall, or auth mismatch | Test port connectivity and credential method | Correct network/auth configuration |
| Access denied on share | NTFS/share permissions misaligned | Review effective permissions at both layers | Adjust ACL and share permissions |
| Poor throughput | Share tier or client path bottleneck | Inspect storage metrics and client profile | Move to premium or optimize client path |
| File Sync conflicts | Multiple writers or sync policy mismatch | Review sync health and conflict logs | Resolve conflicts and adjust sync policy |

## Production Readiness Checklist (Azure Files)

- Authentication and authorization model standardized
- Share tier and capacity sized to workload profile
- Network requirements validated for all client locations
- Backup and snapshot strategy tested for restore outcomes
- File Sync monitoring and alerting enabled where applicable
- Permission governance and audit process documented


---

## Further Reading

- [Azure Files introduction](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-introduction)
- [Identity-based authentication for Azure Files](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-overview)
- [Azure File Sync introduction](https://learn.microsoft.com/en-us/azure/storage/file-sync/file-sync-introduction)
- [Plan for an Azure Files deployment](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-planning)
