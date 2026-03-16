# Lab: VNet Peering + Connectivity Validation (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create two VNets, configure peering in both directions, and validate peering status.

## What you will build

 [VNet-A 10.30.0.0/16] <----> [Peering] <----> [VNet-B 10.31.0.0/16]

## Estimated time
30-45 minutes

## Cost + safety
- Resources are isolated in one lab resource group.
- No VMs required for this basic peering validation.

## Prerequisites
- Azure subscription with permission to create VNets and peerings
- Azure Portal access

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-peering"
RG_NAME="${PREFIX}-${LAB}-rg"
VNET_A="${PREFIX}-${LAB}-vnet-a"
VNET_B="${PREFIX}-${LAB}-vnet-b"
ENVEOF

source .env
echo "Loaded: $RG_NAME, $VNET_A, $VNET_B"
```

## Portal solution (step-by-step)
### 1) Create resource group
1. Open **Resource groups** > **Create**.
2. Set name `${RG_NAME}` and region `${LOCATION}`.
3. Select **Review + create** > **Create**.

### 2) Create VNet A
1. Open **Virtual networks** > **Create**.
2. In **Basics**:
   - Name: `${VNET_A}`
   - Region: `${LOCATION}`
   - Resource group: `${RG_NAME}`
3. In **IP addresses**:
   - Address space: `10.30.0.0/16`
   - Subnet name: `default`
   - Subnet range: `10.30.1.0/24`
4. Select **Review + create** > **Create**.

### 3) Create VNet B
1. Repeat VNet creation with:
   - Name: `${VNET_B}`
   - Address space: `10.31.0.0/16`
   - Subnet range: `10.31.1.0/24`
2. Keep region and resource group the same.

### 4) Create peering from VNet A to VNet B
1. Open **Virtual networks** > `${VNET_A}` > **Peerings** > **+ Add**.
2. Configure:
   - Peering link name (from `${VNET_A}` to remote): `peer-a-to-b`
   - Remote virtual network: `${VNET_B}`
   - Traffic to remote VNet: **Allow**
3. Leave gateway transit options disabled for this basic lab.
4. Select **Add**.

### 5) Create peering from VNet B to VNet A
1. Open `${VNET_B}` > **Peerings** > **+ Add**.
2. Configure:
   - Peering link name: `peer-b-to-a`
   - Remote virtual network: `${VNET_A}`
   - Traffic to remote VNet: **Allow**
3. Select **Add**.

### 6) Validate
1. In `${VNET_A}` > **Peerings**, confirm peering state is **Connected**.
2. In `${VNET_B}` > **Peerings**, confirm peering state is **Connected**.
3. Confirm address spaces remain non-overlapping.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Peering is not transitive by default.
- Peering provides connectivity, not automatic private DNS integration.
