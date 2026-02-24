# Private Endpoints vs Service Endpoints

## What you will learn
- What private endpoints solve
- How they differ from service endpoints
- When AZ-104 expects each

## Concept flow architecture
```mermaid
flowchart LR
  Client[Client in VNet] --> PE[Private Endpoint (NIC)]
  PE --> Service[Azure PaaS Service]
  Client --> SE[Service Endpoint (Subnet Policy)]
  SE --> Service
```

## Key concepts (AZ-104 focus)
- Private Endpoint gives a private IP for a PaaS service and supports private DNS patterns.
- Service Endpoint extends VNet identity to a service but still uses public IPs of the service.
- AZ-104 commonly tests configuration steps and key differences.

## Admin mindset
- Use Private Endpoint when you want no public exposure and private DNS resolution.
- Use Service Endpoint when private endpoint is not required and you want subnet-based restrictions.
- Always validate by resolving service name and checking IP is private when using PE.

## Common pitfalls / exam traps
- Forgetting private DNS causes clients to still resolve public endpoint.
- Assuming PE removes need for RBAC/SAS on storage (it doesn’t).
- Putting PE into a subnet with restrictive policies without planning.

## Quick CLI signals (read-only examples)
> These are **signals** you look for as an administrator. They are not a full lab.
```bash
# az <service> <command> ... 
```
