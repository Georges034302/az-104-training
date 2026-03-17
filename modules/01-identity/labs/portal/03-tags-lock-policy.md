# Lab: Governance Controls in Portal (Delete Lock + Built-in Policy + Custom Deny Policy)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a resource group, apply governance controls, and validate behavior in two scenarios:
1) Delete lock + built-in policy (Audit)
2) Custom Deny policy from uploaded JSON for non-`australiaeast` deployments

## What you will build

 [Resource Group]
   |      |        |
   v      v        v
 [Tags] [Delete Lock] [Policy Assignment(s)]
                         |            |
                         v            v
               [Built-in Audit]   [Custom Deny]

## Estimated time
30-45 minutes

## Cost + safety
- All resources are created in a **dedicated Resource Group** for this lab and can be deleted at the end.
- Default region: **australiaeast** (change if needed).

## Prerequisites
- Azure subscription with permission to create resources
- Azure Portal access

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- DISALLOWED_LOCATION: eastus
- PREFIX: az104
- LAB: m01-governance
- RG_NAME: az104-m01-governance-rg
- BUILTIN_POLICY_ASSIGN_NAME: az104-m01-governance-rg-audit-rg-location
- POLICY_DEF_NAME: az104-deny-non-australiaeast
- CUSTOM_POLICY_ASSIGN_NAME: az104-m01-governance-rg-deny-location

## Portal solution

### 1) Delete lock + built-in policy (Audit)
1. Sign in to the Azure Portal.
2. In the left menu, select **Resource groups** > **Create**.
  - Resource group name: `${RG_NAME}`
  - Region: `${LOCATION}`
  - Click **Review + Create** > **Create**.
3. In the resource group, select **Tags** from the left menu.
  - Add tags: `owner=student`, `env=dev`, `course=az104`
  - Click **Save**.
4. In the resource group, select **Locks** from the left menu.
  - Click **Add**
  - Lock name: `${RG_NAME}-delete-lock`
  - Lock type: **Delete**
  - Notes: (optional)
  - Click **OK**.

5. In the resource group, open **Policies** > **Assign policy**.
  - Scope: `${RG_NAME}`
  - Policy definition: **Audit resource location matches resource group location** (built-in)
  - Assignment name: `${BUILTIN_POLICY_ASSIGN_NAME}`
  - Click **Review + create** > **Create**.

#### Testing steps (Portal)
1. In the same RG, create a VNet in `eastus`.
2. Expected result: deployment succeeds (Audit does not block creation).
3. Open RG > **Policies** > **Compliance**.
4. Confirm the built-in assignment shows non-compliance for the cross-region resource.
5. Try deleting the RG while the delete lock exists.
6. Expected result: delete is blocked by lock.

#### Key takeaways
- **Delete lock** protects against accidental deletion, but does not enforce configuration standards.
- **Built-in Audit policy** detects violations and reports non-compliance, but does not deny deployment.
- Audit is useful for visibility and gradual governance rollout.

### 2) Deny non-australiaeast-rule (custom JSON policy)
1. Create a custom policy definition from JSON.
  - Open **Policy** > **Definitions** > **+ Policy definition**.
  - Definition location: your subscription.
  - Name: `${POLICY_DEF_NAME}`
  - Category: **Custom**
  - Policy rule: upload or paste JSON from `modules/01-identity/labs/portal/policies/deny-non-australiaeast-rule.json`.
  - Click **Review + create** > **Create**.

2. Assign the custom policy at resource group scope.
  - Open your resource group > **Policies** > **Assign policy**.
  - Scope: `${RG_NAME}`
  - Policy definition: `${POLICY_DEF_NAME}`
  - Assignment name: `${CUSTOM_POLICY_ASSIGN_NAME}`
  - Click **Review + create** > **Create**.

#### Testing steps (Portal)
1. In the same RG, try creating a new VNet with region `eastus`.
  - Expected result: deployment is denied by policy.
  - Error should mention policy assignment `${CUSTOM_POLICY_ASSIGN_NAME}` and policy definition `${POLICY_DEF_NAME}`.
2. Create a VNet in `australiaeast`.
3. Expected result: deployment succeeds because it is compliant.
4. Open RG > **Policies** > **Compliance** and confirm assignment evaluation updates.

#### Key takeaways
- **Deny policy** enforces standards at deployment time and blocks non-compliant changes.
- Assigning policy at **RG scope** gives targeted control for a single workload boundary.
- Built-in and custom policies can coexist: audit for visibility, deny for enforcement.



## Cleanup (required)
- In Azure Portal, open **Resource groups** > `${RG_NAME}` > **Policies**.
- Open **Assignments**, then delete `${BUILTIN_POLICY_ASSIGN_NAME}`.
- In **Assignments**, delete `${CUSTOM_POLICY_ASSIGN_NAME}`.
- In Azure Portal, open **Policy** > **Definitions**, find `${POLICY_DEF_NAME}`, and delete the custom definition.
- Go back to `${RG_NAME}` > **Locks**, select `${RG_NAME}-delete-lock`, then delete the lock.
- Open `${RG_NAME}` > **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm cleanup is complete.
- Delete the local `.env` file from your lab folder.

## Notes
- This lab uses both a **built-in Audit policy** and a **custom Deny policy JSON**.
- Policy assignment/compliance can take a few minutes to propagate.
- If delete fails during cleanup, confirm RG lock was removed first.
