# Lab: Create VNet + Subnets + NSG (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a virtual network with two subnets, deploy a Network Security Group (NSG), add an inbound rule, associate the NSG to the workload subnet, and validate the effective configuration.

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
- All resources are created in a dedicated resource group and can be removed at the end.
- Default region is `australiaeast`.
- The sample inbound rule can be restricted to your public IP for better security.

## Prerequisites
- Azure subscription with rights to create networking resources
- Azure CLI installed and authenticated (`az login`)

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-vnet"
RG_NAME="${PREFIX}-${LAB}-rg"
VNET_NAME="${PREFIX}-${LAB}-vnet"
NSG_NAME="${PREFIX}-${LAB}-nsg"
SUBNET_APP="app"
SUBNET_VM="vm"
VNET_CIDR="10.20.0.0/16"
APP_SUBNET_CIDR="10.20.1.0/24"
VM_SUBNET_CIDR="10.20.2.0/24"
SSH_SOURCE_CIDR="0.0.0.0/0"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, VNET_NAME=$VNET_NAME, NSG_NAME=$NSG_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group
```bash
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION"
```

### 2) Deploy VNet and subnets
```bash
VNET_ID="$(az network vnet create \
  --resource-group "$RG_NAME" \
  --name "$VNET_NAME" \
  --address-prefixes "$VNET_CIDR" \
  --subnet-name "$SUBNET_APP" \
  --subnet-prefixes "$APP_SUBNET_CIDR" \
  --query newVNet.id -o tsv)"

echo "VNET_ID=$VNET_ID"

az network vnet subnet create \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_VM" \
  --address-prefixes "$VM_SUBNET_CIDR"
```

### 3) Create NSG and rule
```bash
NSG_ID="$(az network nsg create \
  --resource-group "$RG_NAME" \
  --name "$NSG_NAME" \
  --query NewNSG.id -o tsv)"

echo "NSG_ID=$NSG_ID"

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name "$NSG_NAME" \
  --name "Allow-SSH" \
  --priority 1000 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "$SSH_SOURCE_CIDR" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 22
```

### 4) Associate NSG to workload subnet
```bash
az network vnet subnet update \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_VM" \
  --network-security-group "$NSG_ID"
```

### 5) Validate
```bash
az network vnet subnet show \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_VM" \
  --query "{subnet:name,nsg:networkSecurityGroup.id,addressPrefix:addressPrefix}" \
  -o table

az network nsg rule list \
  --resource-group "$RG_NAME" \
  --nsg-name "$NSG_NAME" \
  -o table
```

## ARM template solution (optional)
Use this if you want the same deployment in one declarative run.

```bash
cat > main.json << 'ARMEOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "type": "string" },
    "vnetName": { "type": "string" },
    "nsgName": { "type": "string" },
    "appSubnetName": { "type": "string" },
    "vmSubnetName": { "type": "string" },
    "vnetCidr": { "type": "string" },
    "appSubnetCidr": { "type": "string" },
    "vmSubnetCidr": { "type": "string" },
    "sshSourceCidr": { "type": "string", "defaultValue": "*" }
  },
  "resources": [
    {
      "type": "Microsoft.Network/networkSecurityGroups",
      "apiVersion": "2023-09-01",
      "name": "[parameters('nsgName')]",
      "location": "[parameters('location')]",
      "properties": {
        "securityRules": [
          {
            "name": "Allow-SSH",
            "properties": {
              "priority": 1000,
              "access": "Allow",
              "direction": "Inbound",
              "protocol": "Tcp",
              "sourceAddressPrefix": "[parameters('sshSourceCidr')]",
              "sourcePortRange": "*",
              "destinationAddressPrefix": "*",
              "destinationPortRange": "22"
            }
          }
        ]
      }
    },
    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2023-09-01",
      "name": "[parameters('vnetName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/networkSecurityGroups', parameters('nsgName'))]"
      ],
      "properties": {
        "addressSpace": {
          "addressPrefixes": [
            "[parameters('vnetCidr')]"
          ]
        },
        "subnets": [
          {
            "name": "[parameters('appSubnetName')]",
            "properties": {
              "addressPrefix": "[parameters('appSubnetCidr')]"
            }
          },
          {
            "name": "[parameters('vmSubnetName')]",
            "properties": {
              "addressPrefix": "[parameters('vmSubnetCidr')]",
              "networkSecurityGroup": {
                "id": "[resourceId('Microsoft.Network/networkSecurityGroups', parameters('nsgName'))]"
              }
            }
          }
        ]
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
    vnetName="$VNET_NAME" \
    nsgName="$NSG_NAME" \
    appSubnetName="$SUBNET_APP" \
    vmSubnetName="$SUBNET_VM" \
    vnetCidr="$VNET_CIDR" \
    appSubnetCidr="$APP_SUBNET_CIDR" \
    vmSubnetCidr="$VM_SUBNET_CIDR" \
    sshSourceCidr="$SSH_SOURCE_CIDR"
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
- Use tighter source CIDR values than `0.0.0.0/0` in real environments.
- Keep subnet ranges non-overlapping for future peering/hybrid expansion.
