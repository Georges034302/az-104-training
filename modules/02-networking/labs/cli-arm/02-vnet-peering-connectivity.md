# Lab: VNet Peering + Connectivity Validation (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create two VNets with non-overlapping address spaces, configure bidirectional peering, and validate peering state and route propagation expectations.

## What you will build

 [VNet-A 10.30.0.0/16] <----> [Peering] <----> [VNet-B 10.31.0.0/16]

## Estimated time
30-45 minutes

## Cost + safety
- All resources are created in one dedicated resource group.
- Default region is `australiaeast`.
- This lab does not deploy VMs, so cost is minimal.

## Prerequisites
- Azure subscription with permission to create VNets/peerings
- Azure CLI authenticated (`az login`)

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-peering"
RG_NAME="${PREFIX}-${LAB}-rg"
VNET_A="${PREFIX}-${LAB}-vnet-a"
VNET_B="${PREFIX}-${LAB}-vnet-b"
VNET_A_CIDR="10.30.0.0/16"
VNET_B_CIDR="10.31.0.0/16"
SUBNET_A_CIDR="10.30.1.0/24"
SUBNET_B_CIDR="10.31.1.0/24"
ENVEOF

source .env
echo "Loaded: $RG_NAME, $VNET_A, $VNET_B"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group
```bash
az group create --name "$RG_NAME" --location "$LOCATION"
```

### 2) Create both VNets
```bash
az network vnet create \
  --resource-group "$RG_NAME" \
  --name "$VNET_A" \
  --address-prefixes "$VNET_A_CIDR" \
  --subnet-name default \
  --subnet-prefixes "$SUBNET_A_CIDR"

az network vnet create \
  --resource-group "$RG_NAME" \
  --name "$VNET_B" \
  --address-prefixes "$VNET_B_CIDR" \
  --subnet-name default \
  --subnet-prefixes "$SUBNET_B_CIDR"

VNET_A_ID="$(az network vnet show --resource-group "$RG_NAME" --name "$VNET_A" --query id -o tsv)"
VNET_B_ID="$(az network vnet show --resource-group "$RG_NAME" --name "$VNET_B" --query id -o tsv)"

echo "VNET_A_ID=$VNET_A_ID"
echo "VNET_B_ID=$VNET_B_ID"
```

### 3) Configure bidirectional peering
```bash
az network vnet peering create \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_A" \
  --name "peer-a-to-b" \
  --remote-vnet "$VNET_B_ID" \
  --allow-vnet-access

az network vnet peering create \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_B" \
  --name "peer-b-to-a" \
  --remote-vnet "$VNET_A_ID" \
  --allow-vnet-access
```

### 4) Validate
```bash
az network vnet peering list \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_A" \
  --query "[].{name:name,state:peeringState,remote:remoteVirtualNetwork.id}" \
  -o table

az network vnet peering list \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_B" \
  --query "[].{name:name,state:peeringState,remote:remoteVirtualNetwork.id}" \
  -o table
```

## ARM template solution (optional)
```bash
cat > main.json << 'ARMEOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "type": "string" },
    "vnetAName": { "type": "string" },
    "vnetBName": { "type": "string" },
    "vnetACidr": { "type": "string" },
    "vnetBCidr": { "type": "string" },
    "subnetACidr": { "type": "string" },
    "subnetBCidr": { "type": "string" }
  },
  "resources": [
    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2023-09-01",
      "name": "[parameters('vnetAName')]",
      "location": "[parameters('location')]",
      "properties": {
        "addressSpace": { "addressPrefixes": [ "[parameters('vnetACidr')]" ] },
        "subnets": [ { "name": "default", "properties": { "addressPrefix": "[parameters('subnetACidr')]" } } ]
      }
    },
    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2023-09-01",
      "name": "[parameters('vnetBName')]",
      "location": "[parameters('location')]",
      "properties": {
        "addressSpace": { "addressPrefixes": [ "[parameters('vnetBCidr')]" ] },
        "subnets": [ { "name": "default", "properties": { "addressPrefix": "[parameters('subnetBCidr')]" } } ]
      }
    },
    {
      "type": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings",
      "apiVersion": "2023-09-01",
      "name": "[format('{0}/peer-a-to-b', parameters('vnetAName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetAName'))]",
        "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetBName'))]"
      ],
      "properties": {
        "allowVirtualNetworkAccess": true,
        "remoteVirtualNetwork": {
          "id": "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetBName'))]"
        }
      }
    },
    {
      "type": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings",
      "apiVersion": "2023-09-01",
      "name": "[format('{0}/peer-b-to-a', parameters('vnetBName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetAName'))]",
        "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetBName'))]"
      ],
      "properties": {
        "allowVirtualNetworkAccess": true,
        "remoteVirtualNetwork": {
          "id": "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetAName'))]"
        }
      }
    }
  ]
}
ARMEOF

az deployment group create \
  --resource-group "$RG_NAME" \
  --template-file main.json \
  --parameters \
    location="$LOCATION" \
    vnetAName="$VNET_A" \
    vnetBName="$VNET_B" \
    vnetACidr="$VNET_A_CIDR" \
    vnetBCidr="$VNET_B_CIDR" \
    subnetACidr="$SUBNET_A_CIDR" \
    subnetBCidr="$SUBNET_B_CIDR"
```

## Cleanup (required)
```bash
# Delete the resource group and all resources asynchronously
az group delete --name "$RG_NAME" --yes --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove local lab files
rm -f .env main.json
echo "Cleaned up local lab files"
```

## Notes
- Peering is non-transitive by default.
- Ensure CIDR ranges never overlap across peered VNets.
