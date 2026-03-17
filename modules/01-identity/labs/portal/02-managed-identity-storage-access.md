# Lab: User-Assigned Managed Identity Access to Blob Storage
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a user-assigned managed identity (UAMI), a storage account, and grant the identity **Storage Blob Data Contributor**. Validate role assignment outputs.

## What you will build

 [User-assigned Managed Identity]
   |
   v
 [Data Role Assignment]
   |
   v
 [Storage Account]

 [Future App/VM] ---> [User-assigned Managed Identity]
 [Future App/VM] ---> [Storage Account]

## Estimated time
30–45 minutes

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
- LAB: m01-mi-storage
- RG_NAME: ${PREFIX}-${LAB}-rg

## Portal solution (step-by-step)
1. Sign in to the Azure Portal.
2. In the left menu, select **Managed Identities** > **Create**.
  - Subscription: select your subscription
  - Resource group: `${RG_NAME}`
  - Region: `${LOCATION}`
  - Name: a unique name (e.g., `${PREFIX}${LAB//-/}uami`)
  - Click **Review + Create** > **Create**.
3. In the left menu, select **Storage accounts** > **Create**.
  - Resource group: `${RG_NAME}`
  - Storage account name: a unique name (e.g., `${PREFIX}${SUFFIX}stg`)
  - Region: `${LOCATION}`
  - Performance: Standard
  - Redundancy: LRS
  - Click **Review + Create** > **Create**.
4. After deployment, go to the storage account > **Access control (IAM)** > **Add** > **Add role assignment**.
  - Role: **Storage Blob Data Contributor**
  - Assign access to: **Managed identity**
  - Select: the managed identity you created
  - Click **Next** > **Review + assign** > **Review + assign**.
5. To validate:
  - In the storage account, go to **Access control (IAM)** > **Role assignments**.
  - Filter by the managed identity and confirm the **Storage Blob Data Contributor** role is assigned.



## Cleanup (required)
- In Azure Portal, go to **Resource groups** and open `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm the resource group is removed (this also removes the storage account and user-assigned managed identity).
- Delete the local `.env` file from your lab folder.

## Notes
- Every CLI command that returns an ID/URL is captured into a **variable** and echoed.
- If a command returns JSON, use `--query ... -o tsv` for clean variable assignment.
