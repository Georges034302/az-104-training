# Azure Load Balancing Services

> Azure does not have a single “load balancer” product for every need. Administrators must choose the right service based on **network layer**, **scope**, **protocol awareness**, and **traffic pattern**.

---

## Overview

The three core services you must understand for AZ-104 are:

- **Azure Load Balancer** — regional Layer 4 (TCP/UDP)
- **Application Gateway** — regional Layer 7 (HTTP/HTTPS)
- **Traffic Manager** — global DNS-based traffic distribution

A strong administrator knows **when to use each** and what problem each one actually solves.

---

## What You Will Learn

- How to choose between Azure load-balancing services
- Health probes, backend pools, and frontend IP concepts
- Public vs internal load balancing
- Regional vs global traffic distribution
- Common admin examples, troubleshooting steps, and exam traps

---

## Service Comparison

| Service | Layer / Scope | Best for | Key features |
|---|---|---|---|
| **Azure Load Balancer** | Layer 4, regional | TCP/UDP workloads, VM/VMSS distribution | High performance, internal or public frontend, health probes |
| **Application Gateway** | Layer 7, regional | Web applications | Host/path routing, TLS termination, optional WAF |
| **Traffic Manager** | DNS-based, global | Cross-region endpoint selection and failover | Priority, weighted, performance, geographic routing |

> In modern Azure deployments, use **Standard Load Balancer**. The older Basic SKU has been retired.

---

## Azure Load Balancer

Azure Load Balancer works at the transport layer.

### Common components

- **Frontend IP**: the address clients connect to
- **Backend pool**: the VMs or VMSS instances receiving traffic
- **Health probe**: checks whether backend instances are healthy
- **Load-balancing rule**: maps frontend traffic to backend targets
- **Inbound NAT rule**: forwards a specific frontend port to one backend instance

### Typical use cases

- balancing SSH/RDP or custom TCP apps
- distributing web traffic when Layer 7 features are not needed
- internal-only balancing between app tiers

---

## Application Gateway

Application Gateway is designed for **HTTP/HTTPS-aware** workloads.

### Key capabilities

- host-based routing
- path-based routing
- SSL/TLS termination
- session affinity options
- rewrite features
- optional **Web Application Firewall (WAF)**

### Typical use cases

- route `/api` to one backend and `/portal` to another
- route `app.contoso.com` and `admin.contoso.com` differently
- protect web apps with WAF rules

If you need inspection of HTTP headers, URLs, or hostnames, Application Gateway is usually the right choice.

---

## Traffic Manager

Traffic Manager works at the **DNS** layer, not the packet-forwarding layer.

### Important meaning
It answers the question:

> “Which endpoint should the client try first?”

It does **not** proxy the traffic itself.

### Routing methods

| Method | Use case |
|---|---|
| **Priority** | Active/passive failover |
| **Weighted** | Simple distribution by ratio |
| **Performance** | Route users to the lowest-latency endpoint |
| **Geographic** | Direct users by region |
| **Subnet / MultiValue** | Specialized scenarios |

---

## Internal vs Public Load Balancing

### Public frontend
Use when clients connect from the internet.

### Internal frontend
Use when only private Azure or hybrid resources should reach the service.

Example:

- public Application Gateway for internet-facing web tier
- internal Load Balancer for app servers behind the web tier

---

## Example Architectures

### 1. Regional web app with WAF

```text
[Internet] -> [Application Gateway + WAF] -> [Web/App backend]
```

Best fit: **Application Gateway**

### 2. Internal app tier for private VMs

```text
[Web tier] -> [Internal Load Balancer] -> [App tier VMs]
```

Best fit: **Azure Load Balancer**

### 3. Global failover between two regions

```text
[Client DNS query] -> [Traffic Manager]
                          |--> [Region A endpoint]
                          +--> [Region B endpoint]
```

Best fit: **Traffic Manager**

---

## Health Probes Matter

All these services depend on some form of health checking.

