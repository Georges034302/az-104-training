# Azure Policy (Compliance and Governance)

> **Azure Policy** enforces organizational standards and assesses compliance at scale.  
> It evaluates Azure resources against policy rules, applies effects (audit, deny, deploy), and provides compliance reporting for governance teams.

---

## Overview

Azure Policy is the **governance backbone** for Azure environments:

- **Enforce standards** - Prevent non-compliant resources from being created
- **Audit compliance** - Identify existing resources that violate policies
- **Remediate** - Automatically fix non-compliant resources
- **Report** - Centralized compliance dashboard for auditing

In AZ-104 terms: policies **control什么 can be deployed**, complementing RBAC (which controls **who can deploy**).

**Use cases:**
- Enforce specific VM SKUs (prevent expensive VM sizes)
- Require tags on all resources (cost tracking, ownership)
- Block public IP addresses (security compliance)
- Ensure encryption at rest (data protection)
- Auto-deploy diagnostic settings (monitoring compliance)

---

## What You Will Learn

- Policy **components**: definitions, assignments, parameters, effects
- **Policy effects**: Deny, Audit, Append, Modify, DeployIfNotExists, AuditIfNotExists
- **Policy definition structure** (JSON rules and conditions)
- **Initiative definitions** (policy sets) for grouped compliance
- Assignment **scopes** and exemptions
- **Compliance evaluation** and remediation tasks
- Built-in vs custom policies
- Real governance scenarios
- Troubleshooting policy conflicts
- Best practices and exam-grade pitfalls

---

## Mental Model: Policy Evaluation Flow

```text
Nodes:
+----------------------------------------------------+
| Resource Create/Update Request                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Azure Resource Manager                             |
+----------------------------------------------------+
+----------------------------------------------------+
| Policy Engine                                      |
+----------------------------------------------------+
+----------------------------------------------------+
| Evaluate all assigned policies at scope            |
+----------------------------------------------------+
+----------------------------------------------------+
| Resource matches policy rules?                     |
+----------------------------------------------------+
+----------------------------------------------------+
| No match - Allow                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Policy Effect                                      |
+----------------------------------------------------+
+----------------------------------------------------+
| Request Blocked                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Allow + Log Compliance                             |
+----------------------------------------------------+
+----------------------------------------------------+
| Add Properties + Allow                             |
+----------------------------------------------------+
+----------------------------------------------------+
| Change Properties + Allow                          |
+----------------------------------------------------+
+----------------------------------------------------+
| Resource exists?                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Deploy Resource                                    |
+----------------------------------------------------+
+----------------------------------------------------+
| Skip Deployment                                    |
+----------------------------------------------------+
Flow:
[Resource Create/Update Request] --> [Azure Resource Manager]
[Azure Resource Manager] --> [Policy Engine]
[Policy Engine] --> [Evaluate all assigned policies at...]
[Evaluate all assigned policies at...] --> [Resource matches policy rules?]
[Resource matches policy rules?] -- No --> [No match - Allow]
[Resource matches policy rules?] -- Yes --> [Policy Effect]
[Policy Effect] -- Deny --> [Request Blocked]
[Policy Effect] -- Audit --> [Allow + Log Compliance]
[Policy Effect] -- Append --> [Add Properties + Allow]
[Policy Effect] -- Modify --> [Change Properties + Allow]
[Policy Effect] -- DeployIfNotExists --> [Resource exists?]
[Resource exists?] -- No --> [Deploy Resource]
[Resource exists?] -- Yes --> [Skip Deployment]
```

**Key insight:** Policies evaluate **before** resource creation/update, enabling preventative governance.

---

## Policy Components

### 1. Policy Definition

A policy definition contains:
- **Policy rule** (condition + effect)
- **Metadata** (category, display name, description)
- **Parameters** (for reusability)

**Example: Require specific tag on resources**

```json
{
  "properties": {
    "displayName": "Require 'Environment' tag on resources",
    "description": "Enforces existence of 'Environment' tag on all resources",
    "policyType": "Custom",
    "mode": "Indexed",
    "parameters": {
      "tagName": {
        "type": "String",
        "metadata": {
          "displayName": "Tag Name",
          "description": "Name of the required tag"
        },
        "defaultValue": "Environment"
      }
    },
    "policyRule": {
      "if": {
        "field": "[concat('tags[', parameters('tagName'), ']')]",
        "exists": "false"
      },
      "then": {
        "effect": "Deny"
      }
    }
  }
}
```

**Policy modes:**
- **Indexed** - Evaluates resource types that support tags and location (most resources)
- **All** - Evaluates all resource types (including child resources like VM extensions)

