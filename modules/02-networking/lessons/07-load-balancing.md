# Azure Load Balancing Services: Load Balancer, Application Gateway, and Traffic Manager

## Overview

Azure provides multiple traffic distribution services, each operating at different layers and scopes:

- **Azure Load Balancer**: Layer 4 (TCP/UDP), regional, high-performance network load balancing
- **Azure Application Gateway**: Layer 7 (HTTP/HTTPS), web traffic routing and optional WAF
- **Azure Traffic Manager**: DNS-based global traffic distribution and failover

Understanding when to use each is a core AZ-104 competency.

---

## What You Will Learn

- Service selection by network layer and use case
- Health probe and backend pool fundamentals
- Internal vs public load balancing
- Regional vs global traffic distribution patterns
- Common configuration and troubleshooting checks

---

## Decision Architecture

```
 [Client]
    |
    +--> [Azure Load Balancer (L4)] ---> [VM/VMSS backend pool]
    |
    +--> [Application Gateway (L7)] ---> [Web/App backend pool]

 [Traffic Manager (DNS)]
    |
    +--> [Region A endpoint]
    +--> [Region B endpoint]
```

---

## Core Concepts

- **Azure Load Balancer**:
  - Works at TCP/UDP level.
  - Uses health probes to determine backend health.
  - Supports inbound and outbound scenarios.
  - Can be public or internal.
- **Application Gateway**:
  - HTTP/HTTPS-aware routing.
  - Supports host/path-based routing.
  - Optional Web Application Firewall (WAF).
- **Traffic Manager**:
  - DNS-level routing among endpoints.
  - Does not proxy or inspect application data-plane traffic.
  - Supports priorities, weighted routing, performance routing, and failover designs.

---

## Design Guidance

1. Use **Load Balancer** for non-HTTP workloads or simple L4 balancing.
2. Use **Application Gateway** for web apps needing URL/host routing or WAF.
3. Use **Traffic Manager** for cross-region endpoint selection and failover.
4. Always configure and validate health probes before production rollout.
5. Choose internal vs public frontends based on exposure requirements.

---

## Troubleshooting Workflow

1. Confirm frontend IP and listener configuration.
2. Validate backend pool membership and health state.
3. Check health probe settings (path/port/protocol/threshold).
4. Review NSG/route rules affecting backend reachability.
5. For Traffic Manager, validate DNS responses and endpoint health profile.

---

## Common Pitfalls and Exam Traps

- Missing or misconfigured health probes causing zero healthy backends.
- Choosing L4 load balancer where L7 routing is required.
- Using public frontend where internal-only access is required.
- Confusing Traffic Manager (DNS control plane) with packet-level load balancing.

---

## Quick CLI Reference

```bash
# List load balancers
az network lb list -o table

# List backend pool addresses
az network lb address-pool address list \
  --resource-group <rg> --lb-name <lb-name> --pool-name <pool-name>

# List application gateways
az network application-gateway list -o table

# List Traffic Manager profiles
az network traffic-manager profile list -o table
```

---

## Further Reading

- [Azure Load Balancer overview](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-overview)
- [Application Gateway overview](https://learn.microsoft.com/en-us/azure/application-gateway/overview)
- [Traffic Manager overview](https://learn.microsoft.com/en-us/azure/traffic-manager/traffic-manager-overview)

