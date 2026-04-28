# Resource Management (Locks & Tags)

> **Resource locks** protect critical resources from accidental deletion or modification.  
> **Resource tags** provide metadata for organization, cost tracking, automation, and compliance reporting.

**Think of them as:** 
- **Locks** = safety mechanism (prevents accidents)
- **Tags** = labels and metadata (enables organization and automation)

---

## Overview

Locks and tags are essential **resource management tools** for Azure administrators:

**Locks:**
- **Prevent** accidental deletion or modifications
- Override RBAC permissions (even Owner cannot delete locked resource without removing lock first)
- Apply at subscription, resource group, or resource level
- Inherited from parent scopes

**Tags:**
- **Organize** resources with metadata (key-value pairs)
- **Track costs** by department, project, environment, cost center
- **Automate** operations based on tag values
- **Report** on resource ownership, compliance status, and usage
- Not inherited (each resource must be tagged separately)

**In AZ-104 terms:** Locks protect resources from accidents, tags enable governance and cost tracking - both are **critical for production environments**.

**Real-world scenario:**
```
Friday 5 PM: You're cleaning up development resources
You see "old-database" and think "nobody uses this"
You delete it
Monday 8 AM: CTO discovers you deleted the production backup database
Damage: $100K data recovery cost, regulatory fines

Solution with locks:
Friday 5 PM: "old-database" is CanNotDelete locked
You cannot delete it (force prevents accident)
You contact database owner first
Solution: Tag clearly, then unlock + delete (intentional action)
```

---

## What You Will Learn

- **Lock types**: CanNotDelete vs ReadOnly
- Lock **inheritance** and scope hierarchy
- When to use locks (and when not to)
- **Tag strategies** for cost allocation and governance
- Tag **inheritance** and limitations
- **Tag policies** for enforcement
- Real-world scenarios
- Troubleshooting locked resources
- Best practices and exam-grade pitfalls

---

## Resource Locks - Detailed

### Lock Types (the Two Options)

Azure provides exactly two lock types:

```text
+------------------------------------------------------+
| CanNotDelete (also called "Delete lock")            |
+------------------------------------------------------+
| Can:    View properties, Modify settings            |
| Cannot: Delete the resource                         |
| Use for: Production resources that must exist       |
+------------------------------------------------------+

+------------------------------------------------------+
| ReadOnly (also called "Read-only lock")             |
+------------------------------------------------------+
| Can:    View properties only                        |
| Cannot: Modify OR Delete                            |
| Use for: Compliance baselines, archived configs     |
+------------------------------------------------------+
```

| Lock Type | Read | Create/Modify | Delete | Use Case |
|-----------|------|---------------|--------|----------|
| **CanNotDelete** | ✅ Yes | ✅ Yes | ❌ No | Production resources, critical data, databases |
| **ReadOnly** | ✅ Yes | ❌ No | ❌ No | Compliance baselines, archived resources, "do not touch" configs |

### Lock Behavior - Critical Details

#### CanNotDelete Lock Behavior

**Who can do what:**
```
Scenario: Resource has CanNotDelete lock

Owner role tries to:
  - View resource           → ✅ Allowed
  - Modify resource props   → ✅ Allowed (locks don't prevent changes!)
  - Delete resource         → ❌ Blocked (403 Forbidden)

Contributor tries to:
  - Modify resource props   → ✅ Allowed
  - Delete resource         → ❌ Blocked (403 Forbidden)

Reader tries to:
  - View resource           → ✅ Allowed (that's all they can do anyway)
```

**Key point:** CanNotDelete lock **only blocks deletion**. Changes to resource properties are still allowed!

#### ReadOnly Lock Behavior

**Who can do what:**
```
Scenario: Resource has ReadOnly lock

Owner role tries to:
  - View resource props     → ✅ Allowed
  - Modify settings         → ❌ Blocked (all modifications forbidden)
  - Delete resource         → ❌ Blocked

Reader role tries to:
  - View resource props     → ✅ Allowed (read-only anyway)
```