### 2. Policy Assignment

Policy assignment **binds** a policy definition to a specific scope:
- Management group (all subscriptions beneath)
- Subscription
Resource group
- Individual resource (rarely used)

**Assignment properties:**
- **Scope** - Where the policy applies
- **Exclusions** - Resources/groups to skip
- **Parameters** - Values for policy parameters
- **Enforcement mode** - Enabled (default) or Disabled (audit-only)
- **Managed identity** - Required for Modify and DeployIfNotExists

### 3. Initiative Definition (Policy Set)

Initiatives **group multiple policies** for logical compliance sets.

**Example: CIS Microsoft Azure Foundations Benchmark**
- Contains 100+ policies for security compliance
- Assign once, enforce entire framework

Benefits:
- **Simplified management** - Assign one initiative instead of 50 individual policies
- **Organized compliance** - Group related policies by framework (PCI-DSS, HIPAA, NIST)
- **Single parameter set** - Configure all policies together

---

## Policy Effects (Detailed)

| Effect | Type | Behavior | Use Case | Remediation |
|--------|------|----------|----------|-------------|
| **Deny** | Preventive | Blocks resource creation/update | Enforce hard limits (no public IPs) | N/A (prevents creation) |
| **Audit** | Detective | Allows but logs non-compliance | Identify existing violations | Manual or task |
| **AuditIfNotExists** | Detective | Checks for related resource existence | Ensure diagnostic settings enabled | Manual or task |
| **Append** | Corrective | Adds properties during creation | Auto-add tags (costCenter=IT) | Task for existing |
| **Modify** | Corrective | Changes properties (tags only) | Fix tag values automatically | Task for existing |
| **DeployIfNotExists** | Corrective | Deploys missing resource | Auto-deploy monitoring agent | Task for existing |
| **Disabled** | None | Policy assigned but not evaluated | Temporarily disable without deleting | N/A |

### Deny Effect

**Blocks** resource operations that don't meet conditions.

```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "not": {
          "field": "Microsoft.Compute/virtualMachines/sku.name",
          "in": ["Standard_B2s", "Standard_D2s_v3"]
        }
      }
    ]
  },
  "then": {
    "effect": "Deny"
  }
}
```

**Result:** Only `Standard_B2s` and `Standard_D2s_v3` VMs allowed; all others blocked.

### Audit Effect

**Logs** non-compliant resources without blocking.

```json
{
  "if": {
    "field": "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly",
    "equals": "false"
  },
  "then": {
    "effect": "Audit"
  }
}
```

**Result:** Storage accounts without HTTPS-only are marked non-compliant in compliance dashboard.

### Append Effect

**Adds properties** during resource creation (cannot modify existing resources via ARM operations).

```json
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Storage/storageAccounts"
  },
  "then": {
    "effect": "Append",
    "details": [
      {
        "field": "Microsoft.Storage/storageAccounts/networkAcls.defaultAction",
        "value": "Deny"
      }
    ]
  }
}
```

**Result:** All new storage accounts get `networkAcls.defaultAction=Deny` automatically.

### Modify Effect

**Changes properties** (primarily tags) on new and existing resources.

```json
{
  "if": {
    "field": "tags['Environment']",
    "exists": "false"
  },
  "then": {
    "effect": "Modify",
    "details": {
      "roleDefinitionIds": [
        "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      ],
      "operations": [
        {
          "operation": "addOrReplace",
          "field": "tags['Environment']",
          "value": "Untagged"
        }
      ]
    }
  }
}
```

**Result:** Resources missing 'Environment' tag get it added with value 'Untagged'.  
**Requires:** Managed identity with Contributor or Tag Contributor role.

### DeployIfNotExists (DINE)

**Deploys a related resource** if it doesn't exist.

```json
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Compute/virtualMachines"
  },
  "then": {
    "effect": "DeployIfNotExists",
    "details": {
      "type": "Microsoft.Insights/diagnosticSettings",
      "existenceCondition": {
        "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
        "equals": "true"
      },
      "deployment": {
        "properties": {
          "mode": "Incremental",
          "template": {
            "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "resources": [
              {
                "type": "Microsoft.Insights/diagnosticSettings",
                "apiVersion": "2021-05-01-preview",
                "name": "vmDiagnostics",
                "properties": {
                  "workspaceId": "[parameters('logAnalyticsWorkspaceId')]",
                  "logs": [
                    {
                      "category": "Administrative",
                      "enabled": true
                    }
                  ]
                }
              }
            ]
          }
        }
      },
      "roleDefinitionIds": [
        "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      ]
    }
  }
}
```

