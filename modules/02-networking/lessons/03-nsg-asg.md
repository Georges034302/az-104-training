# Network Security Groups (NSGs) and Application Security Groups (ASGs)

> **NSGs** are Azure’s built-in Layer 3/4 traffic filters for subnets and NICs. **ASGs** make those rules easier to scale by letting you target application roles instead of hard-coded IP addresses.

---

## Overview

NSGs are one of the first security controls you apply in Azure networking. They decide whether traffic is **allowed** or **denied** based on:

- source and destination
- port and protocol
- direction (inbound or outbound)
- priority order

ASGs work with NSGs by grouping VM NICs into logical roles such as `web`, `app`, or `db`.

---

## What You Will Learn

- How NSG rules are evaluated
- Default rules and custom priority behavior
- Subnet-level vs NIC-level NSGs
- How ASGs simplify rule management
- Examples, best practices, and troubleshooting workflows

---

## Traffic Evaluation Flow

```text
[Inbound or outbound packet]
          |
          v
[Evaluate NSG rules by priority: 100 -> 4096]
          |
          +--> first matching Allow rule -> traffic permitted
          +--> first matching Deny rule  -> traffic blocked
          +--> no custom match           -> default rules apply
```

### Important rule
**Lower number = higher priority**. The first match wins.

---

## NSG Rule Components

Each NSG rule includes:

| Property | Meaning |
|---|---|
| **Priority** | Number between `100` and `4096`; lower wins |
| **Direction** | `Inbound` or `Outbound` |
| **Source / Destination** | IP range, service tag, ASG, or `Any` |
| **Protocol** | `TCP`, `UDP`, `ICMP`, or `Any` |
| **Port** | Single port, range, or `*` |
| **Action** | `Allow` or `Deny` |

---

## Default NSG Rules

Azure includes built-in rules at very low priority precedence (high number values).

### Inbound defaults

| Priority | Rule | Effect |
|---:|---|---|
| `65000` | `AllowVnetInBound` | Allow traffic from the same VNet |
| `65001` | `AllowAzureLoadBalancerInBound` | Allow health probe traffic from Azure Load Balancer |
| `65500` | `DenyAllInBound` | Deny everything else |

### Outbound defaults

| Priority | Rule | Effect |
|---:|---|---|
| `65000` | `AllowVnetOutBound` | Allow traffic to the same VNet |
| `65001` | `AllowInternetOutBound` | Allow internet-bound outbound traffic |
| `65500` | `DenyAllOutBound` | Deny everything else |

Your custom rules normally use priorities such as `100`, `200`, `300`, and so on.

---

## Subnet NSG vs NIC NSG

| Scope | Use case | Guidance |
|---|---|---|
| **Subnet-level NSG** | Baseline policy for a whole workload segment | Preferred default approach |
| **NIC-level NSG** | Exception for one specific VM | Use sparingly |

If both exist, traffic must be allowed by the **effective result** of both scopes. A deny at either layer blocks the traffic.

---

## Stateful Behavior

NSGs are **stateful**.

That means:

- if you allow inbound traffic to port `443`, the response traffic is automatically allowed
- you do **not** need a separate rule for return traffic on the same established flow

This is a frequent exam point.

---

## Service Tags and ASGs

### Service tags
Service tags represent Azure-managed groups of IP ranges, such as:

- `Internet`
- `VirtualNetwork`
- `AzureLoadBalancer`
- `Storage`
- `AzureCloud`

Use them instead of manually maintaining large IP lists.

### Application Security Groups (ASGs)
ASGs let you group VM NICs by role.

Example:

- `web-asg`
- `app-asg`
- `db-asg`

Then your NSG rule can say:

- allow `web-asg` to reach `app-asg` on `TCP 443`
- allow `app-asg` to reach `db-asg` on `TCP 1433`

This is much easier to maintain than IP-based rules when servers scale out or change addresses.

> ASGs are for NIC-based grouping inside Azure VM workloads; they are not a general-purpose grouping feature for every resource type.

---

## Example: Three-Tier App Policy

```text
[Internet]
    |
    v
[web-subnet + web-asg] --443--> [app-subnet + app-asg] --1433--> [data-subnet + db-asg]
```

### Sample security intent

- Allow internet users to `web-asg` on `80/443`
- Allow `web-asg` to `app-asg` on `443`
- Allow `app-asg` to `db-asg` on `1433`
- Deny everything else by default

This design is clearer and safer than a flat, open subnet.

---

## Azure CLI Examples

### Create an NSG

```bash
az network nsg create \
  --resource-group <rg> \
  --name web-nsg \
  --location australiaeast
```

### Add a rule to allow HTTPS inbound

```bash
az network nsg rule create \
  --resource-group <rg> \
  --nsg-name web-nsg \
  --name allow-https-in \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 443 \
  --source-address-prefixes Internet
```

### Create an ASG

```bash
az network asg create \
  --resource-group <rg> \
  --name web-asg \
  --location australiaeast
```

### Inspect effective rules

```bash
az network nic list-effective-nsg \
  --resource-group <rg> \
  --name <nic-name>
```

---

## Best Practices

1. Apply baseline rules at the **subnet level**.
2. Use **NIC NSGs only for exceptions**.
3. Prefer **ASGs and service tags** over raw IP address lists.
4. Keep management ports like `22` and `3389` tightly restricted.
5. Use clear rule naming such as `allow-web-to-app-443`.
6. Review priorities carefully to avoid accidental broad access.

---

## Troubleshooting Checklist

If traffic is blocked unexpectedly:

1. Confirm the NSG is associated with the correct **subnet or NIC**.
2. Check **priority order** and whether another rule matches first.
3. Verify **direction**, **port**, and **protocol** are correct.
4. Review **effective security rules** on the VM NIC.
5. Check whether a **route table** or firewall is also affecting connectivity.

---

## Common Pitfalls and Exam Traps

- Mixing up priority order: `100` beats `200`.
- Allowing traffic on the wrong **direction**.
- Forgetting the default `DenyAllInBound` rule exists.
- Expecting separate return rules even though NSGs are **stateful**.
- Using overly broad `Any -> Any` rules that weaken segmentation.

---

## Key Takeaways

- NSGs are the primary Azure tool for **network traffic filtering**.
- They evaluate rules by **priority**, and the **first match wins**.
- ASGs make policies cleaner and easier to maintain at scale.
- A strong design uses **subnet segmentation + NSGs + least privilege**.

---

## Further Reading

- [Network security groups overview](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Application security groups](https://learn.microsoft.com/en-us/azure/virtual-network/application-security-groups)
- [Tutorial: Filter network traffic with an NSG](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-filter-network-traffic)