**Key point:** ReadOnly lock blocks **all modifications**, not just deletion.

#### Critical Insight: Locks Override RBAC

```
Question: Can the Subscription Owner delete a CanNotDelete-locked resource?
Answer: NO

Reason: 
  RBAC says: "Owner can delete everything"
  Lock says: "Nobody can delete this"
  Result: Lock wins! (Locks override permissions)

To delete: Must remove lock FIRST, then can delete
```

This is a common exam trap. Many people think "Owner has all permissions" but forget that locks are a higher layer.

---

### Lock Inheritance (How Locks Flow Down)

Locks applied at **parent scope** automatically protect **child resources**.

```text
Subscription level CanNotDelete lock
  ↓ (inherited by all)
┌─────────────────────────┐
│ Resource Group A        │ (also CanNotDelete)
├─ VM-1 (locked)         │ ← Cannot delete
├─ Storage-1 (locked)    │ ← Cannot delete
└─ VNet-1 (locked)       │ ← Cannot delete

┌─────────────────────────┐
│ Resource Group B        │ (also CanNotDelete)
├─ SQLServer (locked)    │ ← Cannot delete
└─ Backup (locked)       │ ← Cannot delete
```

**Inheritance rule:**
- Lock on **Subscription** → All RGs and resources protected
- Lock on **Resource Group** → All resources in that RG protected
- Lock on **Resource** → Only that resource protected

**To delete a resource:**
1. Remove lock from resource (if it has one)
2. Remove lock from resource group (if inherited)
3. Remove lock from subscription (if inherited)
4. Then you can delete

---

### Creating Locks - Practical Guide

**Portal method:**
1. Navigate to resource, RG, or subscription
2. Left menu → **Locks**
3. **+ Add**
4. Select lock type (CanNotDelete or ReadOnly)
5. Enter name and optional notes
6. **OK**

**CLI - Create locks with descriptive names:**
```bash
# CanNotDelete lock on production resource group
az lock create \
  --name "prod-rg-prevent-deletion" \
  --lock-type CanNotDelete \
  --resource-group "prod-app-rg" \
  --notes "Prevent accidental deletion of production resources"

# ReadOnly lock on compliance baseline  
az lock create \
  --name "compliance-baseline-readonly" \
  --lock-type ReadOnly \
  --resource-group "compliance-rg" \
  --notes "Compliance baseline - approved by security team"

# Lock on specific resource (database)
az lock create \
  --name "critical-db-delete-lock" \
  --lock-type CanNotDelete \
  --resource-group "data-rg" \
  --resource-name "customer-db" \
  --resource-type "Microsoft.Sql/servers/databases" \
  --notes "Customer database - business critical"
```

**Key best practice:** Always add descriptive notes explaining WHY the lock exists.

---

### Managing Locks - Listing and Removal

**List all locks:**
```bash
# List locks at resource group level
az lock list --resource-group "prod-rg" -o table
# Output shows: Name, Type, Level (subscription/rg/resource)

# List all locks at subscription level
az lock list -o table

# List locks on specific resource
az lock list \
  --resource-group "data-rg" \
  --resource-name "customer-db" \
  --resource-type "Microsoft.Sql/servers/databases"
```

**Remove locks (carefully!):**
```bash
# Delete by name  
az lock delete \
  --name "prod-rg-prevent-deletion" \
  --resource-group "prod-rg"

# Delete by resource ID
LOCK_ID=$(az lock show \
  --name "prod-rg-prevent-deletion" \
  --resource-group "prod-rg" \
  --query id -o tsv)
az lock delete --ids "$LOCK_ID"
```

**Best practice:** Document who removed the lock and why (in change management system).

---

### Lock Conflict Scenarios - Troubleshooting

#### Scenario 1: Cannot Delete Storage Account

