# Lab: RBAC Role Assignment at Resource Group Scope
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a resource group, create a user (optional), and assign a built-in RBAC role at RG scope. Validate the assignment.

## What you will build

  [You]
   |
   v
 [Resource Group]
   |
   v
 [Role Assignment]
   |
   v
 [User/Group] ---> [Built-in Role]
   |
   v
 [ARM Access]

## Estimated time
20–30 minutes

## Cost + safety
- All resources are created in a **dedicated Resource Group** for this lab and can be deleted at the end.
- Default region: **australiaeast** (change if needed).

## Prerequisites
- Azure subscription with permission to create resources
- Azure Portal access

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- PREFIX: az104
- LAB: m01-rbac
- RG_NAME: ${PREFIX}-${LAB}-rg

## Portal solution (step-by-step)
1. Sign in to the Azure Portal.
2. In the left menu, select **Resource groups** > **Create**.
  - Enter Resource Group Name: `${RG_NAME}` (from your .env file)
  - Select Region: `${LOCATION}`
  - Click **Review + Create** > **Create**.
3. In the new resource group, select **Access control (IAM)** from the left menu.
4. Click **Add** > **Add role assignment**.
  - Role: **Reader**
  - Assign access to: **User, group, or service principal**
  - Select: your user or another test user
  - Click **Next** > **Review + assign** > **Review + assign**.
5. To validate:
  - In **Access control (IAM)**, go to the **Role assignments** tab.
  - Filter by the assigned user and confirm the **Reader** role is listed at the resource group scope.



## Cleanup (required)
- In Azure Portal, go to **Resource groups** and open `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm the resource group is removed.
- Delete the local `.env` file from your lab folder.

## Notes
- Every CLI command that returns an ID/URL is captured into a **variable** and echoed.
- If a command returns JSON, use `--query ... -o tsv` for clean variable assignment.
