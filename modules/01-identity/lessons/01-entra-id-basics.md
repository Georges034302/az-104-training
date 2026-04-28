# Microsoft Entra ID Basics (AZ-104)

> **Microsoft Entra ID** (formerly Azure Active Directory) is Microsoft’s cloud-based **identity and access management (IAM)** service.  
> In Azure, Entra ID is the **source of truth for identities** and the **issuer of authentication tokens** that Azure services trust.

---

## Overview

Microsoft Entra ID is the identity layer behind:

- **Azure Portal / Azure CLI / Azure PowerShell** sign-in
- **Azure Resource Manager (ARM)** requests (create, update, delete resources)
- Access to **Microsoft 365** and thousands of SaaS applications
- Secure automation using **service principals** and **managed identities**

In AZ-104 terms: if you can’t reason about **tenant + token + RBAC scope**, you will struggle to troubleshoot access issues.

---

## What You Will Learn

- Entra ID **tenant architecture** and core components
- Identity objects: **users, groups, service principals, managed identities**
- **Authentication vs authorization** (and how Azure splits responsibilities)
- How Entra ID integrates with **ARM** and **Azure RBAC**
- The difference between **Entra ID roles** and **Azure RBAC roles**
- Common identity security controls: **MFA** and **Conditional Access**
- Monitoring and troubleshooting with **sign-in logs** and **audit logs**
- Real admin workflows and **exam-grade pitfalls**

---

## Mental Model: Who does what?

Azure identity is easier when you hold this model:

- **Entra ID answers:** *WHO are you?* and *issues a token*
- **Azure RBAC answers:** *WHAT can you do?* at a specific *scope*
- **ARM enforces:** the decision for **Azure resource management** operations

**Why this matters for AZ-104:**
- Many access issues stem from confusing these responsibilities
- A user can be **authenticated** (proven identity) but **not authorized** (denied permissions)
- Understanding the separation helps you troubleshoot systematically
- Exam questions often test whether you know which layer solves which problem

---


## High-Level Architecture

```text
 [Human/App/Script]
   |
   v
 [Microsoft Entra ID (Identity Provider)]
   |
   v
 [Users/Groups]   [Apps/Service Principals/Managed Identities]   [MFA/Conditional Access]
   |
   v
 [Access Token (JWT: who, tenant, groups)]
   |
   v
 [Azure Resource Manager (ARM)]
   |
   v
 [RBAC Engine]
   |
   v
 [Azure Resource Providers]
   |
   v
 [Compute / Storage / Network]
```

**Key takeaway:** Entra ID does **not** grant permissions to Azure resources by itself. It provides identity and tokens. **RBAC** grants permissions.

**Detailed flow explanation:**
1. **Authentication (Step 1)**: User/app provides credentials to Entra ID (password, certificate, managed identity)
2. **Token Issuance (Step 2)**: Entra ID validates credentials and issues a JWT (JSON Web Token) containing claims (user ID, tenant ID, group memberships)
3. **Authorization (Step 3)**: ARM validates the token, checks RBAC permissions at the requested scope, then allows/denies the operation

---

## Authentication Flow (What actually happens)

```text
+---------------------------+
| 1) User/App signs in      |
+---------------------------+
        |
        v
+---------------------------+
| Entra ID verifies         |
| credentials               |
+---------------------------+
        |
        | password / MFA / Conditional Access
        v
+---------------------------+
| 2) Entra ID issues token  |
| (JWT: user ID, tenant,    |
| groups)                   |
+---------------------------+
        |
        v
+---------------------------+
| 3) Request sent to ARM    |
+---------------------------+
        |
        v
+---------------------------+
| ARM validates token       |
| signature                 |
+---------------------------+
        |
        v
+---------------------------+
| 4) ARM checks RBAC        |
| at scope                  |
+---------------------------+
        |
        v
+---------------------------+
| 5) Has permission?        |
+---------------------------+
     | Allow                      | Deny
     v                            v
+---------------------------+   +-------------------------------+
| Resource provider         |   | Request blocked               |
| executes                  |   | (403 Forbidden)               |
+---------------------------+   +-------------------------------+
```

### Why tokens matter (AZ-104 troubleshooting)

Tokens are **time-bound** (often ~1 hour). If you change group membership or role assignments, the user might still have an old token:

- **Group membership change** may not reflect until token refresh
- **Role assignment change** may take time to propagate
- Symptoms: “I was just added, but still denied”

Admin fix: sign out/in, refresh token, or wait for propagation.

---

## Core Concepts

### 1) Entra ID Tenant

**Definition:** An Entra ID tenant is a dedicated identity directory for an organization and a security boundary.

**What lives in the tenant:**
- Users (members and guests)
- Groups
- App registrations
- Service principals
- Conditional Access policies
- Directory roles
- Logs (audit + sign-ins)

**Tenant identifiers:**
- Tenant (Directory) ID (GUID)
- Primary domain: `contoso.onmicrosoft.com`
- Custom domains: `contoso.com` (optional)

#### What is a Tenant? (Detailed Explanation)

A **tenant** is essentially a dedicated copy of the Entra ID service running for your organization. Think of it as:

1. **Identity vault** - Stores all user and app identities for your organization
2. **Security boundary** - Isolates your organization's identities from others
3. **Policy container** - Central place where you define permission rules (RBAC, Conditional Access, policies)
4. **Trust anchor** - The source that Azure services use to verify "are you really who you say you are?"

**Multi-tenancy example:** Your organization might have:
- Primary tenant: `contoso.onmicrosoft.com` (employees)
- Guest access from partner tenant: `partner.onmicrosoft.com` (contractors via B2B)
- These are **completely separate identity directories**, but Entra ID allows cross-tenant collaboration

#### Common Tenant Scenarios (AZ-104 relevant)

**Scenario 1: Single organization, multiple subscriptions**
```text
Entra ID Tenant: contoso.onmicrosoft.com
├─ Subscription 1 (Production) - trusts this tenant
├─ Subscription 2 (Development) - trusts this tenant
└─ Subscription 3 (Test) - trusts this tenant
```
All subscriptions use the **same identities** from the tenant. This is the standard Azure setup for enterprises.

