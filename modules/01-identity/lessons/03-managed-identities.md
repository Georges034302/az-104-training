# Managed Identities (System vs User-assigned)

> **Managed Identities** eliminate the need to store credentials in code or configuration.  
> Azure automatically manages the identity lifecycle and token acquisition, providing a **secure, credential-free** way for Azure resources to access other Azure services.

**The promise:** Your application code never touches credentials. Azure handles it all transparently.

**The reality:** You still need to understand when to use which type, how to assign roles, and how to troubleshoot when authentication fails.

---

## Overview

Managed Identities solve the **credential management problem** for Azure-to-Azure authentication:

- **No secrets in code** - Azure manages credentials automatically (hidden from developers)
- **Automatic rotation** - Credentials rotated without application changes
- **Seamless integration** - Works with all Entra ID authentication-enabled services
- **Zero-trust architecture** - Identity-based access (not network-based)
- **Reduced attack surface** - No credentials to leak in source code, logs, or core dumps

**Why not just use app registration + secrets?**

App Registration (Service Principal) with secrets:
- ❌ Developer must manage secrets (store safely, rotate regularly)
- ❌ Secrets can leak (hardcoded, logged, exposed in git history)
- ❌ Secrets expire and break deployments if not rotated
- ❌ All VMs running same script share same secret (revocation is all-or-nothing)

Managed Identity:
- ✅ Azure manages credentials (developer never sees them)
- ✅ Credentials auto-rotated (invisible to app)
- ✅ Credentials never expire (Azure handles lifecycle)
- ✅ Each resource has unique identity (fine-grained revocation)

**Recommendation:** Always use Managed Identity when running on Azure. Use Service Principal only for external apps (on-premises, partner systems).

---

## What You Will Learn

- What managed identities are and why they matter
- **System-assigned** vs **User-assigned** - when to use each
- How the **IMDS endpoint** (169.254.169.254) provides tokens
- The lifecycle and behavior of each MI type
- Enabling managed identities across Azure services (VM, App Service, Functions, etc.)
- **Token acquisition** workflow and code examples (bash, Python, PowerShell)
- Role assignments for managed identities (binding MI to actual permissions)
- Common integration patterns (Storage, Key Vault, SQL)
- Troubleshooting MI issues (tokens not working, permissions denied)
- Real admin workflows and exam-grade pitfalls
- Migration from secrets to MI (common scenarios)

---

## Mental Model: Managed Identity Flow

```text
+------------------------------------------+
| Azure Resource                           |
| VM / App Service / Function              |
+------------------------------------------+
      | App calls local endpoint
      v
+------------------------------------------+
| IMDS (169.254.169.254)                   |
| Azure's local token service              |
+------------------------------------------+
      | IMDS gets token from
      v
+------------------------------------------+
| Microsoft Entra ID                       |
| Creates token for this resource          |
+------------------------------------------+
      | Token returned
      v
+------------------------------------------+
| Access Token (JWT)                       |
| Valid for ~1 hour                        |
+------------------------------------------+
      | App uses token to call
      v
+------------------------------------------+
| Target Service                           |
| Storage / Key Vault / SQL                |
+------------------------------------------+
      | Service checks RBAC
      v
+------------------------------------------+
| Is token + permission valid?              |
+------------------------------------------+
     | Yes                            | No
     v                                v
+---------------------------+    +---------------------------+
| Authorized Access         |    | 403 Forbidden             |
+---------------------------+    +---------------------------+
```

**Key points:**
1. **Application never handles credentials** - Azure handles token acquisition transparently
2. **IMDS endpoint is local** - 169.254.169.254 is only accessible from within the Azure resource
3. **Token is automatically refreshed** - Handled transparently before expiration
4. **RBAC still applies** - Managed identity must have role assignment to the target resource

---

## Types of Managed Identities

### System-Assigned Managed Identity

**Lifecycle:** Tied directly to a single Azure resource

```text
Nodes:
+----------------------------------------------------+
| Virtual Machine                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| System-assigned Managed Identity                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Storage Account                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Identity automatically deleted                     |
+----------------------------------------------------+

```

**Characteristics:**
- ✅ One-to-one relationship (1 identity per resource)
- ✅ Automatically deleted when parent resource is deleted
- ✅ Simpler for single-resource scenarios
- ❌ Cannot be shared across resources
- ❌ Deleted if resource is deleted (cannot preserve identity)

