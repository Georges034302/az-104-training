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

---

## High-Level Architecture (Text Diagram)

```
Human / App / Script
        |
        |  (1) Authenticate
        v
+-----------------------+
|  Microsoft Entra ID   |
|  - Users / Groups     |
|  - Apps / SPs / MIs   |
|  - MFA / CA Policies  |
|  - Token Issuer (JWT) |
+-----------------------+
        |
        |  (2) Access Token (JWT with claims)
        v
+------------------------------+
| Azure Resource Manager (ARM) |
| - Validates token            |
| - Calls Azure RBAC engine    |
+------------------------------+
        |
        |  (3) Authorization decision
        v
+------------------------------+
| Azure Resource Providers     |
| (Compute, Storage, Network…) |
+------------------------------+
```

**Key takeaway:** Entra ID does **not** grant permissions to Azure resources by itself. It provides identity and tokens. **RBAC** grants permissions.

---

## Authentication Flow (What actually happens)

```
(1) User/App signs in  --->  Entra ID verifies credentials (password/MFA/CA)
(2) Entra ID issues token ---> Token includes claims (who, tenant, groups, etc.)
(3) Request sent to ARM ---> ARM validates token
(4) ARM checks RBAC ---> Does token identity have permissions at the scope?
(5) ARM allows/denies ---> Resource provider executes or blocks the action
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

#### Tenant and Subscription Relationship (AZ-104 critical)

```
Entra ID Tenant
   |
   +--> Subscription A
   +--> Subscription B
   +--> Subscription C
```

- A subscription trusts **one** tenant at a time (for authentication)
- A tenant can be associated with **many** subscriptions
- **Identities are created at tenant level**, not subscription level

---

### 2) Identity Types

Azure administrators usually manage four identity categories.

#### Users (human identities)

User types you’ll encounter:

- **Member users**: internal identities (employees/students)
- **Guest users (B2B)**: external collaborators invited into your tenant
- **Cloud-only**: created directly in Entra ID
- **Synced (hybrid)**: synchronized from on-premises AD

Text map:

```
Cloud-only users  ---> created in Entra ID
Synced users      ---> on-prem AD  --> sync --> Entra ID
Guest users (B2B) ---> external tenant --> invitation --> your tenant
```

Important attributes:
- **UPN** (e.g., `john@contoso.com`) – sign-in name
- **Object ID** – immutable identifier used in RBAC assignments and APIs

---

#### Groups (access at scale)

Groups are the admin’s best friend for least-privilege access.

Why groups matter:
- You assign RBAC **once** to a group
- Add/remove users from the group without editing RBAC repeatedly

Group patterns:

```
[Users] ---> member of ---> [Group] ---> assigned ---> [RBAC role] ---> [Scope]
```

Types:
- **Security groups**: used for access control (RBAC, apps)
- **Microsoft 365 groups**: collaboration (Teams/SharePoint), can be used for some access patterns

Membership:
- **Assigned**: manual membership
- **Dynamic**: rules-based membership (premium features in many cases)

---

#### Applications and Service Principals (app identities)

Think of this as **design-time vs runtime**:

- **App registration (Application object)** = definition of an app (client ID, permissions, redirect URIs)
- **Service principal** = the identity instance of that app in a tenant (used to sign in and get tokens)

Text diagram:

```
App Registration (definition)
        |
        +--> Service Principal in Tenant (runtime identity)
                |
                +--> RBAC role assignment to Azure scopes
```

**Use cases:** automation scripts, CI/CD, external apps accessing Azure.

---

#### Managed Identities (Azure-managed app identities)

Managed identities are service principals **created and managed by Azure**.

Two types:

- **System-assigned MI**: tied to one Azure resource (deleted with it)
- **User-assigned MI**: standalone resource, reusable across many resources

Text diagram:

```
System-assigned MI:
   VM/AppService/Function --enable--> MI
   delete resource --> MI deleted

User-assigned MI:
   Create MI resource ---> attach to VM + AppService + Function
   delete one workload --> MI still exists
