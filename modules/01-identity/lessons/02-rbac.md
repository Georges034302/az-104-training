# Role-Based Access Control (RBAC) Fundamentals

> **Azure RBAC** is the authorization system that controls **who can do what** on **Azure resources**.  
> It operates **after authentication** and answers: *Does this identity have permission to perform this action at this scope?*

**Key mental model:** RBAC is all about **answering one question correctly**: Given a principal trying to perform an action on a resource at a specific scope, do they have a role assignment that permits it?

---

## Overview

Azure RBAC is the security foundation for all Azure resource management operations:

- **Control plane** (ARM operations): create VM, delete storage account, modify VNet
  - Controlled by role definitions with `Actions` property
  
- **Data plane** (resource-specific data access): read blob, write to SQL, access Key Vault secret
  - Controlled by role definitions with `DataActions` property
  - Often requires SEPARATE role from control plane (this is a common mistake)

- Works at **scope hierarchy**: management group → subscription → resource group → resource
  - Permissions **flow downward** (parent scope permissions apply to children)
  
- Assignments are **additive** (if multiple roles apply, you get the union of all permissions)
  - EXCEPT for **deny assignments** which override all "allow" assignments

**Practical consequence:** If you can't reason about:
- **Principal** (who?)
- **Role** (what actions?)
- **Scope** (where?)
Then you WILL get stuck troubleshooting access denied errors.

---

## What You Will Learn

- RBAC **components**: principal, role definition, scope, role assignment
- **Scope hierarchy** and permission inheritance
- **Built-in roles** and when to use each (Owner, Contributor, Reader, User Access Administrator)
- **Custom roles** creation and JSON structure
- **Data actions** vs **Actions** (control plane vs data plane)
- **Deny assignments** and how they override allow
- **Classic administrator roles** (legacy)
- Troubleshooting access denied scenarios
- Real admin workflows and exam-grade pitfalls
- **Role assignment propagation** and caching behavior
- **Principal types** and how each interacts with RBAC
- **Scope selection strategies** (least privilege patterns)

---

## Mental Model: RBAC Components

Azure RBAC has four core components that work together:

```text
Nodes:
+----------------------------------------------------+
| Principal Who? User/Group/SP/MI                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Role Assignment                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Role Definition What actions? Actions +...         |
+----------------------------------------------------+
+----------------------------------------------------+
| Scope Where? MG/Sub/RG/Resource                    |
+----------------------------------------------------+
+----------------------------------------------------+
| RBAC Engine                                        |
+----------------------------------------------------+
+----------------------------------------------------+
| Access Granted                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Access Denied                                      |
+----------------------------------------------------+

```

**Formula:** *Principal* + *Role* + *Scope* = *Role Assignment*

---

## RBAC Evaluation Flow

```text
Nodes:
+----------------------------------------------------+
| User/App sends request                             |
+----------------------------------------------------+
+----------------------------------------------------+
| ARM validates token                                |
+----------------------------------------------------+
+----------------------------------------------------+
| Identity authenticated?                            |
+----------------------------------------------------+
+----------------------------------------------------+
| Authentication failure                             |
+----------------------------------------------------+
+----------------------------------------------------+
| Check role assignments at all scopes               |
+----------------------------------------------------+
+----------------------------------------------------+
| Deny assignment exists?                            |
+----------------------------------------------------+
+----------------------------------------------------+
| Access Denied                                      |
+----------------------------------------------------+
+----------------------------------------------------+
| Matching allow assignment exists?                  |
+----------------------------------------------------+
+----------------------------------------------------+
| Action in role definition?                         |
+----------------------------------------------------+
+----------------------------------------------------+
| Access Allowed                                     |
+----------------------------------------------------+

```

**Key points:**
1. **Deny assignments** override all allow assignments
2. **No assignment** = no access (deny by default)
3. Permissions are evaluated **across all scopes** (inheritance)

---

## Scope Hierarchy and Inheritance

### Scope Levels

```text
+----------------------------------------------------+
| Management Group (optional, organizational level)  |
| Scope: multiple subscriptions and RGs             |
+----------------------------------------------------+
          |
          v
+----------------------------------------------------+
| Subscription (billing boundary)                    |
| Scope: directly under MG                           |
+----------------------------------------------------+
          |
          v
+----------------------------------------------------+
| Resource Group (logical container)                 |
| Scope: collection of related resources             |
+----------------------------------------------------+
          |
          v
+----------------------------------------------------+
| Resource (individual resource)                     |
| Scope: VM, Storage, SQL, etc.                      |
+----------------------------------------------------+
```

