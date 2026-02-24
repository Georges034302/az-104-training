# Azure Backup (Recovery Services Vault, Policies, Restore)

## What you will learn
- How Azure Backup works for VMs
- Policies and retention basics
- Restore types (file vs full VM)

## Concept flow architecture
```mermaid
flowchart LR
  VM --> Vault[Recovery Services Vault]
  Vault --> Policy[Backup Policy]
  Policy --> Points[Recovery Points]
  Restore --> VM
```

## Key concepts (AZ-104 focus)
- Recovery Services Vault stores backup configuration and recovery points metadata.
- Policies control schedule and retention.
- AZ-104 expects you to enable VM backup and perform restore operations.

## Admin mindset
- Test restores periodically (restore to a new VM is safer for validation).
- Use least privilege and lock critical vault resources (carefully).
- Understand that restore operations can take time and incur storage costs.

## Common pitfalls / exam traps
- Forgetting to register providers or missing permissions.
- Assuming backups happen instantly after enabling (first backup schedule).
- Not cleaning up restored VMs and disks.

## Quick CLI signals (read-only examples)
> These are **signals** you look for as an administrator. They are not a full lab.
```bash
# az <service> <command> ... 
```
