# Private Endpoints and Service Endpoints: Choosing the Right PaaS Access Model

## Overview

Azure offers two common patterns for securing access from VNets to PaaS services:

- **Private Endpoint (Azure Private Link)**: Maps a service to a private IP in your VNet.
- **Service Endpoint**: Extends subnet identity to Azure services while service endpoints remain public.

For AZ-104, you must clearly differentiate these models and know when each is appropriate.

---

## What You Will Learn

- How private endpoints work and why DNS is critical
- How service endpoints differ in network path and exposure
- Security and governance implications of each model
- Selection criteria for real-world scenarios
- Validation and troubleshooting steps

---

## Connectivity Model

```
 [Client in VNet]
        |
        +--> [Private Endpoint NIC (private IP)] ---> [Azure PaaS Service]
        |
        +--> [Service Endpoint-enabled subnet] -----> [Azure PaaS Service (public endpoint)]
```

---

## Private Endpoint: Key Points

- Creates a NIC with a private IP in your subnet.
- Traffic stays private from client to service entry point.
- Typically paired with `privatelink` private DNS zones.
- Supports strong isolation patterns and reduced public exposure.

Important: Private networking does not replace service authorization controls. RBAC/SAS/keys/policies still apply.

---

## Service Endpoint: Key Points

- Extends subnet identity to supported Azure services.
- Access is still to service public endpoint, but source identity/policy is subnet-aware.
- Service endpoints are available only for supported Azure service types.
- Simpler for some scenarios, but less private than Private Link.

---

## Selection Guidance

- Choose **Private Endpoint** when:
    - You need private IP-based access.
    - You want to minimize or disable public access.
    - You require stronger isolation and private DNS control.
- Choose **Service Endpoint** when:
    - Private Link isn’t required.
    - You need simpler subnet-based access restrictions.
    - Public endpoint path is acceptable.

---

## Troubleshooting Workflow

1. Confirm endpoint type configured (private vs service endpoint).
2. For private endpoints, validate DNS resolves to private IP.
3. Check subnet policies and endpoint status.
4. Verify service firewall/network access settings.
5. Validate authorization separately (RBAC, key/SAS, ACL).

---

## Common Pitfalls and Exam Traps

- Creating a private endpoint but leaving DNS unresolved to public endpoint.
- Assuming private endpoint alone grants data access permissions.
- Confusing service endpoints with private IP connectivity.
- Forgetting to align service firewall settings with endpoint model.

---

## Quick CLI Reference

```bash
# Create private endpoint (example skeleton)
az network private-endpoint create \
    --resource-group <rg> --name <pe-name> --vnet-name <vnet> --subnet <subnet> \
    --private-connection-resource-id <service-resource-id> \
    --group-id <group-id> --connection-name <conn-name>

# Enable service endpoint on subnet
az network vnet subnet update \
    --resource-group <rg> --vnet-name <vnet> --name <subnet> \
    --service-endpoints Microsoft.Storage
```

---

## Further Reading

- [What is a private endpoint?](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [Virtual network service endpoints](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview)