```

**Why MIs are preferred:** no secrets, automatic rotation, reduced leakage risk.

---

## Authentication vs Authorization (Do not mix them)

### Authentication (AuthN) — WHO are you?

Handled by **Entra ID**.

Examples:
- Password + MFA
- Passwordless sign-in
- Conditional Access evaluation

Output:
- **Token** (proof of identity)

### Authorization (AuthZ) — WHAT can you do?

Handled by **Azure RBAC** (for Azure resources).

Output:
- **Allow / Deny** at a specific scope

Text model:

```
AuthN (Entra ID)  -->  Token issued  -->  AuthZ (RBAC)  -->  Allow/Deny
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
- Global Administrator
- User Administrator
- Application Administrator
- Security Administrator

**Scope:** the Entra ID tenant/directory.

### Azure RBAC roles

These control **Azure resources**, such as:
- create VMs
- edit VNets
- manage storage
- deploy resources

Examples:
- Owner
- Contributor
- Reader
- User Access Administrator

**Scope:** management group / subscription / resource group / resource.

#### Exam trap

Global Administrator **does not automatically** equal Subscription Owner.

To manage Azure resources, you must have **Azure RBAC** permissions.

---

## Conditional Access (Policy-driven security for sign-in)

Conditional Access evaluates signals and enforces controls.

Signals might include:
- user/group membership
- device compliance
- location/IP range
- sign-in risk
- application being accessed

Controls might include:
- require MFA
- require compliant device
- block access
- limit session duration

Text evaluation:

```
Sign-in attempt
   |
   +--> Evaluate signals (user, device, location, risk)
   |
   +--> Apply CA policy controls (MFA / block / compliant device)
   |
   +--> If passed, token issued
```

**Admin mindset:** CA changes *how* authentication is allowed, not what resource permissions exist.

---

## Multi-Factor Authentication (MFA)

MFA is commonly enforced via:
- per-user MFA (legacy)
- Conditional Access (recommended)

MFA improves resistance to credential theft.

Text ranking (simplified):

```
Most resistant: FIDO2 / Windows Hello / Authenticator number matching
Less resistant: OTP codes
Least resistant: SMS / voice (more vulnerable)
```

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

Text flow:

```
Authentication events ---> Sign-in logs
Directory changes     ---> Audit logs
```

### Common troubleshooting approach (AZ-104 practical)

1. Confirm user can authenticate (sign-in logs)
2. Confirm RBAC assignment exists at the correct scope
3. Confirm group membership is correct
4. Refresh token / allow propagation
5. Re-test action

---

## Common Scenarios (Admin view)

### Scenario 1: New employee onboarding (resource access)

```
Create user
   -> Add to group (e.g., "RG-App-Operators")
      -> Assign RBAC role to group at RG scope
         -> Verify access with test action
```

### Scenario 2: App needs access to Storage without secrets

```
Enable Managed Identity on workload
   -> Assign "Storage Blob Data Contributor" to that identity at Storage scope
      -> App requests token -> accesses Storage with token
```

### Scenario 3: External partner access (B2B guest)

```
Invite guest user (B2B)
   -> Add to group
      -> Assign Reader role at specific scope
         -> Monitor sign-in activity
```

---

## Best Practices (AZ-104 aligned)

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
# az ad user list --output table
# az ad user show --id user@contoso.com
```

### List groups and members
```bash
# az ad group list --output table
# az ad group member list --group "Marketing" --output table
```

### Service principals
```bash
# az ad sp list --all --output table
# az ad sp show --id <app-id-or-object-id>
```

### Check current identity and RBAC assignments
```bash
# az ad signed-in-user show
# ASSIGNEE_ID=$(az ad signed-in-user show --query id -o tsv)
# echo "Signed-in user objectId: $ASSIGNEE_ID"
# az role assignment list --assignee "$ASSIGNEE_ID" --output table
```

---

## Common Pitfalls & Exam Traps

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

## Key Takeaways for AZ-104

1. **Entra ID answers WHO** and issues tokens  
2. **Azure RBAC answers WHAT** and at which scope  
3. **ARM enforces** access decisions for resource management  
4. **Managed identities** remove secrets and reduce risk  
5. **Groups** are the scalable access pattern  
6. Logs are essential for troubleshooting and compliance

---

