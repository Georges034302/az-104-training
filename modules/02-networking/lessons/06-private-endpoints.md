# Private Endpoints and Service Endpoints

> Azure offers two major ways to secure VNet-to-PaaS access: **Private Endpoints** for truly private IP connectivity, and **Service Endpoints** for subnet-based access to a still-public service endpoint.

---

## Overview

When Azure VMs or applications need to reach services such as Storage, SQL Database, or Key Vault, you should avoid leaving access wide open from any network.

Two common controls are:

- **Private Endpoint (Private Link)**
- **Service Endpoint**

They sound similar, but they solve the problem in different ways.

---

## What You Will Learn

- How private endpoints work
- How service endpoints differ from private endpoints
- When to choose one over the other
- Why DNS and authorization still matter
- Common scenarios, examples, and exam traps

---

## Quick Comparison

| Feature | Private Endpoint | Service Endpoint |
|---|---|---|
| Network path | Private IP in your VNet | Service public endpoint |
| Exposure model | Can reduce or disable public access | Service still has a public endpoint |
| DNS impact | Critical; usually requires `privatelink` DNS | Usually less DNS change |
| Security model | Stronger private isolation | Subnet-based restriction to public service |
| Typical use | Highly secure access to PaaS | Simpler trusted-subnet access |

---

## How a Private Endpoint Works

A private endpoint creates a **network interface** in your subnet with a **private IP address**. Your workload then connects to the PaaS service using that private path.

```text
[VM / App in VNet]
        |
        v
[Private Endpoint NIC: 10.20.10.4]
        |
        v
[Azure Storage / SQL / Key Vault over Private Link]
```

### Key points

- The service appears reachable through a private IP inside your VNet.
- It is commonly paired with a **private DNS zone**.
- You can often disable **public network access** on the service after validation.
- Private endpoint approval can be automatic or manual depending on the scenario and permissions.

---

## How a Service Endpoint Works

A service endpoint does **not** place the service on a private IP in your VNet.

Instead, it extends the subnet’s identity to supported Azure services so the service firewall can trust that subnet.

```text
[VM / App in subnet with service endpoint enabled]
        |
        v
[Public endpoint of Azure service]
        |
        v
[Access allowed because subnet identity is trusted]
```

### Key points

- Simpler to configure than Private Link in many cases
- Still uses the service’s public endpoint
- Useful when private IP connectivity is not mandatory
- Commonly used with Storage or SQL firewall restrictions

---

## Important Difference: Network Privacy vs Network Restriction

- **Private Endpoint** = private IP path to the service
- **Service Endpoint** = public endpoint remains, but access can be limited to trusted subnets

This distinction appears frequently in AZ-104 questions.

---

## Authorization Still Matters

Neither feature replaces service-level permissions.

Even if the network path is correct, the user or application may still need:

- Azure RBAC
- SAS token
- access key
- Key Vault access policy / RBAC
- database login or app authorization

### Exam reminder
**Network access and identity authorization are separate controls.**

---

## DNS Considerations for Private Endpoints

Private endpoints depend heavily on DNS.

Without correct DNS:

- the client may still resolve the service name to its **public** IP
- traffic may bypass the intended private path
- the service may appear unreachable or misconfigured

Typical example:

- private DNS zone: `privatelink.blob.core.windows.net`
- storage account record resolves to the private endpoint IP

---

## When to Choose Which Option

### Choose **Private Endpoint** when:

- you need **private IP-based connectivity**
- you want to **minimize or disable public exposure**
- the workload is security-sensitive
- the exam scenario emphasizes **private access**, **isolation**, or **Private Link**

### Choose **Service Endpoint** when:

- you want a simpler configuration
- the service can still use a public endpoint
- subnet-based restriction is enough
- the requirement is “allow access only from this subnet or VNet” without full private-link design

---

## Example Scenarios

### 1. Secure storage access for production app

Best choice: **Private Endpoint**

Reason: traffic stays private, DNS can point to a private IP, and public access can be disabled.

### 2. Quick restriction of a storage account to one app subnet

Best choice: **Service Endpoint**

Reason: simpler and fast when public endpoint use is acceptable.

### 3. Key Vault used by internal workloads only

Best choice: usually **Private Endpoint** for stronger isolation.

---

## Azure CLI Examples

### Create a private endpoint

```bash
az network private-endpoint create \
  --resource-group <rg> \
  --name storage-pe \
  --vnet-name prod-vnet \
  --subnet private-endpoints \
  --private-connection-resource-id <storage-resource-id> \
  --group-id blob \
  --connection-name storage-pe-conn
```

### Enable a service endpoint on a subnet

```bash
az network vnet subnet update \
  --resource-group <rg> \
  --vnet-name prod-vnet \
  --name app-subnet \
  --service-endpoints Microsoft.Storage
```

### Check private endpoint details

```bash
az network private-endpoint show \
  --resource-group <rg> \
  --name storage-pe
```

---

## Best Practices

1. Prefer **Private Endpoint** for high-security or compliance-sensitive workloads.
2. Place private endpoints in a **dedicated subnet** where practical.
3. Configure **private DNS zones** as part of the same change.
4. Disable public network access on the service when the design supports it.
5. Remember that network access does not replace **RBAC or data-plane authorization**.

---

## Troubleshooting Checklist

If the private access design fails:

1. Confirm whether the resource uses a **private endpoint** or **service endpoint**.
2. For private endpoints, verify the DNS name resolves to the **private IP**.
3. Confirm the private endpoint is **Approved** and in a healthy state.
4. Check the service firewall or network access settings.
5. Validate RBAC, SAS, keys, or service authorization separately.

---

## Common Pitfalls and Exam Traps

- Confusing service endpoints with private IP connectivity.
- Creating a private endpoint but forgetting the DNS integration.
- Assuming private network access automatically grants data access.
- Leaving public network access enabled when the goal was strict private-only access.
- Treating “endpoint” terminology as if both services work the same way.

---

## Key Takeaways

- **Private Endpoint** provides a **private IP path** to a supported Azure service.
- **Service Endpoint** restricts a **public endpoint** to trusted subnets.
- Private endpoints are more secure, but they are also more DNS-dependent.
- In Azure administration, always think about **network path + DNS + authorization** together.

---

## Further Reading

- [Private endpoint overview](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [Private Link service and private endpoint DNS](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
- [Virtual network service endpoints overview](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview)