**Error message:**
```
Error: Cannot delete resource 'prodStorage' because it has a lock.
```

**Troubleshooting flow:**
```
Step 1: Just try deleting? → Error → Lock exists somewhere
Step 2: Check resource level → az lock list on resource
         No lock found → Continue
Step 3: Check resource group → az lock list on RG
         Lock found! → Remove it at RG level
Step 4: Check subscription → az lock list
         No lock? → We're done
Step 5: Retry deletion
```

**Solution script:**
```bash
# Find ALL locks that might block this deletion
az lock list --query "[].{name:name, level:level, type:lockType}" -o table

# Remove the blocking lock(s)
az lock delete --name "<lock-name>" --resource-group "<rg>"

# Try deletion again
az storage account delete --name "prodStorage" --resource-group "prod-rg"
```

#### Scenario 2: Cannot Modify Resource (ReadOnly Lock)

**Error message:**
```
Error: Operation failed. Resource is locked for modification.
```

**The issue:** Someone assigned ReadOnly lock to a resource that needs updating.

**Solution:**
```bash
# If you need to change it
# Step 1: Remove the ReadOnly lock
az lock delete --name "lock-name" --resource-group "rg-name"

# Step 2: Make changes
az resource update --ids "<resource-id>" --set properties.<property>=<value>

# Step 3: Re-apply lock (if still needed)
az lock create --name "lock-name" --lock-type ReadOnly --resource-group "rg-name"
```

**Question: Why not just reapply immediately?**
- Good practice: Notify team about the change
- Audit trail: Changes are traceable
- Time delay: Allows someone to object if change is wrong

#### Scenario 3: Lock Blocks Automated Deployment

**Situation:** You have a CI/CD pipeline that deploys to a resource group. The RG has CanNotDelete lock. Deployment fails.

**Root cause:** 
- Deployment might include deleting old resources
- CanNotDelete lock prevents deletion
- Pipeline fails

**Solution options:**

Option A: Use script to temporarily unlock
```bash
# Remove lock before deployment
az lock delete --name "deploy-lock" --resource-group "prod-rg"

# Run deployment
az deployment group create --resource-group "prod-rg" ...

# Re-apply lock
az lock create --name "deploy-lock" --lock-type CanNotDelete --resource-group "prod-rg"
```

Option B: Lock only critical resources (not the RG)
```bash
# Instead of locking entire RG
# Lock individual resources
az lock create --name "db-delete-lock" --lock-type CanNotDelete \
  --resource-group "prod-rg" \
  --resource-name "critical-db" \
  --resource-type "Microsoft.Sql/servers/databases"
```

---

## Resource Tags

### What are Tags?

**Tags** are key-value pairs that provide metadata about Azure resources.

```text
Nodes:
+----------------------------------------------------+
| Azure Resource                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Tag: Environment = Production                      |
+----------------------------------------------------+
+----------------------------------------------------+
| Tag: CostCenter = Finance                          |
+----------------------------------------------------+
+----------------------------------------------------+
| Tag: Owner = ops-team                              |
+----------------------------------------------------+
+----------------------------------------------------+
| Tag: Project = migration                           |
+----------------------------------------------------+

```

**Structure:**
- **Tag name** (key): Up to 512 characters
- **Tag value**: Up to 256 characters
- **Limit**: 50 tags per resource

---

### Tag Strategies

#### Strategy 1: Cost Allocation

```text
Nodes:
+----------------------------------------------------+
| Cost Tracking Tags                                 |
+----------------------------------------------------+
+----------------------------------------------------+
| CostCenter Finance, IT, HR                         |
+----------------------------------------------------+
+----------------------------------------------------+
| Department Engineering, Sales                      |
+----------------------------------------------------+
+----------------------------------------------------+
| Project migration, new-app                         |
+----------------------------------------------------+
+----------------------------------------------------+
| Environment prod, staging, dev                     |
+----------------------------------------------------+

```