**Result:** VMs without diagnostic settings get them deployed automatically.  
**Requires:** Managed identity with Contributor role.

---

## Policy Assignment Scopes

```text
Nodes:
+----------------------------------------------------+
| Management Group Scope: all child subscriptions    |
+----------------------------------------------------+
+----------------------------------------------------+
| Subscription 1                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Subscription 2                                     |
+----------------------------------------------------+
+----------------------------------------------------+
| Resource Group A                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Resource Group B                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Resource Group C                                   |
+----------------------------------------------------+
+----------------------------------------------------+
| Resource 1                                         |
+----------------------------------------------------+
+----------------------------------------------------+
| Resource 2 EXCLUDED                                |
+----------------------------------------------------+
Flow:
[Management Group Scope: all child...] --> [Subscription 1]
[Management Group Scope: all child...] --> [Subscription 2]
[Subscription 1] --> [Resource Group A]
[Subscription 1] --> [Resource Group B]
[Subscription 2] --> [Resource Group C]
[Resource Group A] --> [Resource 1]
[Resource Group A] --> [Resource 2 EXCLUDED]
```

**Scope inheritance:**
- Policy assigned at **management group** applies to all subscriptions and resource groups beneath
- Policy assigned at **subscription** applies to all resource groups and resources beneath
- **Exclusions** can be added at assignment time to skip specific resource groups or resources

**Best practice:** Assign at highest appropriate scope (management group > subscription > resource group).

---

## Compliance Evaluation

### Evaluation Triggers

1. **Resource create/update** - Immediate evaluation
2. **Policy assignment** - Full scan within 30 minutes
3. **Scheduled scan** - Every 24 hours
4. **On-demand scan** - Manual trigger via CLI/Portal

### Compliance States

- **Compliant** - Resource follows policy rules
- **Non-Compliant** - Resource violates policy rules
- **Conflicting** - Multiple policies with incompatible rules
- **Not Started** - Not yet evaluated
- **Exempt** - Explicitly excluded from policy

### Compliance Dashboard