**Management Group is optional** - only used in larger organizations for grouping subscriptions.

**Typical setup:**
- Small company: Use subscription and resource group scopes
- Enterprise: Use management group to group subscriptions by department/function

### Inheritance Rule (Critical for Least Privilege)

**Permissions granted at a parent scope automatically apply to all child scopes.**

```text
Scenario: Alice assigned "Contributor" at Subscription level

Alice's Effective Permissions:
├─ Subscription: Contributor
│  ├─ Resource Group 1: Contributor (inherited)
│  │  ├─ VM-1: Contributor (inherited)
│  │  ├─ Storage-1: Contributor (inherited)
│  │  └─ VNet-1: Contributor (inherited)
│  └─ Resource Group 2: Contributor (inherited)
│     ├─ SQLServer: Contributor (inherited)
│     └─ WebApp: Contributor (inherited)
```

**Result:** Alice can create/modify/delete EVERYTHING in the subscription.

### Least Privilege Pattern (Best Practice)

**Anti-pattern (too broad):**
```bash
# ❌ NO: Assigning at subscription level
az role assignment create \
  --assignee alice@contoso.com \
  --role "Contributor" \
  --scope /subscriptions/<sub-id>

# Result: Alice can manage ALL resources in the subscription
```

**Better pattern (targeted scope):**
```bash
# ✅ YES: Assign at resource group level
az role assignment create \
  --assignee alice@contoso.com \
  --role "Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/team-app-rg

# Result: Alice can only manage resources in that specific RG
```

**Best pattern (even more limited):**
```bash
# ✅ BEST: Assign limited role at specific resource
az role assignment create \
  --assignee alice@contoso.com \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/data-rg/providers/Microsoft.Storage/storageAccounts/datavault

# Result: Alice can only work with blobs in that specific storage account
```

### Why Least Privilege Matters

**Scenario A: Employee leaves**
```
Employee with Contributor on Subscription
→ Must audit all 50 resources to find what they created
→ Problem: Hard to know what to delete, what to keep

Employee with Contributor on RG (team-app-rg)
→ Delete the RG, everything is gone
→ Problem: None, clean removal
```

**Scenario B: Security breach (attacker gets credentials)**
```
Attacker with Contributor on Subscription
→ Can delete everything, deploy malware VMs, export data
→ Damage: Entire subscription compromised

Attacker with Reader on RG (monitoring-rg) only
→ Can read metrics, logs
→ Damage: Information disclosure is the only risk
```

### Combining Multiple Assignments

**Important:** Scope hierarchy and multiple roles create **union of permissions**.

```text
Alice has:
  - Reader at Subscription level (can read everything)
  - Contributor at Resource Group "app-prod-rg" (can modify that RG)

Result for app-prod-rg:
  - Alice has CONTRIBUTOR (more permissive) via direct assignment
  
Result for app-dev-rg:
  - Alice has READER (inherited from subscription)
    
How this works:
  1. Check if assignment exists at requested scope → Contributor found → Granted
  2. Check parent scopes for inherited permissions → Reader found → Granted
  3. Union of permissions = take the most permissive = Contributor
```

---

## Built-in Roles (Core Four) - Comprehensive Guide

### Role Comparison Table

| Role | Scope | Can Create/Modify/Delete | Can Assign Roles | Common Use Case |
|------|-------|--------------------------|------------------|-----------------|
| **Owner** | All resources | ✅ Yes (all) | ✅ Yes | Resource/subscription owners, full delegation |
| **Contributor** | All resources | ✅ Yes (all) | ❌ No | Development teams, operators |
| **Reader** | All resources | ❌ No (read-only) | ❌ No | Auditors, stakeholders, monitoring |
| **User Access Administrator** | All resources | ❌ No (no resource access) | ✅ YES (only thing they can do) | Security teams managing access |

### Owner (The Most Powerful)

**What it includes:**
- `Actions: *` (all actions on resources: CRUD operations)
- `Microsoft.Authorization/roleAssignments/*` (can assign/remove roles)

**Cannot do:**
- Delete subscription (different permission)
- Change subscription billing (different role)

