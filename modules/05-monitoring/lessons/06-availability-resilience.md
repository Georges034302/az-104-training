# Availability & Resilience (SLA, RTO/RPO, Region Pairs)

## What you will learn
- How to read SLAs
- Designing for resilience
- Choosing between availability and backup/DR

## Concept flow architecture
```mermaid
flowchart LR
  SLA --> Design[Design Choices]
  Design --> Zones[Zones/Sets]
  Design --> Backup[Backup]
  Design --> DR[DR (ASR)]
```

## Key concepts (AZ-104 focus)
- SLA is service availability commitment; resilience comes from architecture choices.
- RTO/RPO drive backup/DR design decisions.
- Region pairs support planned platform recovery strategies.

## Admin mindset
- Use availability features for uptime; use backup for data recovery; use DR for regional failures.
- Balance cost vs risk with clear requirements.
- Validate with testing (restore tests, failover simulations).

## Common pitfalls / exam traps
- Assuming single VM meets high availability.
- Confusing backup with DR.
- Ignoring operational processes (runbooks, monitoring).

## Quick CLI signals (read-only examples)
> These are **signals** you look for as an administrator. They are not a full lab.
```bash
# az <service> <command> ... 
```
