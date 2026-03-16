# Network Security Groups (NSGs) and Application Security Groups (ASGs)

## Overview

**Network Security Groups (NSGs)** filter network traffic to and from Azure resources at Layers 3 and 4 (IP, port, protocol). They are a core security control in Azure networking.

**Application Security Groups (ASGs)** simplify NSG rule management by grouping VM NICs by application role instead of hard-coding IP addresses.

---

## What You Will Learn

- How NSG rules are evaluated
- Difference between subnet-level and NIC-level NSGs
- Default rules and custom priorities
- Stateful behavior and flow handling
- ASG-based rule design for scalable policy
- Validation and troubleshooting with effective rules

---

## Traffic Evaluation Flow

```
 [Packet]
    |
    v
 [NSG Rule Processing: lowest priority number first]
    |
    +--> [Match Allow rule] ---> [Traffic permitted]
    |
    +--> [Match Deny rule] ----> [Traffic blocked]
    |
    +--> [No custom match] ----> [Default rules apply]

 [ASG membership] ---> [Used as source/destination in NSG rules]
```

---

## Core Concepts

- **Stateful filtering**: If inbound traffic is allowed, response traffic is automatically allowed (and vice versa for established flows).
- **Priority model**: Lower number means higher priority; first matching rule wins.
- **Scope**:
  - Subnet NSG: applies to all NICs in that subnet.
  - NIC NSG: applies to a specific NIC.
- **Effective evaluation**: When both subnet-level and NIC-level NSGs are present, traffic must be allowed by both effective rule sets. A deny at either scope blocks the flow.
- **Default rules**: Azure adds default allow/deny rules. Your custom rules with higher priority (lower number) can override behavior.
- **ASG value**: Use ASGs (for example, `web-asg`, `app-asg`, `db-asg`) to avoid frequent IP-based rule changes.

---

## Design Guidance

1. Apply baseline security at subnet NSG level.
2. Use NIC NSGs only for targeted exceptions.
3. Prefer ASGs and service tags over static IP lists.
4. Keep inbound exposure minimal; restrict management ports.
5. Separate admin, app, and data tiers into different subnets and policies.

---

## Troubleshooting Workflow

1. Check NSG association (correct subnet/NIC).
2. Review rule priorities and overlap.
3. Use **effective security rules** on the NIC.
4. Validate source/destination, port, protocol direction.
5. Confirm route behavior and next hop when NSG looks correct.

---

## Common Pitfalls and Exam Traps

- Misunderstanding priority order (higher number does not win).
- Applying rules to wrong direction (inbound vs outbound).
- Leaving broad `Any` inbound access in place.
- Forgetting that NSGs are stateful and expecting separate return-path rules.
- Assuming ASGs span arbitrary resources; ASGs are for NIC-based grouping.

---

## Quick CLI Reference

```bash
# List NSGs
az network nsg list -o table

# List NSG rules
az network nsg rule list --resource-group <rg> --nsg-name <nsg>

# Create ASG
az network asg create --resource-group <rg> --name <asg-name>

# Show NIC effective NSG
az network nic list-effective-nsg --resource-group <rg> --name <nic-name>
```

---

## Further Reading

- [Network security groups overview](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Application security groups](https://learn.microsoft.com/en-us/azure/virtual-network/application-security-groups)

