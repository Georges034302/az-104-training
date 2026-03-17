# Lab: Private Endpoint for Storage + Private DNS (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a storage account private endpoint and private DNS integration so blob endpoint name resolves to a private IP from linked VNets.

## What you will build

 [VNet + PE subnet] ---> [Private Endpoint NIC] ---> [Storage Account (Blob)]
           |
           v
 [Private DNS zone: privatelink.blob.core.windows.net]

## Estimated time
45-60 minutes

## Cost + safety
- Storage + private endpoint incur small cost while active.
- Use dedicated resource group and cleanup after validation.

## Prerequisites
- Azure Portal access
- Permission to create storage and private networking resources

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- PREFIX: az104
- LAB: m02-pe-dns
- RG_NAME: ${PREFIX}-${LAB}-rg
- VNET_NAME: ${PREFIX}-${LAB}-vnet
- STG_NAME_HINT: ${PREFIX}${LAB//-/}

## Portal solution (step-by-step)
### 1) Create resource group
1. Open **Resource groups** > **Create**.
2. Set name `${RG_NAME}`, region `${LOCATION}`, then create.

### 2) Create VNet and private endpoint subnet
1. Open **Virtual networks** > **Create**.
2. In **Basics**:
   - Name: `${VNET_NAME}`
   - Region: `${LOCATION}`
   - Resource group: `${RG_NAME}`
3. In **IP addresses**:
   - Address space: `10.50.0.0/16`
   - Add subnet:
     - Name: `private-endpoints`
     - Range: `10.50.3.0/24`
4. Complete create.

### 3) Create storage account
1. Open **Storage accounts** > **Create**.
2. In **Basics**:
   - Resource group: `${RG_NAME}`
   - Name: choose globally unique lowercase name (3-24 chars)
   - Region: `${LOCATION}`
   - Performance: **Standard**
   - Redundancy: **LRS**
3. Select **Review + create** > **Create**.

### 4) Create private endpoint for blob service
1. Open the storage account > **Networking** > **Private endpoint connections**.
2. Select **+ Private endpoint**.
3. In **Basics**:
   - Name: `${PREFIX}-${LAB}-pe`
   - Region: `${LOCATION}`
4. In **Resource**:
   - Target sub-resource: **blob**
5. In **Virtual Network**:
   - Virtual network: `${VNET_NAME}`
   - Subnet: `private-endpoints`
6. In **DNS**:
   - Integrate with private DNS zone: **Yes**
   - Private DNS zone: `privatelink.blob.core.windows.net` (create new if prompted)
7. Select **Review + create** > **Create**.

### 5) Validate
1. In storage account > **Private endpoint connections**, confirm state **Approved**.
2. Open **Private DNS zones** > `privatelink.blob.core.windows.net` > **Record sets**.
3. Confirm an `A` record exists for the storage account endpoint.
4. Open private endpoint resource and note private IP address for verification.

## Cleanup (required)
- In Azure Portal, open **Resource groups** and select `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm cleanup is complete.
- Delete the local `.env` file from your lab folder.
## Notes
- Private endpoint controls network path; storage RBAC/SAS still control data access.
- DNS integration is required for private endpoint name resolution to private IP.
