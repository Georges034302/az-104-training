# Azure Files (SMB Shares and Use Cases)

## What you will learn
- What Azure Files is
- How SMB access works
- Common admin operations (quota, access, mount)

## Concept flow architecture
```mermaid
flowchart LR
  Client[Client/VM] --> SMB[SMB Protocol]
  SMB --> Share[Azure File Share]
  Share --> Account[Storage Account]
```

## Key concepts (AZ-104 focus)
- Azure Files provides managed file shares accessible via SMB.
- Access can be via storage keys/SAS or Entra ID (advanced); AZ-104 typically focuses on share creation and access.
- File Sync extends Azure Files to on-prem via cache servers (concept).

## Admin mindset
- Use Azure Files for lift-and-shift file shares or shared content for apps.
- Control quotas and monitor usage.
- Prefer private endpoints for sensitive workloads in production.

## Common pitfalls / exam traps
- Firewall/network rules blocking SMB (port 445).
- Confusing blob containers with file shares.
- Using storage account keys broadly (rotate and minimise usage).

## Quick CLI signals (read-only examples)
> These are **signals** you look for as an administrator. They are not a full lab.
```bash
# az <service> <command> ... 
```