If health probes fail:

- the backend may be marked unhealthy
- traffic may stop reaching the service
- the design may look correct but still fail in practice

This is one of the most common operational mistakes.

---

## CLI Reference

### Create a Standard public load balancer

```bash
az network lb create \
  --resource-group <rg> \
  --name web-lb \
  --sku Standard \
  --frontend-ip-name web-frontend \
  --backend-pool-name web-backend \
  --public-ip-address web-lb-pip
```

### Create a health probe

```bash
az network lb probe create \
  --resource-group <rg> \
  --lb-name web-lb \
  --name http-probe \
  --protocol tcp \
  --port 80
```

### Review Traffic Manager profiles

```bash
az network traffic-manager profile list -o table
```

---

## Best Practices

1. Match the service to the **traffic type**: L4 vs L7 vs DNS-level global routing.
2. Always test **health probes** before production cutover.
3. Use **internal** frontends for private-only services.
4. Use **Application Gateway + WAF** for internet-facing web apps that need inspection or protection.
5. Use **Traffic Manager** when the goal is **global endpoint selection**, not packet-level balancing.

---

## Troubleshooting Checklist

If a load-balanced application is unavailable:

1. Confirm the correct **frontend IP / listener** is configured.
2. Check the **backend pool** membership.
3. Review **health probe** settings and results.
4. Check NSGs, UDRs, and backend VM reachability.
5. For Traffic Manager, verify DNS answers and endpoint monitor status.

---

## Common Pitfalls

- Choosing Azure Load Balancer when Layer 7 routing is required.
- Confusing Traffic Manager with an actual proxy or reverse proxy.
- Forgetting health probes, resulting in zero healthy backends.
- Exposing a workload publicly when the requirement was internal-only access.
- Ignoring Standard SKU guidance and older retired patterns.

---

## Key Takeaways

- **Azure Load Balancer** = Layer 4 regional balancing.
- **Application Gateway** = Layer 7 web routing and optional WAF.
- **Traffic Manager** = global DNS-based endpoint selection.
- The right choice depends on **protocol awareness, scope, and traffic intent**.

---

## Advanced: Traffic Distribution Strategy

### Layer Selection by Workload

- Azure Load Balancer for L4 TCP/UDP distribution
- Application Gateway for L7 HTTP(S), WAF, and path-based routing
- Traffic Manager for DNS-based global endpoint selection

### Health and Failover Semantics

Health probes define service availability from the balancer perspective:

- Probe design must reflect true application health
- False-positive health checks cause user-visible failures
- Probe intervals and thresholds influence failover speed

### Session and Routing Behavior

- Understand source IP affinity impact on scale and fault domains
- Validate backend pool behavior during rolling upgrades
- Plan for TLS termination points and certificate lifecycle

## Extended Troubleshooting Matrix (Load Balancing)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Backend never receives traffic | Probe failing or backend not in pool | Check probe status and pool membership | Correct probe path/port and backend registration |
| Intermittent user failures | Uneven backend health or app-level dependency | Correlate probe and app logs per backend | Fix unhealthy instance and dependencies |
| TLS errors at edge | Certificate mismatch or expired cert | Verify listener cert and hostname binding | Renew/replace certificate and binding |
| Region failover not occurring | Traffic Manager endpoint state unhealthy logic mis-set | Review TM routing method and endpoint monitor config | Correct monitor settings and test failover |

## Production Readiness Checklist (Load Balancing)

- Service selected by protocol and routing requirements
- Health probes validated against real application health
- Backend scale and drain behavior tested
- TLS termination model documented and monitored
- Regional failover tests executed and recorded
- Alerting configured for probe failure and backend degradation


---

## Further Reading

- [Azure Load Balancer overview](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-overview)
- [Application Gateway overview](https://learn.microsoft.com/en-us/azure/application-gateway/overview)
- [Traffic Manager overview](https://learn.microsoft.com/en-us/azure/traffic-manager/traffic-manager-overview)