**When to use:**
- Single resource needs access to other services
- Identity lifecycle matches resource lifecycle
- No need to share identity across multiple resources

---

### User-Assigned Managed Identity

**Lifecycle:** Independent Azure resource that can be shared

```text
Nodes:
+----------------------------------------------------+
| User-assigned Managed Identity                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Virtual Machine                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| App Service                                        |
+----------------------------------------------------+
+----------------------------------------------------+
| Function App                                       |
+----------------------------------------------------+
+----------------------------------------------------+
| Storage Account                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| VM deleted                                         |
+----------------------------------------------------+

```

**Characteristics:**
- ✅ Can be assigned to multiple resources
- ✅ Independent lifecycle (survives resource deletion)
- ✅ Reusable across environments
- ✅ Supports advanced scenarios (failover, DR)
- ❌ Requires manual creation and deletion
- ❌ More complex to manage

**When to use:**
- Multiple resources need same permissions
- Identity should persist beyond resource lifecycle
- Disaster recovery scenarios requiring identity preservation
- Terraform/IaC where identity is managed separately

---

## Decision Tree: System vs User-Assigned

```text
Nodes:
+----------------------------------------------------+
| Need managed identity?                             |
+----------------------------------------------------+
+----------------------------------------------------+
| Multiple resources need same identity?             |
+----------------------------------------------------+
+----------------------------------------------------+
| Use service principal with secrets                 |
+----------------------------------------------------+
+----------------------------------------------------+
| User-assigned Managed Identity                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Identity must persist beyond resource?             |
+----------------------------------------------------+
+----------------------------------------------------+
| Simple use case?                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| System-assigned Managed Identity                   |
+----------------------------------------------------+

```

**Quick guide:**
- **System-assigned:** Default choice for simple scenarios
- **User-assigned:** When sharing identity or preserving identity across resource lifecycles

---

## The IMDS Endpoint (Instance Metadata Service) - Detailed

### What is IMDS?

**IMDS (Instance Metadata Service)** is a REST API endpoint available **only from within Azure resources** at the special IP address `http://169.254.169.254`.

**Think of it as:** "Local identity service running on every Azure resource that can hand you tokens on demand."