**Real-world use cases:**
```bash
# Scenario 1: Delegating resource group ownership
# App team owns their infrastructure
az role assignment create \
  --assignee "app-team@contoso.com" \
  --role "Owner" \
  --scope /subscriptions/<sub>/resourceGroups/app-team-rg

# Team can now create VMs, add users, delete resources, etc.

# Scenario 2: Backup for Owner role change
# Chief architect needs to manage resource group
az role assignment create \
  --assignee "chief-architect@contoso.com" \
  --role "Owner" \
  --scope /subscriptions/<sub>/resourceGroups/core-infrastructure-rg
```

**Exam trap:**
- Owner on a resource ≠ Owner on its resource group
- You can be Owner on VM but Contributor on the RG containing it
- (More permissive scope assignment is used)

**Careful with:**
- Owner role on high-value resources (production subscriptions)
- Too many people with Owner (hard to track who changed what)
- Owner without monitoring/auditing (no trail)

---

### Contributor (Permission Without Delegation)

**What it includes:**
- `Actions: *` (all actions on resources: CRUD operations)
- Does NOT include `Microsoft.Authorization/roleAssignments/write` (cannot assign roles)

**Cannot do:**
- Assign roles to others (most common confusion)
- View RBAC assignments
- Create new subscriptions (separate permission)
- Change subscription billing

**Real-world use cases:**
```bash
# Scenario 1: Development team deploying infrastructure
az role assignment create \
  --assignee "dev-team@contoso.com" \
  --role "Contributor" \
  --scope /subscriptions/<sub>/resourceGroups/dev-rg

# Dev team can create VMs, storage, deploy code
# But cannot add other people or change permissions

# Scenario 2: Automation script deploying resources
az role assignment create \
  --assignee "<service-principal-id>" \
  --role "Contributor" \
  --scope /subscriptions/<sub>/resourceGroups/prod-rg

# Script can create/modify resources but not change access control
```

**Why Contributor instead of Owner?**
- **Separation of duties:** Developers deploy; security teams manage access
- **Reduced risk:** If developer credentials compromised, attacker cannot add backdoor admin accounts
- **Audit trail:** Clear that only approved admins can change access control

**When to upgrade to Owner:**
- Team demonstrates responsibility
- Need to allow team to onboard members into their space
- Explicit business requirement

---

### Reader (The Safe Default)

**What it includes:**
- `Actions: */read` (read-only access: List, Get)
- Can view resource configuration, properties, metrics
- Cannot create, modify, or delete anything

**Cannot do:**
- Create resources
- Modify any settings
- Delete resources
- Access resource secrets/keys

**Real-world use cases:**
```bash
# Scenario 1: Finance auditor reviewing cost allocation
az role assignment create \
  --assignee "finance-auditor@contoso.com" \
  --role "Reader" \
  --scope /subscriptions/<sub>

# Auditor can see all resources and configurations
# Cannot accidentally (or maliciously) delete anything

# Scenario 2: Monitoring tool reading resource state
az role assignment create \
  --assignee "<monitoring-app-principal>" \
  --role "Reader" \
  --scope /subscriptions/<sub>/resourceGroups/prod-rg

# Monitoring app can retrieve VM status, disk metrics
# But cannot change VM configuration

# Scenario 3: CTO reviewing architecture
az role assignment create \
  --assignee "cto@contoso.com" \
  --role "Reader" \
  --scope /subscriptions/<sub>

# CTO can see everything, approve configurations
# Cannot accidentally modify production
```

**Important limitation:**
- Reader can see resources but **cannot see secrets in Key Vault**
- Reader can see SQL Database but **cannot query it** (need data plane role)
- Reader + data plane role = typical pattern (see config, access data)