**Scenario 2: Large enterprise with multiple business units**
```text
Entra ID Tenant: contoso.onmicrosoft.com
├─ Group: Finance Department
│  └─ Subscription: Finance-Sub (RBAC: Group → Reader role)
├─ Group: Engineering Department
│  └─ Subscription: Engineering-Sub (RBAC: Group → Contributor role)
└─ Group: Sales Department
   └─ Subscription: Sales-Sub (RBAC: Group → Contributor role)
```
Single tenant, organized by groups, with role assignments specific to each subscription.

**Scenario 3: Multi-tenant organization (complex)**
```text
tenant1.onmicrosoft.com (US operations)
├─ Subscriptions A, B, C (US cloud)

tenant2.onmicrosoft.com (EU operations - separate for compliance)
├─ Subscriptions D, E, F (EU cloud)
```
Rare scenario for compliance (GDPR, data residency), but important to understand. Each tenant has **completely separate identities**.

#### Tenant vs Subscription - Critical Distinction

Many AZ-104 candidates confuse these. Here's the firm distinction:

| Aspect | Tenant | Subscription |
|--------|--------|--------------|
| **What it is** | Identity directory | Billing + resource boundary |
| **Where identities live** | ✅ In tenant | ❌ Not here (identities are in tenant) |
| **Multiple allowed** | 1-2 (primary + guest) | Many per tenant |
| **Trust relationship** | N/A | Trusts 1 tenant for auth |
| **Manages** | Users, groups, policies | Resources, costs, quotas |
| **Created by** | Org signs up for Azure | Org creates subscription in existing tenant |

**Real example:**
- You have **1 tenant** (contoso.onmicrosoft.com) where all your employees' identities live
- You have **3 subscriptions** (Production-Sub, Dev-Sub, Test-Sub) all trusting that tenant
- You add a user to Entra ID (happens in tenant)
- You assign RBAC roles in subscriptions to that user
- The user signs in with their tenant identity, gets an access token, then uses it to access resources across all 3 subscriptions (if RBAC permits)



---

### 2) Identity Types

Azure administrators usually manage four identity categories.

#### Users (human identities)

User types you’ll encounter:

- **Member users**: internal identities (employees/students)
- **Guest users (B2B)**: external collaborators invited into your tenant
- **Cloud-only**: created directly in Entra ID
- **Synced (hybrid)**: synchronized from on-premises AD

User origin patterns:

```text
+-------------------------------+    Created directly in Entra ID     +-------------------------------+
| Cloud-only users              | ----------------------------------> | Entra ID Tenant               |
| (Azure Portal / CLI)          |                                     | contoso.onmicrosoft.com       |
+-------------------------------+                                     +-------------------------------+

+-------------------------------+    Sync via Azure AD Connect
| On-premises AD                | ----------------------------------> +-------------------------------+
| (Windows Server AD)           |                                     | Entra ID Tenant               |
+-------------------------------+                                     | contoso.onmicrosoft.com       |
                                                                      +-------------------------------+

+-------------------------------+    B2B invitation (guest user)
| External tenant               | ----------------------------------> +-------------------------------+
| (partner organization)        |                                     | Entra ID Tenant               |
+-------------------------------+                                     | contoso.onmicrosoft.com       |
                                                                      +-------------------------------+
```

Important attributes:
- **UPN** (User Principal Name, e.g., `john@contoso.com`) – sign-in name; should be unique within tenant
- **Object ID** – immutable identifier (GUID) used in RBAC assignments, APIs, and logs; never changes even if user name changes

#### User Types and Provisioning - Comprehensive Guide

**Member Users**
- Created directly in Entra ID or synced from on-premises AD
- Have standard organizational access (subject to RBAC)
- The default identity type for employees/permanent staff

**Guest Users (B2B - Business-to-Business)**
- External identities invited to your tenant for collaboration
- Retain their primary identity in their home organization
- Receive temporary guest credentials in your tenant
- Typical use cases: partner collaboration, vendor access, long-term contractor onboarding
- **Restrictions:** Guest access can be limited via Conditional Access; guests may not see all directory info
- **Important:** Guest users have less visibility by default (cannot browse user list)

**Cloud-only Identity**
- Created and managed entirely in Entra ID (not synced from anywhere)
- Faster provisioning (no sync delay, no on-premises dependency)
- Ideal for cloud-native organizations or cloud-only scenarios
- Used when no on-premises AD infrastructure exists