**Example:**
```bash
# Tag resource for cost tracking
az resource tag \
  --tags CostCenter=Finance Department=Engineering Project=migration Environment=prod \
  --ids /subscriptions/<sub-id>/resourceGroups/app-rg/providers/Microsoft.Compute/virtualMachines/app-vm
```

**Result:** Azure Cost Management can break down costs by CostCenter, Department, Project, or Environment.

---

#### Strategy 2: Operational Tags

| Tag Name | Purpose | Example Values |
|----------|---------|----------------|
| `Owner` | Responsible team/person | ops-team, john@contoso.com |
| `SLA` | Service level | critical, standard, low |
| `MaintenanceWindow` | Allowed downtime | saturday-2am, never |
| `BackupPolicy` | Backup requirement | daily, weekly, none |
| `DataClassification` | Sensitivity level | confidential, internal, public |

---

#### Strategy 3: Automation Tags

```bash
# Tag VM for auto-shutdown
az vm update \
  --resource-group app-rg \
  --name dev-vm \
  --set tags.AutoShutdown=true tags.ShutdownTime=19:00
```

**Automation script:**
```bash
# Shutdown all VMs tagged with AutoShutdown=true at specified time
VMs=$(az vm list --query "[?tags.AutoShutdown=='true'].id" -o tsv)
for VM in $VMs; do
  az vm deallocate --ids "$VM" --no-wait
done
```

---

### Tag Inheritance

**Warning:** Tags do **NOT** inherit from parent scopes by default.

```text
Nodes:
+----------------------------------------------------+
| Resource Group Tag: Environment=prod               |
+----------------------------------------------------+
+----------------------------------------------------+
| VM No tags inherited                               |
+----------------------------------------------------+
+----------------------------------------------------+
| Storage No tags inherited                          |
+----------------------------------------------------+

```

**Solution:** Use Azure Policy to enforce tag inheritance.

**Policy example: Inherit tag from resource group**
```json
{
  "if": {
    "field": "tags['Environment']",
    "exists": false
  },
  "then": {
    "effect": "modify",
    "details": {
      "roleDefinitionIds": [
        "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      ],
      "operations": [
        {
          "operation": "addOrReplace",
          "field": "tags['Environment']",
          "value": "[resourceGroup().tags['Environment']]"
        }
      ]
    }
  }
}
```

---

### Tag Management via CLI

**Add/Update tags:**
```bash
# Add tags to resource group
az group update \
  --name "app-prod-rg" \
  --tags Environment=Production CostCenter=Finance Owner=ops-team

# Add tags to specific resource
az vm update \
  --resource-group "app-prod-rg" \
  --name "web-vm" \
  --set tags.Role=WebServer tags.Tier=Frontend

# Add tag using resource ID
az tag create \
  --resource-id "/subscriptions/<sub-id>/resourceGroups/app-rg/providers/Microsoft.Compute/virtualMachines/app-vm" \
  --tags Project=migration
```

**List resources by tag:**
```bash
# Find all resources with Environment=Production tag
az resource list --tag Environment=Production -o table

# Find all VMs with specific tag
az vm list --query "[?tags.Role=='WebServer']" -o table
```

**Remove tags:**
```bash
# Remove specific tag from resource
az vm update \
  --resource-group "app-rg" \
  --name "test-vm" \
  --remove tags.Temporary

# Remove all tags from resource
az vm update --resource-group "app-rg" --name "test-vm" --set tags={}
```

---

### Tag Policies (Enforcement)

#### Policy 1: Require Specific Tags

**Requirement:** All resources must have `CostCenter` tag.

```bash
# Assign built-in policy "Require a tag on resources"
az policy assignment create \
  --name "require-costcenter" \
  --policy "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99" \
  --params '{"tagName":{"value":"CostCenter"}}' \
  --scope /subscriptions/<sub-id>
```

**Effect:** Resources created without `CostCenter` tag are **denied**.

