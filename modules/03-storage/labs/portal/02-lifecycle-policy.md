# Lab: Blob Lifecycle Management Policy (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a storage account, upload a sample blob, and configure a lifecycle management rule that moves block blobs to the Cool tier after seven days. Validate the rule configuration in the portal.

## What you will build

 [Storage Account]
   |
   v
 [Blob Container]
   |
   v
 [Lifecycle Rule]
   |
   v
 [Move To Cool After 7 Days]

## Estimated time
30-40 minutes

## Cost + safety
- The lab uses a small storage account and sample blob.
- Lifecycle rules are validated by configuration, not by waiting for a real tier change.

## Prerequisites
- Azure subscription with permission to create storage resources
- Azure Portal access

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- PREFIX: az104
- LAB: m03life
- RG_NAME: ${PREFIX}-${LAB}-rg
- STG_NAME: az104m03life001
- CONTAINER_NAME: data

## Portal solution (step-by-step)
### 1) Create the resource group and storage account
1. Open **Resource groups** > **Create**.
2. Create `${RG_NAME}` in `${LOCATION}`.
3. Open **Storage accounts** > **Create**.
4. Set:
   - Resource group: `${RG_NAME}`
   - Storage account name: choose a globally unique variation of `${STG_NAME}`
   - Region: `${LOCATION}`
   - Performance: **Standard**
   - Redundancy: **Locally-redundant storage (LRS)**
5. Select **Review + create**, then **Create**.

### 2) Create a container and upload a sample blob
1. Open the storage account.
2. In **Data storage**, select **Containers** > **+ Container**.
3. Name the container `${CONTAINER_NAME}` and keep anonymous access disabled.
4. Open the container and upload a small text file.

### 3) Create the lifecycle management rule
1. In the storage account, open **Lifecycle management** under **Data management**.
2. Select **Add a rule**.
3. On the rule configuration page, set:
   - Rule name: `move-block-blobs-to-cool`
   - Rule scope: apply to all blobs or keep the default broad scope for this lab
   - Blob type: **Block blobs**
4. In the base blob actions area, enable **Move blobs to cool storage**.
5. Set the condition to **7 days after last modification**.
6. Save the rule.

### 4) Validate
1. Return to **Lifecycle management** and confirm the rule appears in the list.
2. Open the rule to confirm it is enabled and references **Block blobs** with **7 days** before moving to Cool.
3. Open the uploaded blob and note that the blob will not move immediately; Azure processes lifecycle rules asynchronously.

## Cleanup (required)
- In Azure Portal, open **Resource groups** and select `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm cleanup is complete.
- Delete the local `.env` file from your lab folder.

## Notes
- Lifecycle management is configured at the storage account level.
- The rule is valid immediately after saving, but the actual move to Cool happens later when Azure evaluates the policy.
