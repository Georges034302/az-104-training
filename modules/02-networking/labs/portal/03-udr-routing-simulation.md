# Lab: UDR Routing Simulation (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a route table, add custom routes, associate the route table to a subnet, and validate the resulting subnet routing association.

## What you will build

 [VNet + subnet]
      |
      v
 [Route table]
    |       \
    v        v
 [Route 1] [Route 2]
      |
      v
 [Subnet association]

## Estimated time
25-35 minutes

## Cost + safety
- Resource group isolation enables full cleanup.
- No compute resources are deployed.

## Prerequisites
- Azure Portal access
- Permission to create VNets and route tables

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- PREFIX: az104
- LAB: m02-udr
- RG_NAME: ${PREFIX}-${LAB}-rg
- VNET_NAME: ${PREFIX}-${LAB}-vnet
- RT_NAME: ${PREFIX}-${LAB}-rt

## Portal solution (step-by-step)
### 1) Create resource group
1. Open **Resource groups** > **Create**.
2. Set name `${RG_NAME}` and region `${LOCATION}`.
3. Select **Create**.

### 2) Create VNet and subnet
1. Open **Virtual networks** > **Create**.
2. Set:
   - Name: `${VNET_NAME}`
   - Region: `${LOCATION}`
   - Resource group: `${RG_NAME}`
3. In **IP addresses**:
   - Address space: `10.40.0.0/16`
   - Subnet name: `workload`
   - Subnet range: `10.40.1.0/24`
4. Select **Create**.

### 3) Create route table
1. Open **Route tables** > **Create**.
2. Set:
   - Name: `${RT_NAME}`
   - Region: `${LOCATION}`
   - Resource group: `${RG_NAME}`
3. Select **Review + create** > **Create**.

### 4) Add routes
1. Open `${RT_NAME}` > **Routes** > **+ Add**.
2. Add route 1:
   - Route name: `default-to-internet`
   - Destination type: **IP Addresses**
   - Destination CIDR blocks: `0.0.0.0/0`
   - Next hop type: **Internet**
3. Add route 2:
   - Route name: `blackhole-example`
   - Destination CIDR blocks: `10.99.0.0/16`
   - Next hop type: **None**

### 5) Associate route table to subnet
1. In `${RT_NAME}`, open **Subnets** > **+ Associate**.
2. Select:
   - Virtual network: `${VNET_NAME}`
   - Subnet: `workload`
3. Select **OK**.

### 6) Validate
1. In `${RT_NAME}` > **Routes**, verify both routes exist.
2. In `${RT_NAME}` > **Subnets**, verify `workload` subnet association exists.

## Cleanup (required)
- In Azure Portal, open **Resource groups** and select `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm cleanup is complete.
- Delete the local `.env` file from your lab folder.
## Notes
- Longest prefix match is used first in route selection.
- For equal prefix length, UDR precedence is above BGP and system routes.