---

#### Policy 2: Append Default Tag

**Requirement:** Auto-apply `Environment=dev` to resources in dev-rg.

```bash
# Custom policy to append default tag
cat > append-env-tag-policy.json << 'EOF'
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "notEquals": "Microsoft.Resources/subscriptions/resourceGroups"
      },
      {
        "field": "tags['Environment']",
        "exists": false
      }
    ]
  },
  "then": {
    "effect": "append",
    "details": [
      {
        "field": "tags['Environment']",
        "value": "dev"
      }
    ]
  }
}
EOF

az policy definition create --name "append-env-tag" --rules append-env-tag-policy.json
az policy assignment create --name "auto-env-tag" --policy "append-env-tag" --scope /subscriptions/<sub-id>/resourceGroups/dev-rg
```

---

## Real-World Scenarios

### Scenario 1: Production Resource Protection

**Requirement:** Protect production RG from accidental deletion but allow updates.

```bash
# Apply CanNotDelete lock to production resource group
az lock create \
  --name "prod-protection" \
  --lock-type CanNotDelete \
  --resource-group "app-prod-rg" \
  --notes "Protect production environment from accidental deletion"

# Tag all resources in production
az group update --name "app-prod-rg" --tags Environment=Production SLA=Critical Owner=ops-team
```

**Result:**
- ✅ Admins can deploy/update resources
- ❌ Nobody can delete the resource group or its resources
- ✅ Tags identify production resources for cost tracking

---

### Scenario 2: Cost Allocation by Department

**Requirement:** Track costs for Finance, Engineering, and Sales departments.

```bash
# Tag resource groups by department
az group update --name "finance-rg" --tags Department=Finance CostCenter=F100
az group update --name "engineering-rg" --tags Department=Engineering CostCenter=E200
az group update --name "sales-rg" --tags Department=Sales CostCenter=S300

# Enforce department tag on all resources (policy)
az policy assignment create \
  --name "require-department-tag" \
  --policy "<require-tag-policy-id>" \
  --params '{"tagName":{"value":"Department"}}' \
  --scope /subscriptions/<sub-id>
```

**Result:** Azure Cost Management can show costs broken down by Department tag.

---

### Scenario 3: Automation - Auto-Start/Stop VMs

**Requirement:** Dev VMs should auto-shutdown at 7 PM and start at 8 AM.

```bash
# Tag dev VMs with schedule
az vm update --resource-group "dev-rg" --name "dev-vm1" \
  --set tags.AutoStart=08:00 tags.AutoStop=19:00

# Automation script (run via Azure Automation or scheduled task)
STOP_VMS=$(az vm list --query "[?tags.AutoStop=='19:00' && powerState=='running'].id" -o tsv)
for VM in $STOP_VMS; do
  CURRENT_HOUR=$(date +%H:%M)
  if [ "$CURRENT_HOUR" == "19:00" ]; then
    az vm deallocate --ids "$VM" --no-wait
  fi
done
```

---

## Troubleshooting

### Cannot Delete Resource (Lock)

```text
Nodes:
+----------------------------------------------------+
| Cannot delete resource                             |
+----------------------------------------------------+
+----------------------------------------------------+
| Portal: Check Locks                                |
+----------------------------------------------------+
+----------------------------------------------------+
| Resource → Locks                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| RG → Locks                                         |
+----------------------------------------------------+
+----------------------------------------------------+
| Subscription → Locks                               |
+----------------------------------------------------+
+----------------------------------------------------+
| Lock found?                                        |
+----------------------------------------------------+
+----------------------------------------------------+
| Remove lock                                        |
+----------------------------------------------------+
+----------------------------------------------------+
| Check RBAC permissions                             |
+----------------------------------------------------+
+----------------------------------------------------+
| Delete resource                                    |
+----------------------------------------------------+

```