**Why Reader is safe:**
- Safe to assign broadly (auditors, stakeholders, management)
- Cannot cause outages by accident
- Auditing is transparent (they can't hide their reads)

---

### User Access Administrator (The Permission Manager)

**What it includes:**
- `Microsoft.Authorization/*` (manage access control ONLY)
- Can create, view, modify, delete role assignments
- Can view role definitions

**Cannot do:**
- Create resources (no resource access at all)
- Modify resources
- Delete resources
- Access resource data

**Real-world use cases:**
```bash
# Scenario 1: Security team managing access (separation of duties)
az role assignment create \
  --assignee "security-team@contoso.com" \
  --role "User Access Administrator" \
  --scope /subscriptions/<sub>

# Security team can assign/revoke roles
# But cannot create/modify/delete resources
# If they compromise themselves, attacker only gets access control
# BUT cannot create VMs/storage to mine crypto, etc.

# Scenario 2: HR system integration
# When employee hired:
az role assignment create \
  --assignee "<new-employee>" \
  --role "User Access Administrator" \
  --scope /subscriptions/<sub>/resourceGroups/employee-services

# Employee admin can move people between groups/roles
# But cannot access the employee data systems directly
```

**Why this role exists (Separation of Duties):**
```
Organization structure:
├─ Cloud Operations Team
│  ├─ John: Contributor on production (deploys resources)
│  └─ Jane: Contributor on production (deploys resources)
│
├─ Security Team
│  └─ Bob: User Access Administrator (manages who can access what)
│
Result:
  - Ops can deploy but cannot grant themselves extra access
  - Security controls access; ops runs infrastructure
  - If ops credentials compromised, attacker cannot escalate
```

**Exam trap:**
- User Access Administrator is NOT "admin of the subscription"
- They can't create VMs or manage resources at all
- This role is deliberately narrow

---

## Data Actions vs Actions (Control Plane vs Data Plane)

**This is one of the most confusing aspects of Azure RBAC. Many people get it wrong.**

### Control Plane vs Data Plane - Explained

**Control Plane:**
- Operations that **manage Azure resources** (create, modify, delete)
- Who can create a VM? Who can change storage account settings?
- Handled by `Actions` property in role definitions
- Example: `Microsoft.Compute/virtualMachines/write`

**Data Plane:**
- Operations that **use Azure resources** (read/write the actual data)
- Who can read data from a blob? Who can execute a SQL query?
- Handled by `DataActions` property in role definitions
- Example: `Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read`

### The Critical Distinction Example

**Scenario: Alice and the Storage Account**

**Situation 1: Alice is Contributor on storage account**
```
Question: Can Alice read blobs?
Answer: Maybe not! 

Why? 
- Contributor controls the CONTROL PLANE
- Control plane = managing storage account (create, modify settings)
- It does NOT include blob access
- Alice can delete the storage account but not read its blobs
```

**Situation 2: Alice is Storage Blob Data Contributor**
```
Question: Can Alice manage storage account settings?
Answer: No!

Why?
- Storage Blob Data Contributor controls the DATA PLANE
- Data plane = accessing blob data
- It does NOT include control plane operations
- Alice can read/write blobs but cannot create storage account or change encryption
```

**Situation 3: Alice has BOTH roles**
```
Result:
- Contributor: Can create, modify, delete storage account (control plane)
- Storage Blob Data Contributor: Can read, write blobs (data plane)
- Combined: Full access to storage
```

### Control Plane vs Data Plane Diagram

```text
+------------------------------------------+      RBAC Roles: Contributor
| Storage Account                          |      Who can manage the account?
| Setting: Encryption, Networking, etc.    |      Answer: Contributor
+------------------------------------------+
          |
          | Data inside
          v
+------------------------------------------+      RBAC Roles: Storage Blob Data Contributor
| Blob Container / Files                   |      Who can READ/WRITE data?
| /data/file.txt, /logs/app.log            |      Answer: Storage Blob Data Contributor
+------------------------------------------+
```

**The Two-Role Problem:**
- Creating storage account: Need **Contributor**
- Uploading blobs: Need **Storage Blob Data Contributor**
- Many people miss the second role and can't upload data

### Common Roles with Data Actions

| Service | Control Plane Role | Data Plane Role | What You Need |
|---------|-------------------|-----------------|-------------|
| **Storage** | Contributor | Storage Blob Data Contributor | Both to fully work with storage |
| **Key Vault** | Contributor | Key Vault Secrets User | Both to manage vault + access secrets |
| **SQL Database** | Contributor | (Database-level RBAC) | Control plane role + SQL database permissions |
| **Cosmos DB** | Contributor | Cosmos DB Data Contributor | Both to manage + query database |
| **App Configuration** | Contributor | App Configuration Data Owner | Both to manage + access configs |

### Real-World Scenario

**Scenario: Deploying a web app that reads from storage**

**Infrastructure team deploys:**
```bash
# Creates storage account (control plane operation)
az role assignment create \
  --assignee "devops-team@contoso.com" \
  --role "Contributor" \
  --scope /subscriptions/<sub>/resourceGroups/app-rg

# Result: DevOps team has Contributor (can create resources)
```

**Web app needs to read blobs at runtime:**
```bash
# Create managed identity for the app
# Grant blob read permission (data plane operation)
az role assignment create \
  --assignee "<app-managed-identity>" \
  --role "Storage Blob Data Reader" \
  --scope /subscriptions/<sub>/resourceGroups/app-rg/providers/Microsoft.Storage/storageAccounts/appdata

# Result: App can read blobs (but not create/modify storage account)
```

**Troubleshooting:**
```
App error: "Access denied reading blob"
DevOps says: "But we have Contributor on the storage account!"

Problem: Contributor = control plane (manage storage)
         NOT = data plane (read blobs)
         
Solution: Add Storage Blob Data Reader role to the app's managed identity
```

---

## Custom Roles - When and How

### When to Create Custom Roles

✅ **Good reasons:**
- Built-in role is too broad (violates least privilege) and you need specific permissions
- Need specific combination of permissions across services
- Business-specific requirements (e.g., "VM Operator who can start/stop but not create")
- Compliance requirement for narrow permissions

❌ **Bad reasons:**
- "We want to remove just one action" → Use scope instead (assign to RG instead of subscription)
- "Temporary need" → Use time-limited assignments instead
- "Too many built-in roles to choose from" → Use the closest match, don't create custom
- Avoiding proper permission structure

**Decision tree:**
```
1. Is there a built-in role that's close? → Use it
2. Can I solve with scope assignment? → Use narrower scope
3. Can users have read-only? → Use Reader role
4. Need specific permissions? → Create custom role

If you reach step 4, it's appropriate to create custom.
```

### Custom Role JSON Structure (Detailed)

```json
{
  "Name": "Virtual Machine Power User",
  "IsCustom": true,
  "Description": "Can start, stop, restart, and view VMs. Cannot create or delete VMs.",
  
  "Actions": [
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/powerOff/action",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Network/networkInterfaces/read",
    "Microsoft.Storage/storageAccounts/listKeys/action",
    "Microsoft.Resources/subscriptions/resourceGroups/read"
  ],
  
  "NotActions": [
    "Microsoft.Compute/virtualMachines/delete",
    "Microsoft.Compute/virtualMachines/write"
  ],
  
  "DataActions": [],
  "NotDataActions": [],
  
  "AssignableScopes": [
    "/subscriptions/12345678-1234-1234-1234-123456789012",
    "/subscriptions/87654321-4321-4321-4321-210987654321"
  ]
}
```

### Property Explanation

| Property | Purpose | Notes |
|----------|---------|-------|
| `Name` | Unique role name | Use descriptive names; must be unique at scope |
| `IsCustom` | Always `true` for custom | Built-in roles have `false` |
| `Description` | Human-readable explanation | Appears in portal role picker |
| `Actions` | Permissions to ALLOW (control plane) | Wildcard supported: `Microsoft.Compute/*` |
| `NotActions` | Permissions to REMOVE from Actions | Applied after Actions (subtraction logic) |
| `DataActions` | Permissions to ALLOW (data plane) | Same wildcard support |
| `NotDataActions` | Permissions to REMOVE from DataActions | Applied after DataActions |
| `AssignableScopes` | Where this role can be assigned | Can be subscription or RG level; cannot be resource |

### Permission Logic

**Effective permissions are calculated as:**
- **Effective Actions** = (Actions) - (NotActions)
- **Effective DataActions** = (DataActions) - (NotDataActions)

**Example:**
```json
{
  "Actions": ["Microsoft.Compute/*"],        // All compute
  "NotActions": ["Microsoft.Compute/*/delete"]  // Except delete
}

Result: Can do everything in Compute EXCEPT delete operations
```

### Creating a Custom Role - Step by Step

**Step 1: Define permissions in JSON file**
```json
// vm-operator-role.json
{
  "Name": "VM Operator",
  "Description": "Start, stop, and view VMs",
  "Actions": [
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/powerOff/action",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Network/networkInterfaces/read"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": ["/subscriptions/<sub-id>"]
}
```

**Step 2: Create the role**
```bash
az role definition create --role-definition vm-operator-role.json
```

**Step 3: Use the role**
```bash
# Check it was created
az role definition list --custom-role-only true

# Assign it to a user
az role assignment create \
  --assignee operator@contoso.com \
  --role "VM Operator" \
  --scope /subscriptions/<sub-id>/resourceGroups/prod-rg
```

**Step 4: Test and verify**
```bash
# Verify the assignment
az role assignment list \
  --assignee operator@contoso.com \
  --scope /subscriptions/<sub-id>/resourceGroups/prod-rg

# Verify permissions by testing actions
# (From operator's account:)
az vm start --ids /subscriptions/<sub-id>/resourceGroups/prod-rg/providers/Microsoft.Compute/virtualMachines/test-vm
```

### Common Custom Role Mistakes

❌ **Mistake 1: Too many permissions**
```json
// NO - Also grants delete, create, etc.
"Actions": ["Microsoft.Compute/*"]
```

✅ **Better**
```json
// YES - Only what's needed
"Actions": [
  "Microsoft.Compute/virtualMachines/start/action",
  "Microsoft.Compute/virtualMachines/powerOff/action"
]
```

❌ **Mistake 2: Forgetting to remove old permissions**
```json
// NO - Grants management + reading secrets
{
  "Actions": ["Microsoft.KeyVault/*"],
  "NotActions": ["Microsoft.KeyVault/*/delete"]
}
```

✅ **Better**
```json
// YES - Only read secrets, no management
{
  "DataActions": ["Microsoft.KeyVault/vaults/secrets/getSecret/action"]
}
```

❌ **Mistake 3: Assigning at wrong scope**
```bash
# NO - Allows role anywhere in subscription
"AssignableScopes": ["/subscriptions/<sub-id>"]

# If attacker gets this role definition, they can assign it widely
```

✅ **Better - for non-admins**
```bash
# Only allow assignment in this specific RG
"AssignableScopes": ["/subscriptions/<sub-id>/resourceGroups/limited-rg"]
```

---

## Deny Assignments

### What are Deny Assignments?

Deny assignments **block users from performing specific actions**, even if a role assignment grants them access.

**Key characteristics:**
- **Deny overrides allow** (always)
- Cannot be created directly by users (system-managed)
- Created automatically by certain Azure services (e.g., Blueprints, Managed Apps)
- Rare in typical environments

### Deny Assignment Evaluation

```text
Nodes:
+----------------------------------------------------+
| Resource request                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Deny assignment matches?                           |
+----------------------------------------------------+
+----------------------------------------------------+
| Access Denied Deny wins                            |
+----------------------------------------------------+
+----------------------------------------------------+
| Allow assignment matches?                          |
+----------------------------------------------------+
+----------------------------------------------------+
| Access Granted                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Access Denied No permission                        |
+----------------------------------------------------+

```

### CLI: Check Deny Assignments

```bash
# List deny assignments at subscription scope
az role assignment list --include-inherited --include-deny -o table

# Check deny assignments for a specific resource
az role assignment list \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<vm> \
  --include-deny \
  -o table
```

---

## Classic Administrator Roles (Legacy)

| Role | Scope | Modern Equivalent | Status |
|------|-------|-------------------|--------|
| **Account Administrator** | Subscription | Owner + billing admin | Deprecated |
| **Service Administrator** | Subscription | Owner | Deprecated |
| **Co-Administrator** | Subscription | Owner | Deprecated |

**Current guidance:**
- ❌ Do **not** use classic roles for new assignments
- ✅ Use Azure RBAC roles instead (Owner, Contributor, etc.)
- ⚠️ Existing classic assignments still work but should be migrated

---

## Troubleshooting Access Denied

### Common Troubleshooting Flow

```text
Nodes:
+----------------------------------------------------+
| Access Denied                                      |
+----------------------------------------------------+
+----------------------------------------------------+
| User authenticated?                                |
+----------------------------------------------------+
+----------------------------------------------------+
| Check credentials Sign-in logs                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Role assignment exists?                            |
+----------------------------------------------------+
+----------------------------------------------------+
| Add appropriate role assignment                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Correct scope?                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Adjust scope to correct level                      |
+----------------------------------------------------+
+----------------------------------------------------+
| Action in role definition?                         |
+----------------------------------------------------+
+----------------------------------------------------+
| Create custom role or use different built-in       |
+----------------------------------------------------+
+----------------------------------------------------+
| Assignment propagated?                             |
+----------------------------------------------------+
+----------------------------------------------------+
| Wait 5-10 minutes Refresh token                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Deny assignment?                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Review and remove deny if possible                 |
+----------------------------------------------------+

```

### Validation Checklist

1. **Confirm authentication** - User can sign in?
2. **Check role assignments** - Does assignment exist for the principal?
3. **Verify scope** - Is assignment at the right scope level?
4. **Review role definition** - Does role include required action?
5. **Check propagation** - Did assignment propagate (can take 5-10 min)?
6. **Look for deny assignments** - Any deny blocking access?
7. **Review Activity Log** - What error code is returned?

### CLI: Troubleshooting Commands

```bash
# Check current user's identity
az ad signed-in-user show

# List all role assignments for current user
PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)
az role assignment list --assignee "$PRINCIPAL_ID" --all -o table

# Check effective permissions at a scope
az role assignment list \
  --scope "/subscriptions/<sub-id>/resourceGroups/<rg>" \
  --assignee "$PRINCIPAL_ID" \
  --include-inherited \
  -o table

# View Activity Log for authorization failures
az monitor activity-log list \
  --offset 1h \
  --query "[?contains(authorization.action, 'Microsoft.Authorization')]" \
  -o table
```

---

## Real-World Admin Scenarios

### Scenario 1: Developer Team Needs RG Access

**Requirement:** Dev team needs full access to `app-dev-rg` but not production.

```text
Nodes:
+----------------------------------------------------+
| Dev Team Group                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| app-dev-rg                                         |
+----------------------------------------------------+
+----------------------------------------------------+
| app-prod-rg                                        |
+----------------------------------------------------+

```

**Implementation:**
```bash
# Get the group object ID
GROUP_ID=$(az ad group show --group "Dev-Team" --query id -o tsv)

# Assign Contributor at RG scope only
az role assignment create \
  --assignee-object-id "$GROUP_ID" \
  --assignee-principal-type Group \
  --role "Contributor" \
  --scope "/subscriptions/<sub-id>/resourceGroups/app-dev-rg"
```

---

### Scenario 2: Monitoring Tool Needs Read Access

**Requirement:** Monitoring service needs read-only access to subscription.

```bash
# Create service principal for monitoring tool
SP_ID=$(az ad sp create-for-rbac --name "monitoring-sp" --query appId -o tsv)

# Assign Reader at subscription scope
az role assignment create \
  --assignee "$SP_ID" \
  --role "Reader" \
  --scope "/subscriptions/<subscription-id>"
```

---

### Scenario 3: Data Access Without Resource Management

**Requirement:** User needs to read/write blob data but not modify storage account.

```bash
# Assign data-plane role only (not Contributor)
az role assignment create \
  --assignee user@contoso.com \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>"
```

**Result:** User can upload/download blobs but **cannot** change firewall rules, delete account, etc.

---

## Best Practices

✅ **Use groups** for role assignments (not individual users)  
✅ **Apply least privilege** - smallest scope, minimal permissions  
✅ **Prefer Contributor** over Owner when role assignment capability not needed  
✅ **Use data-plane roles** for resource data access (blobs, queues, secrets)  
✅ **Document custom roles** with clear descriptions and justification  
✅ **Regular access reviews** - remove unused assignments  
✅ **Test in dev/test** before production role changes  
✅ **Monitor Activity Log** for authorization failures

---

## Common Pitfalls

❌ **Assigning Owner when Contributor is sufficient**  
Owner grants role assignment capability that creates security risk.

❌ **Using subscription scope when RG scope is enough**  
Violates least privilege; increases blast radius.

❌ **Mixing control-plane and data-plane roles**  
Contributor ≠ data access. Need separate data-plane roles.

❌ **Expecting immediate effect after assignment**  
Propagation takes 5-10 minutes; token caching delays effect.

❌ **Forgetting NotActions**  
`Actions: ["*"], NotActions: []` grants everything.

❌ **Not checking deny assignments**  
Deny overrides allow; always check for deny when troubleshooting.

❌ **Using classic administrator roles**  
Deprecated; use modern RBAC instead.

❌ **Assigning at resource level for multiple resources**  
Use RG scope to avoid assignment sprawl.

---

## Key Takeaways

1. **RBAC = Principal + Role + Scope** (assignment formula)
2. **Deny overrides allow** (always check deny assignments)
3. **Inheritance flows down** scope hierarchy (parent → child)
4. **Contributor ≠ data access** (need data-plane roles)
5. **Owner grants role assignment** capability (security consideration)
6. **Least privilege** = smallest scope + minimal permissions
7. **Propagation delay** = 5-10 minutes for new assignments
8. **Custom roles** require `AssignableScopes` and clear documentation

---

## CLI Reference

### Role Assignment Operations

```bash
# Create role assignment
az role assignment create \
  --assignee <user-or-sp-id> \
  --role "Contributor" \
  --scope <scope-path>

# List all role assignments at scope
az role assignment list --scope <scope-path> -o table

# Delete role assignment
az role assignment delete \
  --assignee <user-or-sp-id> \
  --role "Contributor" \
  --scope <scope-path>
```

### Role Definition Operations

```bash
# List all role definitions
az role definition list -o table

# Get specific role definition
az role definition list --name "Contributor" -o json

# Create custom role
az role definition create --role-definition <json-file>

# Update custom role
az role definition update --role-definition <json-file>

# Delete custom role
az role definition delete --name <role-name>
```

### Troubleshooting Commands

```bash
# Check current user's role assignments
PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)
az role assignment list --assignee "$PRINCIPAL_ID" --all -o table

# List denied assignments
az role assignment list --include-deny -o table

# View Activity Log for authorization events
az monitor activity-log list \
  --offset 1h \
  --query "[?contains(category, 'Authorization')]" \
  -o table
```

---

## Advanced: Effective Permission Evaluation

RBAC outcomes come from combined assignments and inheritance.

Operational model:

1. Collect assignments for principal (direct + via group)
2. Expand inherited assignments from parent scopes
3. Union all allow permissions
4. Apply role-level exclusions (`NotActions`, `NotDataActions`)
5. Apply deny assignments (deny wins)

Conceptual formula:

$$
Effective = \left(\bigcup AllowAssignments\right) - \left(\bigcup Exclusions\right) - \left(\bigcup DenyAssignments\right)
$$

Key admin takeaway: more assignments generally only increase access unless deny logic is present.

---

## Advanced: Scope Design Patterns

### Pattern A: Landing Zone Baseline

- Reader at management group for central audit teams
- Contributor at resource group for workload teams
- Owner restricted to platform admin groups

This pattern keeps operational teams productive while reducing tenant-wide risk.

### Pattern B: Shared Services Model

- Networking/security team gets Contributor on shared platform resource groups
- Application teams get Reader only in shared platform scopes
- Application teams get Contributor only in app-specific resource groups

This prevents accidental changes to shared infrastructure.

### Pattern C: Ephemeral Environments

- Temporary Contributor assignment at dedicated dev subscription scope
- Time-box with governance process
- Automatic review/removal after sprint window

---

## Advanced: Role Assignment Hygiene at Scale

As environments grow, access sprawl becomes a major risk.

Minimum hygiene controls:

- Prefer group assignments over direct user assignments
- Use naming conventions for groups and custom roles
- Require justification ticket for Owner assignments
- Review inactive service principals and stale assignments regularly
- Remove orphaned assignments referencing deleted objects

Recommended naming examples:

- `rg-app1-contributor`
- `sub-finance-reader`
- `custom-vm-operator`

---

## Advanced: Custom Role Governance Lifecycle

Custom roles should have a lifecycle, not just JSON creation.

Lifecycle stages:

1. Request: identify exact missing actions
2. Design: least-privilege role definition
3. Test: validate in non-production scope
4. Approve: security/platform review
5. Deploy: assign at minimal scope
6. Re-certify: periodic review for relevance

Validation checks before production:

- Role does only required operations
- `AssignableScopes` are intentionally minimal
- No wildcard permission without explicit need
- Documentation explains why built-in role was insufficient

---

## Advanced: RBAC and Operational Separation of Duties

Separation of duties examples:

- Platform ops: Contributor on infrastructure resource groups
- Security ops: User Access Administrator for permission governance
- Audit team: Reader at subscription or management group
- Incident responders: temporary elevation workflow

This separation reduces both accidental and malicious misuse.

---

## Extended Troubleshooting Playbook (403/AuthorizationFailed)

When you hit an authorization failure, investigate in this order:

1. Confirm principal identity used by request
2. Confirm role assignment exists for that principal
3. Confirm assignment scope includes target resource
4. Confirm required action or data action is present in role
5. Check deny assignments
6. Refresh token and wait propagation
7. Re-run request and inspect Activity Log correlation ID

Frequent root causes:

- Role assigned to wrong object ID
- Role assigned at sibling resource group instead of target scope
- Control-plane role used where data-plane role is required
- Assignment exists but token predates role grant

---

## Production Readiness Checklist (RBAC)

- No unnecessary Owner assignments at subscription scope
- Group-based access model implemented for all teams
- Custom roles documented and reviewed
- Data-plane roles used intentionally for data access workloads
- Access review cadence defined (monthly/quarterly)
- Deny assignment impact understood in governed subscriptions

---