**Characteristics:**
- ✅ Non-routable IP (169.254.169.254 is link-local; only accessible from within the resource)
- ✅ No authentication required (you're already running in the Azure resource)
- ✅ Provides several types of metadata about the resource instance
- ✅ **Token endpoint** for managed identities (primary use for MI)
- ✅ Available without any setup (built into Azure resource, always running)

**Why this special IP?**
- 169.254.0.0/16 is a link-local range (not routable over internet)
- Means it's ONLY accessible from within the Azure resource
- Cannot be accessed from external networks or on-premises
- Cannot be blocked by network security groups (it's internal to Azure fabric)

### IMDS Request-Response Example

**Request:**
```bash
# Get token for Azure Storage
curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/' \
  -H "Metadata: true"
```

**Required parameters:**
- `api-version=2018-02-01` (IMDS API version)
- `resource=https://storage.azure.com/` (what resource do you want a token for?)
- `Metadata: true` (required header to identify as metadata request)

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IjloSUhJT3NWdTFXREVTRV...",
  "expires_in": "3599",
  "expires_on": "1645678123",
  "ext_expires_in": "3599",
  "not_before": "1645674523",
  "resource": "https://storage.azure.com/",
  "token_type": "Bearer",
  "client_id": "00000000-0000-0000-0000-000000000000"
}
```

**Key fields:**
- `access_token`: JWT that can be used with Azure services
- `expires_in`: Seconds until token expires (usually 3600 = 1 hour)
- `expires_on`: Unix timestamp when token expires
- `resource`: Confirms which resource this token is for

### Common Resource Endpoints (Token Requests)

| Service | Resource URL | Use Case |
|---------|--------------|----------|
| **Azure Storage** | `https://storage.azure.com/` | Read/write blobs, files, tables |
| **Key Vault** | `https://vault.azure.net/` | Access secrets, keys, certificates |
| **Azure SQL** | `https://database.windows.net/` | Query SQL databases |
| **Azure Resource Manager** | `https://management.azure.com/` | Manage resources (rare for app code) |
| **Microsoft Graph** | `https://graph.microsoft.com/` | Access Microsoft 365 APIs |
| **Azure Cosmos DB** | `https://cosmos.azure.com/` | Query Cosmos databases |

### IMDS Architecture (Simplified)

```text
+------------------------------------------+
| Application Code                         |
| (running on Azure resource)              |
+------------------------------------------+
          | GET http://169.254.169.254/metadata/...
          |
          v
+------------------------------------------+
| Azure Fabric                             |
| (intercepts 169.254.169.254 traffic)     |
+------------------------------------------+
          | Requests token from
          v
+------------------------------------------+
| Microsoft Entra ID                       |
| (issues tokens)                          |
+------------------------------------------+
          | Returns token
          v
+------------------------------------------+
| Response to application                  |
+------------------------------------------+
```

**Why intercept at the fabric?**
- Application code doesn't need to know about Entra ID URLs
- Application always uses local 169.254.169.254
- Fabric handles all Entra ID communication
- Result: Extremely simple for application developers

---

## Enabling Managed Identities

### Virtual Machine (System-assigned)

**Portal:**
1. VM → **Identity** → System assigned → **On** → Save

**CLI:**
```bash
# Enable system-assigned MI on existing VM
az vm identity assign --name <vm-name> --resource-group <rg-name>

# Create VM with system-assigned MI enabled
az vm create \
  --name myVM \
  --resource-group myRG \
  --image UbuntuLTS \
  --assign-identity \
  --role Contributor \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>
```

**Get principal ID:**
```bash
# Get the managed identity's principal ID (for role assignments)
PRINCIPAL_ID=$(az vm identity show \
  --name <vm-name> \
  --resource-group <rg-name> \
  --query principalId -o tsv)
echo $PRINCIPAL_ID
```

---

### App Service / Function App (System-assigned)

**Portal:**
1. App Service → **Identity** → System assigned → **On** → Save

**CLI:**
```bash
# Enable system-assigned MI on App Service
az webapp identity assign \
  --name <app-name> \
  --resource-group <rg-name>

# Get principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name <app-name> \
  --resource-group <rg-name> \
  --query principalId -o tsv)
```

---

### User-Assigned Managed Identity

**Create user-assigned MI:**
```bash
# Create user-assigned managed identity
az identity create \
  --name myUserMI \
  --resource-group myRG \
  --location eastus

# Get identity details
IDENTITY_ID=$(az identity show \
  --name myUserMI \
  --resource-group myRG \
  --query id -o tsv)
PRINCIPAL_ID=$(az identity show \
  --name myUserMI \
  --resource-group myRG \
  --query principalId -o tsv)
```

**Assign to VM:**
```bash
# Assign user-assigned MI to VM
az vm identity assign \
  --name <vm-name> \
  --resource-group <rg-name> \
  --identities "$IDENTITY_ID"
```

**Assign to App Service:**
```bash
# Assign user-assigned MI to App Service
az webapp identity assign \
  --name <app-name> \
  --resource-group <rg-name> \
  --identities "$IDENTITY_ID"
```

---

## Token Acquisition in Code

### Bash (from VM)

```bash
#!/bin/bash
# Get token for Azure Storage
TOKEN=$(curl -H Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" \
  | jq -r '.access_token')

# Use token to access Storage
curl -H "Authorization: Bearer $TOKEN" \
  -H "x-ms-version: 2019-12-12" \
  "https://<storage-account>.blob.core.windows.net/<container>?restype=container&comp=list"
```

### Python

```python
import requests
import json

# IMDS endpoint for managed identity token
imds_url = "http://169.254.169.254/metadata/identity/oauth2/token"
params = {
    "api-version": "2018-02-01",
    "resource": "https://storage.azure.com/"  # Target resource
}
headers = {"Metadata": "true"}

# Get token
response = requests.get(imds_url, params=params, headers=headers)
token = response.json()["access_token"]

# Use token to access Azure Storage
storage_url = "https://<storage-account>.blob.core.windows.net/<container>?restype=container&comp=list"
storage_headers = {
    "Authorization": f"Bearer {token}",
    "x-ms-version": "2019-12-12"
}
storage_response = requests.get(storage_url, headers=storage_headers)
print(storage_response.text)
```

### PowerShell

```powershell
# Get token for Key Vault
$response = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' `
  -Headers @{Metadata="true"}
$token = $response.access_token

# Use token to access Key Vault secret
$vaultName = "myKeyVault"
$secretName = "mySecret"
$secretUrl = "https://$vaultName.vault.azure.net/secrets/$secretName?api-version=7.2"
$secret = Invoke-RestMethod -Uri $secretUrl -Headers @{Authorization="Bearer $token"}
Write-Host $secret.value
```

---

## Role Assignments for Managed Identities

### Pattern: MI → Role → Target Service

```text
Nodes:
+----------------------------------------------------+
| Managed Identity VM/App Service                    |
+----------------------------------------------------+
+----------------------------------------------------+
| RBAC Role Storage Blob Data Contributor            |
+----------------------------------------------------+
+----------------------------------------------------+
| Storage Account                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Entra ID                                           |
+----------------------------------------------------+
+----------------------------------------------------+
| RBAC Check                                         |
+----------------------------------------------------+
+----------------------------------------------------+
| Access                                             |
+----------------------------------------------------+

```

### Common Role Assignments

**Storage Account:**
```bash
# Grant managed identity access to blob storage
az role assignment create \
  --assignee <principal-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>
```

**Key Vault:**
```bash
# Grant managed identity access to Key Vault secrets
az role assignment create \
  --assignee <principal-id> \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>
```

**Azure SQL Database:**
```sql
-- Connect to database as Azure AD admin
-- Create user for managed identity
CREATE USER [myVM] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [myVM];
ALTER ROLE db_datawriter ADD MEMBER [myVM];
```

---

## Common Integration Patterns

### Pattern 1: VM → Storage Account

**Scenario:** VM needs to read/write blob data

```text
Nodes:
+----------------------------------------------------+
| Virtual Machine                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Managed Identity                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Storage Account                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| 169.254.169.254                                    |
+----------------------------------------------------+

```

**Implementation:**
```bash
# 1. Enable system MI on VM
az vm identity assign --name myVM --resource-group myRG

# 2. Get principal ID
PRINCIPAL_ID=$(az vm identity show --name myVM --resource-group myRG --query principalId -o tsv)

# 3. Assign Storage Blob Data Contributor role
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>

# 4. From VM, get token and access storage (see code examples above)
```

---

### Pattern 2: App Service → Key Vault

**Scenario:** App Service needs to retrieve secrets from Key Vault

```text
Nodes:
+----------------------------------------------------+
| App Service                                        |
+----------------------------------------------------+
+----------------------------------------------------+
| Managed Identity                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Key Vault                                          |
+----------------------------------------------------+
+----------------------------------------------------+
| 169.254.169.254                                    |
+----------------------------------------------------+

```

**Implementation:**
```bash
# 1. Enable system MI on App Service
az webapp identity assign --name myApp --resource-group myRG

# 2. Get principal ID
PRINCIPAL_ID=$(az webapp identity show --name myApp --resource-group myRG --query principalId -o tsv)

# 3. Assign Key Vault Secrets User role
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>

# 4. In app code, use Azure SDK to access Key Vault with managed identity
```

---

### Pattern 3: Function → SQL Database

**Scenario:** Azure Function needs to query SQL Database

```text
Nodes:
+----------------------------------------------------+
| Azure Function                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Managed Identity                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Azure SQL Database                                 |
+----------------------------------------------------+
+----------------------------------------------------+
| 169.254.169.254                                    |
+----------------------------------------------------+

```

**Implementation:**
```bash
# 1. Enable system MI on Function
az functionapp identity assign --name myFunction --resource-group myRG

# 2. In SQL, create user for managed identity (see SQL example above)
```

**Connection string:**
```csharp
// C# example
var connectionString = "Server=tcp:myserver.database.windows.net;Database=mydb;";
var connection = new SqlConnection(connectionString);
connection.AccessToken = GetAccessToken("https://database.windows.net/");
```

---

## Cross-Subscription and Cross-Tenant Access

### Cross-Subscription Access

✅ **Supported** - Managed identity can access resources in different subscriptions within the **same tenant**

```bash
# Assign MI to storage account in different subscription
az role assignment create \
  --assignee <principal-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<other-sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>
```

### Cross-Tenant Access

❌ **Not supported** - Managed identities cannot authenticate across Entra ID tenants

**Alternative:** Use service principals with federated credentials (advanced topic).

---

## Troubleshooting Managed Identities

### Common Issues Checklist

```text
Nodes:
+----------------------------------------------------+
| Access Denied                                      |
+----------------------------------------------------+
+----------------------------------------------------+
| MI enabled on resource?                            |
+----------------------------------------------------+
+----------------------------------------------------+
| Enable managed identity                            |
+----------------------------------------------------+
+----------------------------------------------------+
| Role assigned to MI?                               |
+----------------------------------------------------+
+----------------------------------------------------+
| Assign appropriate RBAC role                       |
+----------------------------------------------------+
+----------------------------------------------------+
| Correct scope?                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Adjust role assignment scope                       |
+----------------------------------------------------+
+----------------------------------------------------+
| Propagated?                                        |
+----------------------------------------------------+
+----------------------------------------------------+
| Wait 5-10 minutes                                  |
+----------------------------------------------------+
+----------------------------------------------------+
| Getting token?                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Check IMDS connectivity                            |
+----------------------------------------------------+
+----------------------------------------------------+
| Target service supports MI?                        |
+----------------------------------------------------+

```

### Validation Commands

```bash
# Check if system MI is enabled on VM
az vm identity show --name <vm-name> --resource-group <rg-name>

# List role assignments for managed identity
az role assignment list --assignee <principal-id> --all -o table

# Test IMDS endpoint from within VM/App Service
curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq

# Get token for specific resource
curl -H Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" \
  | jq
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `AADSTS70001: Application not found` | MI not enabled | Enable managed identity on resource |
| `403 Forbidden` | No role assignment | Assign appropriate role to MI principal |
| `The managed identity has not been assigned this role` | Wrong scope or missing role | Check role assignment scope |
| `Could not connect to IMDS` | Network issue or not running on Azure | Verify running on Azure resource |
| `MSI not available` | MI not enabled or runtime not initialized | Enable MI and restart resource |

---

## Best Practices

✅ **Prefer managed identities** over service principals with secrets  
✅ **Use system-assigned MI** as default (simpler)  
✅ **Use user-assigned MI** for shared identity or DR scenarios  
✅ **Assign data-plane roles** (Storage Blob Data Contributor, not Contributor)  
✅ **Scope roles narrowly** (storage account level, not subscription)  
✅ **Test token acquisition** before deploying to production  
✅ **Monitor sign-in logs** for managed identity usage  
✅ **Document MI dependencies** in infrastructure-as-code  
✅ **Use latest IMDS API version** (2021-02-01 or newer)

---

## Common Pitfalls

❌ **Enabling MI but forgetting role assignment**  
MI provides identity, not permissions. Must assign RBAC role.

❌ **Assigning Contributor instead of data-plane role**  
Contributor grants control-plane access, not blob/queue/secret access.

❌ **Using system MI when user MI is appropriate**  
System MI is deleted with resource; use user MI for shared scenarios.

❌ **Assuming MI works across tenants**  
MI is tenant-scoped; use service principals for cross-tenant.

❌ **Not waiting for propagation**  
Role assignments take 5-10 minutes to propagate.

❌ **Hardcoding IMDS endpoint in application**  
Use Azure SDK libraries that handle IMDS automatically.

❌ **Forgetting to test from within Azure resource**  
IMDS is only accessible from Azure resources, not local development.

❌ **Using wrong resource URI in token request**  
Each service has specific resource URI (https://storage.azure.com/, https://vault.azure.net/, etc.)

---

## Key Takeaways

1. **Managed identities = credential-free authentication** for Azure resources
2. **System-assigned** = 1:1 with resource (default choice)
3. **User-assigned** = reusable across resources (advanced scenarios)
4. **IMDS endpoint** (169.254.169.254) provides tokens automatically
5. **Role assignment required** - MI provides identity, not permissions
6. **Data-plane roles** for resource data access (not Contributor)
7. **Cross-subscription supported**, cross-tenant not supported
8. **No secrets in code** - Azure SDK handles token acquisition
9. **Propagation delay** = 5-10 minutes for role assignments
10. **Best for Azure-to-Azure** authentication (VMs, App Services, Functions)

---

## CLI Reference

### Enable Managed Identities

```bash
# Enable system-assigned MI on VM
az vm identity assign --name <vm-name> --resource-group <rg-name>

# Enable system-assigned MI on App Service
az webapp identity assign --name <app-name> --resource-group <rg-name>

# Create user-assigned MI
az identity create --name <identity-name> --resource-group <rg-name>

# Assign user-assigned MI to VM
az vm identity assign --name <vm-name> --resource-group <rg-name> --identities <identity-id>
```

### Get Identity Information

```bash
# Get principal ID from system-assigned MI
az vm identity show --name <vm-name> --resource-group <rg-name> --query principalId -o tsv

# Get user-assigned MI details
az identity show --name <identity-name> --resource-group <rg-name>
```

### Assign Roles to Managed Identity

```bash
# Assign Storage Blob Data Contributor
az role assignment create \
  --assignee <principal-id> \
  --role "Storage Blob Data Contributor" \
  --scope <storage-account-resource-id>

# Assign Key Vault Secrets User
az role assignment create \
  --assignee <principal-id> \
  --role "Key Vault Secrets User" \
  --scope <key-vault-resource-id>
```

### Test Token Acquisition

```bash
# Get token for Azure Storage (from within Azure resource)
curl -H Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" \
  | jq

# Get token for Key Vault
curl -H Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net/" \
  | jq
```

---

## Advanced: Token Request Semantics

Managed identity authentication still follows OAuth token audience rules.

Critical requirement:

- Request token for the correct target resource URI

Examples:

- Storage data plane: `https://storage.azure.com/`
- Key Vault: `https://vault.azure.net`
- Azure SQL: `https://database.windows.net/`
- ARM management plane: `https://management.azure.com/`

Wrong audience is a common reason for authorization failure even when role assignment is correct.

---

## Advanced: User-Assigned Identity Selection

If multiple user-assigned managed identities are attached to a resource, token requests must specify which identity to use.

Selection options commonly include:

- client ID
- object ID
- resource ID

Operational risk:

- If identity selector is omitted in multi-identity scenarios, application may use unintended identity or fail token acquisition.

---

## Advanced: Azure SDK Authentication Chain

In production-grade code, prefer Azure SDK credential abstractions rather than raw IMDS calls.

Typical `DefaultAzureCredential` behavior:

1. Local development credentials (CLI, VS Code, etc.)
2. Environment credentials (if configured)
3. Managed identity credential in Azure runtime

Benefits:

- Same code path across local dev and cloud runtime
- Better token caching and retry behavior
- Less custom authentication code to maintain

---

## Advanced: Performance and Reliability Considerations

### Token Caching

Best practice:

- Reuse SDK clients and credential instances
- Do not request a new token for every single operation

Reason:

- Excessive token calls add latency and can create avoidable throttling pressure.

### Transient Failures

Implement resilient retries for:

- temporary network interruptions
- short-lived IMDS timeouts
- brief service-side throttling

Use bounded exponential backoff and idempotent request patterns.

---

## Advanced: Security Hardening with Managed Identities

Managed identity removes secrets, but least privilege is still mandatory.

Hardening controls:

- Narrow role scopes to specific resource IDs where possible
- Use data-plane roles instead of broad Contributor where appropriate
- Separate identities by workload trust level
- Monitor sign-ins and role assignments for managed identities
- Remove unused user-assigned identities

Anti-patterns to avoid:

- Reusing one user-assigned identity for unrelated high/low trust workloads
- Granting subscription-wide Contributor to MI that only needs one storage account

---

## Advanced: Incident Troubleshooting Matrix

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| `MSI not available` | MI disabled or runtime startup issue | Check identity blade / CLI identity show | Enable MI and restart workload |
| Token retrieval timeout | Network/runtime transient | Test IMDS metadata endpoint | Add retries and verify runtime health |
| `403 Forbidden` on target service | Missing role or wrong scope | List MI role assignments | Assign correct role at correct scope |
| Works after delay only | Propagation/token cache delay | Check assignment timestamp | Wait, refresh token path, retry |
| Wrong data access behavior | Wrong audience/token target | Verify requested resource URI | Request token for correct audience |

---

## Production Readiness Checklist (Managed Identities)

- System-assigned MI used by default for single-resource workloads
- User-assigned MI used only when reuse/persistence is required
- Role assignments scoped to minimum required resources
- Applications use SDK credentials rather than hand-built auth logic
- Retry and timeout strategy defined for token and target calls
- Monitoring in place for MI sign-ins and privilege changes

---