Azure Policy provides a centralized compliance view:
- **Overall compliance percentage**
- **Non-compliant resources** (drill-down by policy)
- **Policy assignments** (which policies are active)
- **Exemptions** (what's excluded and why)

---

## Remediation Tasks

Remediation tasks **fix existing non-compliant resources** for policies with Modify or DeployIfNotExists effects.

### Creating a Remediation Task

```bash
# Identify non-compliant resources
az policy state list --filter "ComplianceState eq 'NonCompliant'" -o table

# Create remediation task
az policy remediation create   --name "fix-missing-tags"   --policy-assignment "/subscriptions/<sub-id>/providers/Microsoft.Authorization/policyAssignments/<assignment-name>"   --resource-group "<rg-name>"

# Monitor remediation progress
az policy remediation show --name "fix-missing-tags"
```

### Remediation Behavior

- **Runs asynchronously** - Can take minutes to hours
- **Uses managed identity** - Requires appropriate RBAC permissions
- **Retries failures** - Up to 3 attempts per resource
- **Logs deployment history** - Visible in Activity Log

**Important:** Remediation does NOT re-evaluate compliance; run compliance scan after remediation completes.

---

## Built-in vs Custom Policies

### Built-in Policies (200+)

Azure provides built-in policies for common scenarios:
- **Security:** Require HTTPS, disable public access
- **Cost:** Restrict VM SKUs, enforce auto-shutdown
- **Compliance:** Require tags, enforce naming conventions
- **Monitoring:** Deploy diagnostic settings

**Advantages:**
- Tested and maintained by Microsoft
- Updated for new Azure services
- No JSON authoring required

**Examples:**
- `Allowed virtual machine size SKUs`
- `Require a tag on resource groups`
- `Storage accounts should use private link`

### Custom Policies

Create custom policies for organization-specific requirements:
- Enforce custom naming conventions
- Require specific network configurations
- Implement unique security controls

**Definition structure:**

```json
{
  "properties": {
    "displayName": "Enforce naming convention for storage accounts",
    "policyType": "Custom",
    "mode": "Indexed",
    "description": "Storage account names must start with 'st' and be lowercase",
    "parameters": {},
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Storage/storageAccounts"
          },
          {
            "not": {
              "field": "name",
              "match": "st*"
            }
          }
        ]
      },
      "then": {
        "effect": "Deny"
      }
    }
  }
}
```

---

## Real-World Scenarios

### Scenario 1: Enforce cost controls

**Requirement:** Limit VM SKUs to cost-effective sizes for dev/test.

**Solution:**
1. Assign built-in policy `Allowed virtual machine size SKUs`
2. Set parameters: `Standard_B2s`, `Standard_D2s_v3`
3. Scope: Dev/Test resource groups
4. Effect: Deny

**Result:** Developers can only create approved VM sizes.

### Scenario 2: Auto-tag resources with owner

**Requirement:** All resources must have an 'Owner' tag.

**Solution:**
1. Create custom Modify policy
2. Add tag `Owner` with value from creator's email
3. Assign at subscription scope
4. Run remediation task for existing resources

**Result:** All resources tagged automatically.

### Scenario 3: Security compliance (CIS Benchmark)

**Requirement:** Meet CIS Microsoft Azure Foundations Benchmark.

**Solution:**
1. Assign built-in initiative `CIS Microsoft Azure Foundations Benchmark v1.3.0`
2. Scope: Entire subscription
3. Effect: Audit (initially, then migrate to Deny)
4. Review compliance dashboard weekly

**Result:** Centralized compliance reporting for 100+ security controls.

---

## Troubleshooting Policy Issues

### Issue 1: Policy not enforcing

**Symptoms:** Resources created despite Deny policy.

**Checks:**
1. Verify policy assignment scope includes the resource
2. Check enforcement mode (must be "Enabled")
3. Verify no exemptions applied
4. Check policy rule logic (use `--debug` for evaluation details)

### Issue 2: Remediation task stuck

**Symptoms:** Remediation task shows "Running" indefinitely.

**Checks:**
1. Verify managed identity has required permissions
2. Check Activity Log for deployment errors
3. Ensure API permissions for the resource type
4. Manually test deployment template

### Issue 3: Conflicting policies

**Symptoms:** Resource shows "Conflicting" compliance state.

**Checks:**
1. List all policy assignments at scope
2. Identify conflicting rules (e.g., one Denies, one Allows)
3. Remove conflicting policy or add exclusion
4. Consolidate into single initiative

### Policy Evaluation Debugging

```bash
# View detailed evaluation for a resource
az policy state list   --resource "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<vm-name>"   --query "[].{Policy:policyDefinitionName,State:complianceState,Reason:policyDefinitionAction}"   -o table

# Trigger immediate compliance scan
az policy state trigger-scan --no-wait

# View policy events (evaluation history)
az policy event list --query "[?complianceState=='NonCompliant']" -o table
```

---

## Key Takeaways for AZ-104

1. **Policy = what can be deployed** (RBAC = who can deploy)
2. **Effects**: Deny (block), Audit (log), Append/Modify (fix), DINE (deploy)
3. **Initiatives** group related policies for compliance frameworks
4. **Remediation tasks** fix existing non-compliant resources
5. **Exemptions** provide escape hatch with justification
6. **Start with Audit** before enforcing Deny
7. **Built-in policies** cover most common scenarios
8. **Compliance evaluation** takes time (30 min - 24 hrs)
9. **Parameters** make policies reusable
10. **Policy complements RBAC and locks** - not a replacement

---

## Best Practices (AZ-104 Aligned)

✅ **Start with Audit** before enforcing Deny (assess impact first)  
✅ **Use built-in policies** when available (tested and maintained)  
✅ **Group policies** into initiatives for logical compliance sets  
✅ **Assign at highest appropriate scope** (management group > subscription)  
✅ **Use parameters** to make policies reusable across environments  
✅ **Document exemptions** with clear justification and expiration date  
✅ **Regular compliance reviews** (monthly or quarterly)  
✅ **Test in dev** before applying to production  
✅ **Managed identity** for DINE and Modify policies  
✅ **Naming conventions** for policy assignments (include purpose and scope)  
✅ **Review Activity Log** after policy changes for deployment errors  
✅ **Combine with RBAC** (least privilege) and locks (prevent deletion)

---

## Common Pitfalls & Exam Traps

❌ **Confusing Policy with RBAC**  
Policy controls **what** can be deployed; RBAC controls **who** can deploy. You can have Contributor rights but still be blocked by a Deny policy.

❌ **Using Deny without testing in Audit first**  
Start with Audit to understand impact, then switch to Deny after validation.

❌ **Forgetting managed identity for DINE/Modify**  
DeployIfNotExists and Modify require managed identity with sufficient RBAC permissions.

❌ **Not waiting for evaluation**  
Compliance results can take 30 minutes after assignment; don't assume immediate enforcement.

❌ **Over-exempting resources**  
Excessive exemptions reduce governance value; use sparingly with documented business justification.

❌ **Assigning too broadly without exclusions**  
Subscription-wide Deny assignments can block legitimate use cases (e.g., blocking all public IPs prevents Azure Bastion).

❌ **Not setting exemption expiration**  
Permanent exemptions become technical debt; always set expiration dates for review.

❌ **Conflicting policies**  
Multiple policies at different scopes can conflict; test policy combinations before production.

❌ **Forgetting inherited assignments**  
Policies assigned at management group or subscription scope apply to all children; check parent scopes.

❌ **Using Append for existing resources**  
Append only affects **new** resources; use Modify or remediation tasks for existing resources.

---

## CLI Reference (Commented Examples)

### Policy Definitions

```bash
# List all built-in policy definitions
az policy definition list --query "[?policy Type=='BuiltIn'].{Name:displayName,ID:name}" -o table

# View specific policy definition
az policy definition show --name "e56962a6-4747-49cd-b67b-bf8b01975c4c"  # Allowed locations

# Create custom policy from JSON file
az policy definition create   --name "enforce-storage-naming"   --display-name "Enforce storage naming convention"   --description "Storage accounts must start with 'st'"   --rules policy-rule.json   --params policy-params.json   --mode Indexed

# Delete custom policy
az policy definition delete --name "enforce-storage-naming"
```

### Policy Assignments

```bash
# Assign built-in policy at subscription scope
az policy assignment create   --name "allowed-locations"   --display-name "Restrict Azure regions"   --policy "e56962a6-4747-49cd-b67b-bf8b01975c4c"   --params '{"listOfAllowedLocations":{"value":["australiaeast","australiasoutheast"]}}'   --scope "/subscriptions/<subscription-id>"

# Assign at resource group scope with exclusion
az policy assignment create   --name "require-tags-rg"   --policy "<policy-definition-id>"   --resource-group "prod-rg"   --not-scopes "/subscriptions/<sub-id>/resourceGroups/prod-rg/providers/Microsoft.Compute/virtualMachines/exempted-vm"

# List all policy assignments
az policy assignment list -o table

# Delete policy assignment
az policy assignment delete --name "allowed-locations"

# Create assignment with managed identity (for DINE/Modify)
az policy assignment create   --name "deploy-diagnostics"   --policy "<policy-id>"   --assign-identity   --identity-scope "/subscriptions/<sub-id>"   --role "Contributor"   --location "australiaeast"
```

### Initiatives (Policy Sets)

```bash
# List built-in initiatives
az policy set-definition list --query "[?policyType=='BuiltIn'].{Name:displayName,ID:name}" -o table

# Assign initiative
az policy assignment create   --name "cis-benchmark"   --display-name "CIS Azure Benchmark"   --policy-set-definition "<initiative-id>"   --scope "/subscriptions/<sub-id>"
```

### Compliance and State

```bash
# View overall compliance summary
az policy state summarize --top 5

# List non-compliant resources
az policy state list --filter "ComplianceState eq 'NonCompliant'" -o table

# View compliance for specific resource
az policy state list   --resource "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<vm-name>"

# Trigger on-demand compliance scan
az policy state trigger-scan --no-wait

# Check scan status
az policy state trigger-scan  # Waits for completion

# Query policy events (evaluation history)
az policy event list --from "2024-01-01" --to "2024-01-31" --query "[?complianceState=='NonCompliant']" -o table
```

### Remediation Tasks

```bash
# Create remediation for non-compliant resources
az policy remediation create   --name "fix-tags-remediation"   --policy-assignment "/subscriptions/<sub-id>/providers/Microsoft.Authorization/policyAssignments/require-tags"

# Create remediation for specific resource group
az policy remediation create   --name "fix-rg-tags"   --policy-assignment "<assignment-id>"   --resource-group "prod-rg"

# Check remediation status
az policy remediation show --name "fix-tags-remediation"

# List all remediation tasks
az policy remediation list -o table

# Cancel running remediation
az policy remediation cancel --name "fix-tags-remediation"

# Delete remediation task
az policy remediation delete --name "fix-tags-remediation"
```

### Exemptions

```bash
# Create policy exemption (escape hatch)
az policy exemption create   --name "exemption-legacy-vm"   --display-name "Legacy VM exemption"   --policy-assignment "<assignment-id>"   --exemption-category "Waiver"   --expires-on "2024-12-31"   --scope "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<vm-name>"

# List exemptions
az policy exemption list -o table

# Delete exemption
az policy exemption delete --name "exemption-legacy-vm"
```

---

**Final Note:** Azure Policy is the **enforcement layer** for governance. Combine it with RBAC (authorization), locks (deletion protection), and tags (organization) for comprehensive Azure resource governance.

---
