# Load Balancing Overview (LB, App Gateway, Traffic Manager)

## What you will learn
- What each service does
- How to choose based on layer
- Common admin tasks

## Concept flow architecture
```mermaid
flowchart LR
  Client --> L4[Load Balancer (L4)] --> VM1[VM]
  L4 --> VM2[VM]
  Client --> L7[Application Gateway (L7)] --> App1[App]
  DNS[Traffic Manager] --> RegionA[Region A]
  DNS --> RegionB[Region B]
```

## Key concepts (AZ-104 focus)
- Load Balancer is L4 (TCP/UDP) and distributes traffic to backend pools.
- Application Gateway is L7 (HTTP/S) with routing and WAF options.
- Traffic Manager is DNS-based global distribution/failover.

## Admin mindset
- For AZ-104, focus on Load Balancer basics and knowing when App Gateway is used.
- Validate health probes and backend pool associations.
- Keep demo labs minimal to avoid cost (App Gateway can be expensive).

## Common pitfalls / exam traps
- Forgetting health probe configuration causes traffic drop.
- Using public LB when internal LB is required.
- Confusing Traffic Manager (DNS) with data-plane load balancing.

## Quick CLI signals (read-only examples)
> These are **signals** you look for as an administrator. They are not a full lab.
```bash
# az <service> <command> ... 
```
