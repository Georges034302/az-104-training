# Lab: Azure Files Share (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a storage account and SMB-based Azure file share, configure a quota, upload a small file through the portal, and confirm the share details.

## What you will build

 [Resource Group]
      |
      v
 [Storage Account]
      |
      v
 [Azure File Share]
    /         \
   v           v
 [Quota]    [Uploaded File]

## Estimated time
30-40 minutes

## Cost + safety
- The lab uses a standard storage account and small share quota.
- No VM deployment is required.

## Prerequisites
- Azure subscription with permission to create storage resources
- Azure Portal access

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- PREFIX: az104
- LAB: m03files
- RG_NAME: ${PREFIX}-${LAB}-rg
- STG_NAME: az104m03files001
- SHARE_NAME: share1

## Portal solution (step-by-step)
### 1) Create the resource group and storage account
1. Open **Resource groups** > **Create** and create `${RG_NAME}` in `${LOCATION}`.
2. Open **Storage accounts** > **Create**.
3. Set:
   - Resource group: `${RG_NAME}`
   - Storage account name: choose a globally unique variation of `${STG_NAME}`
   - Region: `${LOCATION}`
   - Performance: **Standard**
   - Redundancy: **Locally-redundant storage (LRS)**
4. Select **Review + create**, then **Create**.

### 2) Create the file share
1. Open the storage account.
2. In **Data storage**, select **File shares**.
3. Select **+ File share**.
4. Set:
   - Name: `${SHARE_NAME}`
   - Tier or performance option: leave the default for this lab unless your portal prompts for an access tier
   - Quota: `5` GiB
5. Select **Create**.

### 3) Upload a test file
1. Open share `${SHARE_NAME}`.
2. Select **Upload**.
3. Choose a small local text file and upload it.
4. Confirm the file appears in the share root directory listing.

### 4) Validate
1. In the file share overview, confirm the share name and quota.
2. In the storage account **Endpoints** page, note the file service endpoint.
3. In the share file listing, confirm the uploaded file exists.

## Cleanup (required)
- In Azure Portal, open **Resource groups** and select `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm cleanup is complete.
- Delete the local `.env` file from your lab folder.

## Notes
- Azure Files mounting is not required for this lab. If you later mount it from a client, verify outbound TCP 445 is allowed.
- The portal UI can vary slightly by SKU and region, but the file share creation flow is the same at a high level.