**CLI troubleshooting:**
```bash
# List all locks affecting a resource
az lock list --resource-group "app-rg" -o table

# Check locks at all scopes
az lock list -o table  # Subscription level
az lock list --resource-group "app-rg" -o table  # RG level
```

---

### Tags Not Appearing in Cost Reports

**Possible causes:**
1. **Tags not applied** - Verify tags exist on resources
2. **Tag not synced** - Cost data can lag 24-48 hours
3. **Tag not enabled in Cost Management** - Enable tag in cost analysis filters

**Verification:**
```bash
# Check tags on resource
az resource show --ids <resource-id> --query tags

# List all resources and their tags
az resource list --query "[].{Name:name, Tags:tags}" -o json
```

---

## Best Practices

### Locks

✅ **Use CanNotDelete** for production RGs and critical resources  
✅ **Document lock purpose** in notes field  
✅ **Apply at RG level** (not individual resources) for easier management  
✅ **Use sparingly** - excessive locks hinder automation  
✅ **Test deployment** before applying ReadOnly locks  
✅ **Notify teams** when applying locks to shared resources

### Tags

✅ **Define tag schema** before deployment (standardize names)  
✅ **Use policies** to enforce required tags  
✅ **Tag resource groups** and use policies to inherit to resources  
✅ **Keep tag names consistent** (CostCenter, not Cost_Center or costcenter)  
✅ **Limit tag count** - use 5-10 meaningful tags, not 50  
✅ **Document tag meanings** in wiki or runbook  
✅ **Review tags quarterly** - remove obsolete tags

---

## Common Pitfalls

### Locks

❌ **Confusing locks with RBAC**  
Locks are **not permissions**. They block operations **even for Owners**.

❌ **Forgetting inherited locks**  
Lock on subscription blocks deletion of all RGs and resources below.

❌ **ReadOnly lock blocking all changes**  
ReadOnly prevents even benign updates; use CanNotDelete for most cases.

❌ **Not documenting lock purpose**  
6 months later, nobody knows why the lock exists.

❌ **Locking automation accounts**  
Locks can break CI/CD pipelines and automation.

### Tags

❌ **Expecting automatic inheritance**  
Tags do NOT inherit by default; use policies to enforce.

❌ **Inconsistent tag names**  
`Environment`, `environment`, `Env` are all different tags.

❌ **Too many tags**  
50-tag limit is per resource; 10-15 meaningful tags are usually sufficient.

❌ **Not enforcing tags**  
Without policy enforcement, tag standards are optional.

❌ **Using tags instead of RBAC**  
Tags are metadata, not access control.

---

## Key Takeaways

### Locks

1. **CanNotDelete** = allow modifications, block deletion
2. **ReadOnly** = block all modifications and deletion
3. **Locks override RBAC** (even Owner cannot bypass lock)
4. **Inheritance applies** - parent lock protects all children
5. **Remove lock before deletion** - mandatory step

### Tags

6. **Tags = metadata** (not permissions, not inheritance by default)
7. **50 tags max** per resource
8. **Use policies** to enforce required tags and inheritance
9. **Cost allocation** requires consistent tagging strategy
10. **Automation** can use tags to identify resources for operations

---

## CLI Reference

### Locks

```bash
# Create CanNotDelete lock on resource group
az lock create --name "prod-lock" --lock-type CanNotDelete --resource-group "app-prod-rg"

# Create ReadOnly lock on subscription
az lock create --name "baseline-lock" --lock-type ReadOnly

# List all locks
az lock list -o table

# Delete lock
az lock delete --name "prod-lock" --resource-group "app-prod-rg"
```

### Tags

```bash
# Add tags to resource group
az group update --name "app-rg" --tags Environment=prod CostCenter=IT

# Add tags to resource
az vm update --resource-group "app-rg" --name "vm1" --set tags.Role=WebServer

# List resources by tag
az resource list --tag Environment=prod -o table

# Remove tag
az vm update --resource-group "app-rg" --name "vm1" --remove tags.Temporary
```