**Synced Identity (Hybrid)**
- Created in on-premises Active Directory, synced to Entra ID via Azure AD Connect
- On-premises AD remains the authoritative source
- Sync typically occurs every 30 minutes
- Three auth options:
  - **Password hash sync**: Password hashes synced to cloud (easiest, least secure - Microsoft doesn't see password)
  - **Pass-through authentication**: On-premises domain controller validates password (recommended hybrid)
  - **Federated (ADFS)**: On-premises federation server handles authentication (most complex, most control)
- Common in enterprises with established Windows Server AD infrastructure

#### Practical User Scenarios (AZ-104 Operations)

**Scenario A: Adding a new employee (cloud-only)**
```bash
# Admin creates user in Entra ID
az ad user create \
  --display-name "Alice Johnson" \
  --user-principal-name alice@contoso.com \
  --password "TempPassword123!" \
  --force-change-password-next-login true

# Alice receives temporary password via email, must change on first sign-in
# Then assign RBAC roles as needed
az role assignment create \
  --assignee alice@contoso.com \
  --role "Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group>
```

**Scenario B: Adding an external partner (guest B2B)**
```bash
# Admin creates guest invitation
az ad user invitation create \
  --user-email bob@partner.com \
  --redirect-url "https://myapps.microsoft.com"

# Bob receives invitation email with redemption link
# Upon acceptance, Bob becomes a guest user in your tenant
# Can then be added to security groups and assigned RBAC roles
az ad group member add \
  --group "External-Partners" \
  --member-id <bob-object-id>
```

**Scenario C: Troubleshooting user not found error**
- User recently created? → Wait 30 seconds (cache delay)
- User is guest? → Check if guest redemption completed
- User disabled? → Check user account status, enable if needed
- Synced from on-premises? → Verify Azure AD Connect is running and synced recently
- Wrong tenant? → Verify tenant ID in your sign-in session

#### Groups (access at scale)

Groups are the admin’s best friend for least-privilege access.

Why groups matter:
- You assign RBAC **once** to a group
- Add/remove users from the group without editing RBAC repeatedly

Group-based access pattern:

```text
+------------------------------------------+
| Users                                    |
| - alice@contoso.com                      |
| - bob@contoso.com                        |
| - charlie@contoso.com                    |
+------------------------------------------+
          |
          | member of
          v
+------------------------------------------+
| Security Group                           |
| example: RG-App-Contributors             |
+------------------------------------------+
          |
          | assigned to
          v
+------------------------------------------+
| RBAC Role                                |
| example: Contributor                     |
+------------------------------------------+
          |
          | at scope
          v
+------------------------------------------+
| Scope                                    |
| Subscription / Resource Group / Resource |
+------------------------------------------+
```

**Why this pattern works:**
- Add user to group → immediate access (once token refreshes)
- Remove user from group → immediate revocation
- No need to modify RBAC assignments repeatedly
- Easier auditing (one group assignment vs hundreds of individual assignments)

Types:
- **Security groups**: used for access control (RBAC, apps); the standard choice for permissions
- **Microsoft 365 groups**: primarily for collaboration (Teams/SharePoint); can be used for some access patterns but less flexible for fine-grained RBAC

Membership:
- **Assigned**: manual membership (admin adds/removes users)
- **Dynamic**: rules-based membership (automatic based on user attributes)

#### Group Strategy - Best Practices

**Rule 1: Always use groups, never assign roles directly to individual users**

Why?
- Scales better (add/remove from group vs editing every role assignment)
- Audit trail is cleaner
- Prevents accidental permission sprawl
- Easier to onboard/offboard users

**Rule 2: Use descriptive group names following a naming convention**

Good names:
- `SG-AppTeam-Contributors` (SG = Security Group, AppTeam = team, Contributors = role level)
- `RG-CloudOps-Readers` (RG = Resource Group, CloudOps = team, Readers = role level)

Bad names:
- `Team1`, `Users`, `Group`, `Temp-Access`

**Rule 3: Assign groups to roles, not vice versa**

Pattern:
```
User → joins → Group → assigned → Role at Scope
```

**Assigned vs Dynamic Membership**

**Assigned (manual):**
```bash
# Admin manually adds user
az ad group member add --group "RG-AppTeam-Contributors" --member-id <user-id>
```
- Simple, immediate effect
- Requires manual management (on/offboard tasks)
- Suitable for small, stable teams

**Dynamic (rules-based):**
```bash
# Rule example: All users in the Engineering department automatically join
# Rule: user.department -eq "Engineering"
```
- Automatic (no manual add/remove)
- Requires premium licensing in many cases
- Suitable for large organizations with HR system integration
- Reduces manual tasks on employee transfer/termination

#### Practical Group Scenarios

**Scenario A: Team access to resource group**
```bash
# Create security group
az ad group create --display-name "RG-WebApp-Contributors" --mail-nickname "webapp-contribs"

#Add team members
az ad group member add --group "RG-WebApp-Contributors" --member-id <alice-id>
az ad group member add --group "RG-WebApp-Contributors" --member-id <bob-id>

# Assign group to role at resource group scope
PRINCIPAL_ID=$(az ad group show --group "RG-WebApp-Contributors" --query objectId -o tsv)
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/app-prod-rg
```

**Scenario B: Temporary project access**
```bash
# Create temporary project group
az ad group create --display-name "Project-DataMigration-Team" --mail-nickname "datamig"

# Add people from multiple teams
az ad group member add --group "Project-DataMigration-Team" --member-id <contractor-id>
az ad group member add --group "Project-DataMigration-Team" --member-id <engineer-id>

# Assign limited permissions for project resources only
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/project-migration-rg

# After project: Remove group (all members lose access)
az ad group delete --group "Project-DataMigration-Team"
```

---

#### Applications and Service Principals (app identities) - Detailed Guide

Think of this as **design-time vs runtime**:

- **App registration (Application object)** = definition of an app (client ID, permissions, redirect URIs)
- **Service principal** = the identity instance of that app in a tenant (used to sign in and get tokens)

Application identity flow:

```text
+------------------------------------------+
| App Registration                         |
| (Design-time definition)                 |
|                                          |
| Contains:                                |
| - Client ID (app ID)                     |
| - Redirect URIs                          |
| - API permissions                        |
| - Certificates / secrets                 |
+------------------------------------------+
          |
          | creates
          v
+------------------------------------------+
| Service Principal                        |
| (Runtime identity in tenant)             |
| Used for auth and token requests         |
+------------------------------------------+
          |
          | receives
          v
+------------------------------------------+
| RBAC Role Assignment                     |
| Azure permissions                        |
| Example: Contributor on RG-Prod          |
+------------------------------------------+
```

**Key distinction:**
- **App Registration** = blueprint (exists in one tenant, can be multi-tenant)
- **Service Principal** = instance (exists in each tenant where app is used)
- **Example**: Microsoft Graph API has ONE app registration, but a service principal in every tenant that uses it

**Why this matters:**
- When you build an app that needs Azure access, you create **one app registration**
- When that app runs in your tenant, a **service principal** is created automatically
- If the app needs to run in multiple customer tenants, there's **one app registration** but a **service principal in each customer tenant**

**Use cases for service principals:** 
- Automation scripts accessing Azure resources
- CI/CD pipelines deploying infrastructure
- External applications with API access
- Scheduled jobs and serverless functions

#### Practical App Service Principal Scenarios

**Scenario A: Creating a service principal for a deployment script**
```bash
# Create app registration
APP_ID=$(az ad app create \
  --display-name "DeploymentScript" \
  --query appId -o tsv)

# Create service principal for the app (in current tenant)
PRINCIPAL_ID=$(az ad sp create --id "$APP_ID" --query objectId -o tsv)

# Assign Contributor role to service principal
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Contributor" \
  --scope /subscriptions/<subscription-id>

# Create credentials for the service principal
az ad sp credential reset --id "$PRINCIPAL_ID"

# Now the script can authenticate using the app ID and credentials
```

**Scenario B: Multi-tenant application**
```bash
# Single app registration (one tenant creates this)
# Mark as multi-tenant so other organizations can use it
az ad app update --id <app-id> --available-to-other-tenants true

# When Organization A adds the app, a service principal is created in their tenant
# When Organization B adds the app, a separate service principal is created in their tenant
# Both organizations see the same app registration ID, but different service principals
```

**Common Pitfalls:**
- Storing service principal credentials (secrets) in source code ❌ (use Key Vault instead)
- Using permanent secrets without rotation ❌ (use certificates + expiration, or managed identities)
- Assigning Owner role to service principals ❌ (least privilege: assign specific needed roles)

---

#### Managed Identities (Azure-managed app identities) - Complete Guide

Managed identities are service principals **created and managed by Azure**. Azure automatically handles credentials - no passwords or secrets needed.

**Key benefit:** You write code that accesses Azure services **without embedding any credentials**. Azure handles authentication transparently.

Two types:

- **System-assigned MI**: tied to one Azure resource (deleted with it)
- **User-assigned MI**: standalone resource, reusable across many resources

Managed identity lifecycle:

```text
SYSTEM-ASSIGNED MI (1:1)

+------------------------------------------+
| Azure Resource                           |
| VM / App Service / Function              |
+------------------------------------------+
      | Enable MI
      v
+------------------------------------------+
| Managed Identity                         |
| Automatically created                    |
+------------------------------------------+

Delete resource -> Managed Identity is deleted automatically


USER-ASSIGNED MI (reusable)

+------------------------------------------+
| Create Managed Identity as standalone    |
| resource                                 |
+------------------------------------------+
      |\
      | \ Attach to VM
      |  +---------------------------+
      |  | VM                        |
      |  +---------------------------+
      |
      |  Attach to App Service
      |  +---------------------------+
      |  | App Service               |
      |  +---------------------------+
      |
      |  Attach to Function
      |  +---------------------------+
      |  | Function                  |
      |  +---------------------------+
      |
      +--> Delete VM -> MI persists and can be reused
```

**When to use each:**
- **System-assigned**: Simple scenarios, single resource (VM accessing Storage)
- **User-assigned**: Multiple resources need same identity (3 VMs accessing same Key Vault with one MI)

**Why MIs are preferred:** no secrets, automatic rotation, reduced credential leakage risk.

#### System-Assigned vs User-Assigned - Decision Matrix

| Criterion | System-Assigned | User-Assigned |
|-----------|-----------------|---------------|
| **Lifecycle** | Tied to resource | Independent |
| **Number of resources** | One | Many |
| **Reusability** | Single resource | Multiple resources |
| **Sharing credentials** | Cannot share | Can share |
| **Deletes with resource?** | Yes | No (persists) |
| **Disaster recovery** | MI recreated when resource recreated | MI survives, can use same identity |
| **Complexity** | Lower | Higher |
| **Common use** | VM → Storage Account | VM1 + VM2 + App Service → Key Vault |

#### Practical Managed Identity Scenarios

**Scenario A: VM needs read-only access to Key Vault (System-assigned)**
```bash
# 1. Enable system-assigned MI on VM
az vm identity assign --name myVM --resource-group myRG

# 2. Get the principal ID (needed for RBAC assignment)
PRINCIPAL_ID=$(az vm identity show --name myVM --resource-group myRG --query principalId -o tsv)
echo $PRINCIPAL_ID  # Output: 12345678-1234-1234-1234-123456789012

# 3. Assign "Key Vault Secrets User" role to the MI
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<sub-id>/resourceGroups/myRG/providers/Microsoft.KeyVault/vaults/myVault

# 4. From within the VM, code can now read secrets without credentials:
# curl http://169.254.169.254/metadata/identity/oauth2/token?...&resource=https://vault.azure.net/
```

**Scenario B: Multiple services need access to same storage account (User-assigned)**
```bash
# 1. Create user-assigned MI as standalone resource
IDENTITY_ID=$(az identity create \
  --name shared-storage-mi \
  --resource-group shared-rg \
  --query id -o tsv)

PRINCIPAL_ID=$(az identity show \
  --name shared-storage-mi \
  --resource-group shared-rg \
  --query principalId -o tsv)

# 2. Assign role to the MI
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/data-rg/providers/Microsoft.Storage/storageAccounts/sharedvault

# 3. Attach same MI to multiple resources
# VM-1 gets the MI
az vm identity assign \
  --name vm1 \
  --resource-group prod-rg \
  --identities "$IDENTITY_ID"

# VM-2 gets the same MI
az vm identity assign \
  --name vm2 \
  --resource-group prod-rg \
  --identities "$IDENTITY_ID"

# App Service also gets the same MI
az webapp identity assign \
  --name myApp \
  --resource-group prod-rg \
  --identities "$IDENTITY_ID"

# Result: All three resources can access storage with the same identity (and same credentials)
# If you revoke the MI's storage access, all three lose access together
```

**Scenario C: Disaster recovery scenario with user-assigned MI**
```bash
# Original setup
# MI: finance-processor-mi in East US
# Function App: process-invoices-app in East US
# Storage: invoice-data-storage in East US

# Disaster occurs in East US, need to failover to West US
# User-assigned MI is replicated to West US (or created separately)
# New Function App created in West US, attached to MI
# Storage is replicated/setup in West US
# Function App in West US can immediately use the same MI identity
# (No need to recreate credentials from scratch)
```

**Common Pitfalls with Managed Identities:**
- Forgetting to assign RBAC roles to the MI (MI exists but has no permissions) ❌
- Using system-assigned MI when you need failover (MI deleted with resource) ❌
- Trying to authenticate outside of Azure (MI tokens only work from Azure resources) ❌

---

## Authentication vs Authorization (Do not mix them)

### Authentication (AuthN) — WHO are you?

## Authentication vs Authorization (Do not mix them)

These are **two separate processes** that often confuse new Azure admins.

### Authentication (AuthN) — WHO are you?

Handled by **Entra ID**.

Examples:
- Password + MFA (Multi-Factor Authentication)
- Passwordless sign-in (Windows Hello, FIDO2)
- Conditional Access evaluation (device compliance, location checks, sign-in risk)

Output:
- **Token** (JWT format: proof of identity with claims about who you are)

**Authentication means proving your identity; Entra ID is the authority that decides if you are who you claim.**

### Authorization (AuthZ) — WHAT can you do?

Handled by **Azure RBAC** (for Azure resources).

Output:
- **Allow / Deny** decision at a specific scope

**Authorization means deciding what actions you're allowed to perform; Azure RBAC is the authority that makes access control decisions.**

#### Critical Distinction Example

**Scenario: User cannot access a storage account**

**Q: Is this an authentication problem or authorization problem?**

First check:
1. **Can the user sign in?** 
   - If NO → **Authentication problem** (contact Entra ID admin, check password/MFA)
   - If YES → Continue to step 2

2. **Does the user have RBAC role with permissions?**
   - If NO → **Authorization problem** (add Storage Blob Data Reader role)
   - If YES → Continue to step 3

3. **Is the RBAC assignment propagated?**
   - New assignments take 5-10 minutes to propagate
   - Have user sign out/in to refresh token

**Real-world error mapping:**
- **401 Unauthorized**: Authentication failed (invalid/missing/expired token)
- **403 Forbidden**: Authentication succeeded, but authorization failed (no RBAC permissions)

#### Token Propagation and Caching (Common AZ-104 Pitfall)

Tokens are **time-bound** (often ~1 hour expiration). When you make changes to group membership or RBAC, users might still have old tokens:

**Problem scenario:**
```
10:00 AM - User added to group "App-Admins"
10:00 AM - Admin: "You should have access now!"
10:05 AM - User: "I still can't access the app"
         - User still has old token (doesn't know about group membership yet)
```

**Solutions:**
- Sign out/sign in (forces new token acquisition)
- Wait for token expiration (usually ~1 hour)
- Clear browser cache
- Open in private/incognito window (forces fresh token)

**Why does this matter?**
- Users ask "why do I still not have access after being added to group?"
- Admins think something is wrong, but it's just token caching
- Knowing this saves troubleshooting time

#### Authentication Flow - Step by Step

```text
Step 1: User/App provides credentials to Entra ID
        |
        v
Step 2: Entra ID verifies credentials
        - Password check
        - MFA challenge (if enabled)
        - Conditional Access evaluation
        |
        v
Step 3: Credentials valid? → Issue token (JWT)
        - Token contains: user ID, tenant ID, group memberships, expiration time
        - Token is digitally signed (cannot be forged)
        |
        v
Step 4: User/App sends token with request to Azure
        |
        v
Step 5: Azure Resource Manager receives request
        - Validates token signature
        - Extracts identity info from token
        |
        v
Step 6: ARM checks RBAC at specified scope
        - Does principal have matching role assignment?
        - Does role include this action?
        - Are there deny assignments?
        |
        v
Step 7: RBAC decision: Allow or Deny
        |
        v
Step 8: Resource provider executes (if allowed) or returns 403 Forbidden
```

---

## Entra ID Roles vs Azure RBAC Roles (Two different systems)

### Entra ID roles (Directory roles)

These control **directory management**, such as:
- create users
- reset passwords
- manage groups
- configure Conditional Access (depending on role)
- manage app registrations

Examples:
- Global Administrator (highest privilege in tenant; can manage everything)
- User Administrator (create/manage users and groups, reset passwords)
- Application Administrator (manage app registrations, permissions)
- Security Administrator (manage authentication, protection policies, security reports)

**Scope:** the Entra ID tenant/directory.

**Important limit:** Entra ID roles do NOT grant permissions to create, modify, or delete Azure resources.

### Azure RBAC roles

These control **Azure resources**, such as:
- create VMs
- edit VNets
- manage storage
- deploy resources

Examples:
- Owner (full control + can assign roles)
- Contributor (full control - cannot assign roles)
- Reader (read-only)
- User Access Administrator (manage permissions only - no resource access)

**Scope:** management group / subscription / resource group / resource.

#### Exam trap - Global Administrator vs Subscription Owner

**Global Administrator** in Entra ID does NOT automatically have Subscription Owner privileges in Azure.

**Example:**
```
Alice = Global Administrator in contoso.onmicrosoft.com
Alice is NOT a Subscription Owner in any Azure subscription by default
Alice signs into Azure Portal and tries to create a VM → 403 Forbidden
Why? She has Entra ID permissions (tenant management) but no RBAC roles (resource management)

Solution: Either:
1. Have a subscription owner add Alice as Subscription Owner/Contributor, OR
2. Alice needs the appropriate Azure RBAC role assignment
```

**Real-world consequence:**
- Org has "Global Admins" managing Entra ID (users, groups, policies)
- Different team has "Cloud Ops" managing Azure subscriptions (resources, billing)
- These are separate roles with separate responsibilities
- Must not be confused

---

## Conditional Access (Policy-driven security for sign-in)

**What is Conditional Access?**

Conditional Access is a security framework that evaluates **context** during sign-in and dynamically applies controls. It's the answer to "don't just check the password; check the whole situation."

**Basic formula:** IF (conditions are met) THEN (apply control)

**It operates at the authentication layer** - before RBAC. It decides WHETHER someone can get a token, not what they can do with it.

### Signals Evaluated

Conditional Access evaluates these **signals** (contextual information about the sign-in attempt):

1. **User/Group membership**
   - Is this user in the "Admins" group?
   - Is this user in the "Executives" group?

2. **Device compliance** (if using Intune)
   - Is the device enrolled in Intune?
   - Is the device compliant (updated, not jailbroken)?
   - Is the device joined to domain?

3. **Location / IP range**
   - Is the user signing in from the corporate network?
   - Is the IP within the trusted IP range?
   - Is the user in the expected geographic location?
   - Sudden sign-in from different country = risk signal

4. **Sign-in risk** (identity protection)
   - Is there suspicious behavior detected?
   - Are credentials being used from a new device?
   - Anonymous IP, leaked credentials, atypical travel?

5. **Application/Resource**
   - Applying rules to specific apps (SharePoint, Teams, Azure Portal)
   - Different policies for different apps

### Controls Applied

When signals match policy conditions, Conditional Access applies **controls**:

1. **Require MFA**
   - User must authenticate with second factor (phone approval, authenticator app)

2. **Require compliant/domain-joined device**
   - Device must be managed by Intune and pass security checks
   - Or device must be domain-joined (on-premises AD)

3. **Require specific Authenticator app**
   - Force use of Microsoft Authenticator app (more secure than SMS)

4. **Block access**
   - Deny sign-in entirely (even if password is correct)

5. **Session controls** (limited time tokens)
   - Token valid for only 1 hour (vs default 24 hours)
   - Re-authentication required frequently

### Conditional Access Evaluation Flow

```text
+------------------------------------------+
| Sign-in attempt                          |
| User enters credentials + factors        |
+------------------------------------------+
          |
          v
+------------------------------------------+
| Evaluate ALL Conditional Access policies |
+------------------------------------------+
          |
          v
+------------------------------------------+
| For each policy: conditions match?       |
+------------------------------------------+
     | No match                    | Match
     v                             v
+---------------------------+      +------------------------------------------+
| Policy doesn't apply      |      | Apply control (MFA, block, device check) |
+---------------------------+      +------------------------------------------+
          |                                  |
          |                                  v
          |                        +------------------------------------------+
          |                        | Control passed?                          |
          |                        +------------------------------------------+
          |                             | Yes               | No
          |                             v                   v
          |                    +---------------------------+ +---------------------------+
          |                    | Continue evaluation       | | Access Denied             |
          |                    +---------------------------+ +---------------------------+
          |                             |
          +-----------------------------+
                   |
                   v
+------------------------------------------+
| All policies evaluated                   |
| Any policy blocked? → Access Denied      |
| All approved? → Issue token              |
+------------------------------------------+
```

### Practical Conditional Access Policies

**Example Policy 1: Require MFA for admins outside network**
```
Condition:
  User: Members of "Global Admins" group
  Location: Outside corporate IP range
Control:
  Require MFA
Result:
  Admins signing in remotely must use MFA
  Admins on-site can sign in with password only
```

**Example Policy 2: Block external sign-in from unsupported apps**
```
Condition:
  User: Anyone
  App: Anything except Azure Portal, Microsoft Teams
  Device: Not managed/compliant
Control:
  Block access
Result:
  Prevents users from accessing Azure via browser clients
  Only managed apps/devices allowed for unmanaged endpoints
```

**Example Policy 3: Block risky sign-ins**
```
Condition:
  Sign-in risk: High (detected suspicious behavior)
Control:
  Block access
Result:
  Suspicious logins (credential stuffing, leaked credential) are blocked
  User receives alert to change password
```

**Example Policy 4: Force reauthentication for sensitive services**
```
Condition:
  User: Sensitive role (Security Admin, Global Admin)
  OR Resource: Conditional Access policies, Azure Portal
Control:
  Session control: Re-auth every 1 hour
Result:
  Even if attacker steals token, it's only valid 1 hour
  Limits damage from token compromise
```

### Common Conditional Access Mistakes

❌ **Mistake 1: Blocking yourself**
- Admin creates CA policy that blocks the admin from signing in
- Admin gets locked out, must contact support
- **Fix:** Always test CA policies on test users first; exclude emergency admin accounts

❌ **Mistake 2: Too strict (users cannot work)**
- Requiring MFA for ALL apps, ALL times → user frustration
- **Better:** Require MFA for admin apps and outside network; allow password for internal apps on-prem

❌ **Mistake 3: Confusing CA with RBAC**
- CA controls WHETHER someone can authenticate
- RBAC controls WHAT they can do
- Both are needed; neither replaces the other

---

## Multi-Factor Authentication (MFA)

MFA is commonly enforced via:
- per-user MFA (legacy)
- Conditional Access (recommended)

MFA improves resistance to credential theft.

MFA method security ranking:

```text
+------------------------------------------+
| Most resistant (phishing-resistant)      |
| - FIDO2 security keys                    |
| - Windows Hello for Business             |
| - Certificate-based authentication       |
| - Authenticator number matching          |
+------------------------------------------+
          |
          v
+------------------------------------------+
| Moderately resistant                     |
| - Authenticator app (OTP codes)          |
| - Software tokens                        |
| - Hardware tokens (OATH)                 |
+------------------------------------------+
          |
          v
+------------------------------------------+
| Least resistant                          |
| - SMS codes                              |
| - Voice call codes                       |
+------------------------------------------+
```

**Microsoft recommendation:**
- **Avoid**: SMS/voice (vulnerable to SIM swapping, interception)
- **Good**: Authenticator app with push notifications
- **Best**: FIDO2 keys or Windows Hello (hardware-backed, phishing-resistant)

---

## Monitoring and Auditing (How admins troubleshoot identity issues)

### Sign-in logs (authentication events)

Use sign-in logs to answer:
- Did the user sign in?
- Was MFA required?
- Was Conditional Access applied?
- Where did sign-in originate?
- Why did it fail (error code)?

### Audit logs (directory changes)

Use audit logs to answer:
- Who changed group membership?
- Who created a service principal?
- Who assigned a directory role?
- Who modified a Conditional Access policy?

Log types and sources:

```text
+------------------------------------------+      +------------------------------------------+
| Authentication events                    | ---> | Sign-in logs                             |
| - Sign-in success/failure                |      | Portal: Entra ID > Monitoring > Sign-ins |
| - MFA prompts                            |      +------------------------------------------+
| - CA policy applied                      |
| - Location/device info                   |
+------------------------------------------+

+------------------------------------------+      +------------------------------------------+
| Directory changes                        | ---> | Audit logs                               |
| - User created/deleted                   |      | Portal: Entra ID > Monitoring > Audit    |
| - Group membership                       |      | logs                                     |
| - Role assignments                       |      +------------------------------------------+
| - Policy modifications                   |
+------------------------------------------+
```

**Retention:**
- **Free tier**: 7 days
- **Premium P1/P2**: 30 days
- **Export to Log Analytics**: Long-term retention (90+ days, queryable with KQL)

### Common troubleshooting approach (AZ-104 practical)

1. Confirm user can authenticate (sign-in logs)
2. Confirm RBAC assignment exists at the correct scope
3. Confirm group membership is correct
4. Refresh token / allow propagation
5. Re-test action

---

## Common Scenarios (Admin view)

### Scenario 1: New employee onboarding (resource access)

```text
+------------------------------------------+    +------------------------------------------+
| 1) Create user                           | -> | 2) Add to group                          |
| alice@contoso.com                        |    | RG-App-Contributors                      |
+------------------------------------------+    +------------------------------------------+
                             |
                             v
                    +------------------------------------------+
                    | 3) Assign RBAC role                      |
                    | Contributor to group at RG scope         |
                    +------------------------------------------+
                             |
                             v
                    +------------------------------------------+
                    | 4) Verify access                         |
                    | User tests storage account creation      |
                    +------------------------------------------+
```

**Commands:**
```bash
# 1. Create user
az ad user create --display-name "Alice Smith" --user-principal-name alice@contoso.com --password "Temp@Pass123!"

# 2. Add to group
az ad group member add --group "RG-App-Contributors" --member-id $(az ad user show --id alice@contoso.com --query id -o tsv)

# 3. Assign RBAC role (group already has Contributor at RG scope)
az role assignment create --assignee-object-id <group-object-id> --role "Contributor" --scope "/subscriptions/<sub-id>/resourceGroups/RG-App"

# 4. User tests access
az login --username alice@contoso.com
az storage account create --name teststoragealice --resource-group RG-App --location australiaeast --sku Standard_LRS
```

### Scenario 2: App needs access to Storage without secrets

```text
+------------------------------------------+    +------------------------------------------+
| 1) Enable managed identity               | -> | 2) Assign role to MI                     |
| (system-assigned) on VM/App Service      |    | Storage Blob Data Contributor            |
+------------------------------------------+    +------------------------------------------+
                             |
                             v
                    +------------------------------------------+
                    | 3) App requests token from IMDS          |
                    | 169.254.169.254                          |
                    +------------------------------------------+
                             |
                             v
                    +------------------------------------------+
                    | 4) Access Storage with token             |
                    | No secrets required                      |
                    +------------------------------------------+
```

**Commands:**
```bash
# 1. Enable system-assigned MI on VM
az vm identity assign --name myVM --resource-group myRG

# 2. Get MI principal ID
MI_PRINCIPAL_ID=$(az vm show --name myVM --resource-group myRG --query identity.principalId -o tsv)

# 3. Assign Storage Blob Data Contributor role
az role assignment create \
  --assignee "$MI_PRINCIPAL_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<sub-id>/resourceGroups/myRG/providers/Microsoft.Storage/storageAccounts/mystorageacct"

# 4. From within the VM, app code requests token:
curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/' -H Metadata:true
```

### Scenario 3: External partner access (B2B guest)

```text
+------------------------------------------+    +------------------------------------------+
| 1) Invite guest user (B2B)               | -> | 2) Add to group                          |
| partner@external.com                     |    | External-Auditors                        |
+------------------------------------------+    +------------------------------------------+
                             |
                             v
                    +------------------------------------------+
                    | 3) Assign Reader role                    |
                    | at specific resource group scope         |
                    +------------------------------------------+
                             |
                             v
                    +------------------------------------------+
                    | 4) Monitor sign-in activity              |
                    | in logs for auditing                     |
                    +------------------------------------------+
```

**Commands:**
```bash
# 1. Invite guest user
az ad user create --user-principal-name partner_external.com#EXT#@contoso.onmicrosoft.com \
  --display-name "Partner User" --mail partner@external.com

# Alternatively, use Portal: Portal > Entra ID > Users > New guest user

# 2. Add to group
az ad group member add --group "External-Auditors" \
  --member-id $(az ad user show --id partner_external.com#EXT#@contoso.onmicrosoft.com --query id -o tsv)

# 3. Assign Reader role to group at RG scope
az role assignment create --assignee-object-id <group-object-id> \
  --role "Reader" --scope "/subscriptions/<sub-id>/resourceGroups/Audit-RG"

# 4. Monitor sign-ins (Portal: Entra ID > Monitoring > Sign-in logs, filter by user)
```

---

## Best Practices

- ✅ Use **groups** for RBAC assignments (not individuals)
- ✅ Apply **least privilege** and scope roles as low as possible (RG > subscription)
- ✅ Use **managed identities** for Azure workloads instead of secrets
- ✅ Require **MFA** for admins and privileged roles
- ✅ Use **Conditional Access** to enforce security policies
- ✅ Separate admin accounts from daily user accounts
- ✅ Monitor sign-in/audit logs and export to Log Analytics where required

---

## CLI Examples (commented)

> Note: Entra ID / directory operations may depend on tenant permissions.  
> Commands are intentionally **commented** so learners can copy/paste intentionally.

### List users
```bash
# List all users in the tenant
az ad user list --output table

# Show specific user details (UPN, object ID, display name)
az ad user show --id user@contoso.com

# Filter users by display name
az ad user list --filter "startswith(displayName,'Alice')" --output table
```

**What this shows:**
- User Principal Name (UPN) - sign-in name
- Object ID - immutable identifier used in RBAC
- Display Name - friendly name shown in portal
- User Type - Member or Guest

### List groups and members
```bash
# List all groups in tenant
az ad group list --output table

# Show specific group details
az ad group show --group "Marketing"

# List members of a group
az ad group member list --group "Marketing" --output table

# Check if user is member of specific group
az ad group member check --group "Marketing" --member-id <user-object-id>
```

**Use cases:**
- Verify group membership for troubleshooting access issues
- Audit group assignments before changing RBAC
- Identify nested groups (groups within groups)

### Service principals
```bash
# List all service principals (can be large, use --all flag)
az ad sp list --all --output table

# Show specific service principal by app ID or object ID
az ad sp show --id <app-id-or-object-id>

# Find service principal by display name
az ad sp list --filter "displayName eq 'MyApp'" --output table

# List service principals owned by current user
az ad sp list --show-mine --output table
```

**What this reveals:**
- App ID (Client ID) - used in authentication
- Object ID - used in RBAC assignments
- Display Name - human-readable app name
- Service Principal Names - additional identifiers

### Check current identity and RBAC assignments
```bash
# Show currently signed-in user
az ad signed-in-user show

# Get object ID of signed-in user (useful for scripting)
ASSIGNEE_ID=$(az ad signed-in-user show --query id -o tsv)
echo "Signed-in user objectId: $ASSIGNEE_ID"

# List all RBAC role assignments for current user
az role assignment list --assignee "$ASSIGNEE_ID" --output table

# List role assignments at specific scope
az role assignment list --assignee "$ASSIGNEE_ID" \
  --scope "/subscriptions/<sub-id>/resourceGroups/myRG" --output table

# Show inherited assignments (from parent scopes)
az role assignment list --assignee "$ASSIGNEE_ID" --all --output table
```

**Troubleshooting workflow:**
1. Confirm user is authenticated: `az ad signed-in-user show`
2. Get user's object ID: `az ad signed-in-user show --query id -o tsv`
3. Check RBAC assignments: `az role assignment list --assignee <object-id>`
4. Check group memberships: `az ad user get-member-groups --id <object-id>`
5. Verify scope hierarchy (assignments inherit from parent scopes)

---

## Common Pitfalls

- ❌ **Confusing directory roles with Azure RBAC roles**  
  Entra roles manage the directory; RBAC manages Azure resources.

- ❌ **Assigning roles at the wrong scope**  
  A role at RG scope does not grant subscription-wide access.

- ❌ **Expecting immediate access after changes**  
  Propagation + token caching can delay access.

- ❌ **Mixing authentication failures with authorization failures**  
  - AuthN failure: cannot sign in (Entra ID issue)  
  - AuthZ failure: signed in but forbidden (RBAC issue)

- ❌ **Using service principal secrets unnecessarily**  
  Prefer managed identities for Azure workloads.

---

## Key Takeaways

1. **Entra ID answers WHO** and issues tokens  
2. **Azure RBAC answers WHAT** and at which scope  
3. **ARM enforces** access decisions for resource management  
4. **Managed identities** remove secrets and reduce risk  
5. **Groups** are the scalable access pattern  
6. Logs are essential for troubleshooting and compliance

---

## Advanced: Token Anatomy and Claim Interpretation

When Entra ID issues an access token (JWT), Azure services evaluate claims inside the token.

Important claims you should understand:

- `iss` (issuer): which tenant issued the token
- `aud` (audience): which service the token is intended for
- `tid` (tenant ID): directory boundary of the identity
- `oid` (object ID): unique identity object in Entra ID
- `upn` / `preferred_username`: user sign-in identifier (user tokens)
- `groups`: group memberships (or overage indicator)
- `appid`: app client ID (application tokens)
- `exp`, `nbf`, `iat`: token lifetime controls

Why this matters operationally:

- Wrong `aud` means the token is rejected even if identity is valid
- Wrong `tid` means cross-tenant assumptions fail
- Missing expected group claims can break app-side authorization logic
- Expired token causes failures even when RBAC assignments are correct

### Group Claim Overage (Large Group Membership)

If a user belongs to many groups, token group claims can be replaced by an overage indicator. Services may need to query Microsoft Graph for full group expansion.

Symptoms:

- User appears correctly grouped in portal
- Application-side checks fail because groups are not all in token

Admin action:

- Verify group count and token claims
- Use app patterns that can resolve group memberships through Graph

---

## Advanced: Identity Administration Model for Enterprises

### Administrative Account Separation

Use separate identities for:

- Daily productivity account
- Privileged admin account

Benefits:

- Limits blast radius from phishing on day-to-day account
- Improves auditing clarity for privileged actions

### Break-Glass Accounts

Create a minimal number of emergency cloud-only accounts for tenant recovery.

Controls:

- Long, unique passwords stored in controlled vault process
- Excluded from conditional access policies that might lock out all admins
- Strict monitoring on all sign-ins
- Use only during incidents, then rotate credentials immediately

### Privileged Identity Management (PIM) Concept

Even if your exam focus is foundational, understand the model:

- Standing access: role permanently active (higher risk)
- Eligible access: role activated just-in-time for limited duration

Just-in-time access reduces long-lived privilege exposure.

---

## Advanced: Federation and Authentication Protocols

You should distinguish common sign-in protocols:

- OAuth 2.0: delegated/app authorization framework
- OpenID Connect (OIDC): identity layer on top of OAuth 2.0
- SAML 2.0: XML-based federation commonly used by enterprise SaaS

Practical interpretation:

- Modern cloud-native apps commonly use OAuth/OIDC
- Legacy enterprise integrations often use SAML
- Protocol choice affects troubleshooting artifacts and claim formats

---

## Operational Troubleshooting Matrix (Identity Layer)

| Symptom | Most likely layer | First checks | Typical fix |
|--------|-------------------|-------------|-------------|
| User cannot sign in at all | Entra authentication | Sign-in logs, CA result, MFA method | Fix credentials, CA condition, MFA registration |
| Sign-in succeeds but portal action fails | RBAC authorization | Role assignment, scope, propagation | Correct role/scope, refresh token |
| App works in dev but not prod tenant | Tenant/app config | Service principal presence, consent, audience | Create SP in tenant, grant consent, correct audience |
| Guest user blocked unexpectedly | B2B + CA | External user policy, CA targeting guests | Adjust guest access/CA policy conditions |

---

## Production Readiness Checklist (Identity)

- All privileged roles protected by MFA and conditional access
- Group-based RBAC used instead of individual role sprawl
- Guest access model documented (who invites, who approves, expiration)
- Sign-in and audit logs exported to long-term store
- Break-glass process tested and documented
- Privileged changes reviewed periodically

---

