# Lab: Storage Account + Blob Container (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a storage account, add a private blob container, upload a file, and download it again to confirm basic blob storage operations in the Azure portal.

## What you will build

 [Resource Group]
    |
    v
 [Storage Account]
    |
    v
 [Blob Container]
   /         \
  v           v
 [Upload]   [Download]

## Estimated time
30-40 minutes

## Cost + safety
- The lab uses a single Standard_LRS storage account.
- All resources remain isolated in one lab resource group for complete cleanup.

## Prerequisites
- Azure subscription with permission to create storage resources
- Azure Portal access

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- PREFIX: az104
- LAB: m03blob
- RG_NAME: ${PREFIX}-${LAB}-rg
- STG_NAME: az104m03blob001
- CONTAINER_NAME: data

## Portal solution (step-by-step)
### 1) Create the resource group
1. Open **Resource groups** in Azure Portal and select **Create**.
2. Set:
  - Resource group name: `${RG_NAME}`
  - Region: `${LOCATION}`
3. Select **Review + create**, then **Create**.

### 2) Create the storage account
1. Open **Storage accounts** and select **Create**.
2. On the **Basics** tab, set:
  - Resource group: `${RG_NAME}`
  - Storage account name: choose a globally unique name based on `${STG_NAME}`
  - Region: `${LOCATION}`
  - Primary service: **Azure Blob Storage or Azure Files**
  - Performance: **Standard**
  - Redundancy: **Locally-redundant storage (LRS)**
3. On **Advanced**, leave secure defaults enabled, including HTTPS-only traffic.
4. Select **Review + create**, then **Create**.

### 3) Create a private blob container
1. Open the new storage account.
2. In **Data storage**, select **Containers**.
3. Select **+ Container**.
4. Set:
  - Name: `${CONTAINER_NAME}`
  - Anonymous access level: **Private (no anonymous access)**
5. Select **Create**.

### 4) Upload and download a sample blob
1. Open container `${CONTAINER_NAME}`.
2. Select **Upload**.
3. Create a small local text file such as `hello-storage.txt` on your workstation.
4. Browse to the file and select **Upload**.
5. After the blob appears in the container list, select the blob name.
6. Use **Download** to save a copy locally.

### 5) Validate
1. In the storage account overview, confirm the account shows **Standard** and **LRS**.
2. In **Containers**, confirm `${CONTAINER_NAME}` exists.
3. In the container view, confirm the uploaded blob appears in the list.
4. Open **Endpoints** in the storage account and note the blob service endpoint.

## Cleanup (required)
- In Azure Portal, open **Resource groups** and select `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm cleanup is complete.
- Delete the local `.env` file from your lab folder.

## Notes
- Storage account names must be globally unique. If your preferred name is unavailable, adjust the suffix and continue.
- This portal lab validates object creation and basic blob operations, not advanced access control.