---

## Advanced: Governance Control Layering

Locks and tags solve different governance problems and should be layered with RBAC and Policy.

Control interaction model:

- RBAC controls who is authorized to perform actions
- Policy controls what configurations are allowed
- Locks control whether delete/modify operations are blocked
- Tags provide metadata for reporting, automation, and ownership

Operational takeaway:

- Use tags and policy for standards
- Use locks selectively for high-impact resource protection
- Do not use locks as a substitute for proper RBAC design

---

## Advanced: Lock Scope Design Patterns

### Pattern A: Production Resource Group Protection

- Apply `CanNotDelete` lock at production resource group scope
- Keep CI/CD update paths available
- Require change process for lock removal during decommission

This is the most common pattern because it balances safety and operability.

### Pattern B: Short-Lived ReadOnly Freeze Window

- Apply `ReadOnly` temporarily during critical cutover/freeze periods
- Remove after change window closes
- Communicate impact broadly before applying

This avoids long-term operational friction while protecting high-risk windows.

### Pattern C: Tiered Locking by Criticality

- Tier 0 shared platform resources: stronger controls, possible ReadOnly windows
- Tier 1 production app resources: CanNotDelete baseline
- Lower environments: minimal or no locks

This keeps governance proportional to business impact.

---

## Advanced: Tag Taxonomy Engineering

Tag strategy should be designed as a controlled taxonomy, not ad hoc labels.

Recommended mandatory core tags:

- `Environment`
- `CostCenter`
- `Owner`
- `Application`
- `DataClassification`

Good taxonomy rules:

- Controlled value sets for key tags (for example `prod|stage|dev`)
- Explicit casing standard (for example PascalCase keys)
- Stable semantics over time (avoid renaming tags frequently)
- Clear ownership for schema updates

Why this matters:

- Cost and compliance reporting quality depends on consistent tag keys and values.

---

## Advanced: Policy + Tag Remediation Operating Model

To scale tagging standards, combine deny and modify policies intentionally.

Rollout pattern:

1. Audit existing tag coverage
2. Use `modify`/`append` to remediate missing tags where safe
3. Enforce critical tags with `deny` after teams are ready
4. Track exceptions with expiration and owner

Important dependency:

- `modify` effects require managed identity and correct RBAC permissions at assignment scope.

---

## Advanced: FinOps and Chargeback Alignment

Tags are a primary FinOps signal for cost allocation and accountability.

Practical model:

- `CostCenter` and `Application` for chargeback/showback views
- `Environment` for spend segmentation
- `Owner` for accountability and cleanup workflows

Reporting caution:

- Newly applied tags may take time to appear in downstream cost reporting pipelines.
- Inconsistent tag values create fragmented reports and weak trend analysis.

---

## Extended Troubleshooting Matrix (Locks and Tags)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| Cannot delete resource despite Owner role | Inherited `CanNotDelete` lock | Check locks at resource, RG, and subscription scopes | Remove/adjust parent lock, then retry |
| Deployment fails with write operation blocked | `ReadOnly` lock at parent scope | Inspect lock type and assignment scope | Temporarily remove lock for change window |
| Required tags still missing after policy assignment | `modify` policy identity lacks permissions | Review policy assignment identity and role assignments | Grant required role and rerun remediation |
| Cost report shows unallocated resources | Missing/inconsistent cost tags | Query resources for tag coverage and value consistency | Backfill tags and enforce schema via policy |

---

## Production Readiness Checklist (Locks and Tags)

- Lock policy defined by environment criticality (prod vs non-prod)
- `CanNotDelete` baseline applied to critical production resource groups
- ReadOnly lock usage restricted to controlled windows
- Enterprise tag taxonomy documented and versioned
- Required tags enforced via policy with exception process
- Modify/remediation identities have least-privilege required roles
- Periodic review in place for stale locks and low-quality tag values

---
