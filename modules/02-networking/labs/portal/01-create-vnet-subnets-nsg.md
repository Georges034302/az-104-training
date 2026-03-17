# Lab: Create VNet + Subnets + NSG (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a VNet with two subnets, deploy an NSG, add an inbound security rule, associate NSG to the workload subnet, and validate the configuration.

## What you will build

 [Resource Group]
      |
      v
 [VNet 10.20.0.0/16]
    |             |
    v             v
 [app subnet]   [vm subnet] <--- [NSG + inbound rule]

## Estimated time
30-45 minutes

## Cost + safety
- All resources are isolated in one lab resource group.
- Default region: `australiaeast`.

## Prerequisites
- Azure subscription with permission to create networking resources
- Azure Portal access

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- PREFIX: az104
- LAB: m02-vnet
- RG_NAME: ${PREFIX}-${LAB}-rg
- VNET_NAME: ${PREFIX}-${LAB}-vnet
- NSG_NAME: ${PREFIX}-${LAB}-nsg

## Portal solution (step-by-step)
### 1) Create the resource group
1. Sign in to Azure Portal.
2. Open **Resource groups** > **Create**.
3. Set:
   - Resource group name: `${RG_NAME}`
   - Region: `${LOCATION}`
4. Select **Review + create** > **Create**.

### 2) Create the virtual network and subnets
1. Open **Virtual networks** > **Create**.
2. In **Basics**:
   - Resource group: `${RG_NAME}`
   - Name: `${VNET_NAME}`
   - Region: `${LOCATION}`
3. Go to **IP addresses**:
   - IPv4 address space: `10.20.0.0/16`
   - Default subnet: rename to `app` and set `10.20.1.0/24`
4. Select **+ Add a subnet**:
   - Subnet name: `vm`
   - Subnet address range: `10.20.2.0/24`
5. Select **Review + create** > **Create**.

### 3) Create NSG and inbound rule
1. Open **Network security groups** > **Create**.
2. Set:
   - Resource group: `${RG_NAME}`
   - Name: `${NSG_NAME}`
   - Region: `${LOCATION}`
3. Select **Review + create** > **Create**.
4. Open `${NSG_NAME}` > **Inbound security rules** > **+ Add**.
5. Configure rule:
   - Source: `Any` (or your public IP range for tighter security)
   - Source port ranges: `*`
   - Destination: `Any`
   - Service: `SSH`
   - Action: `Allow`
   - Priority: `1000`
   - Name: `Allow-SSH`
6. Select **Add**.

### 4) Associate NSG to vm subnet
1. Open **Virtual networks** > `${VNET_NAME}` > **Subnets**.
2. Select subnet `vm`.
3. In **Network security group**, choose `${NSG_NAME}`.
4. Select **Save**.

### 5) Validate
1. In `${VNET_NAME}` > **Subnets**, confirm `vm` subnet shows NSG `${NSG_NAME}`.
2. In `${NSG_NAME}` > **Inbound security rules**, confirm `Allow-SSH` exists with priority 1000.

## Cleanup (required)
- In Azure Portal, open **Resource groups** and select `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm cleanup is complete.
- Delete the local `.env` file from your lab folder.
## Notes
- Prefer restricted source IP over `Any` for management ports.
- Subnet-level NSG is usually easier to govern than per-NIC exceptions.
