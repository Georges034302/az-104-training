# Lab: UDR Routing Simulation (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a route table, add custom routes, associate it with a subnet, and validate route behavior at subnet scope.

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
- All resources are created in one lab resource group.
- No compute resources are required.

## Prerequisites
- Azure CLI authenticated (`az login`)
- Permission to create networking resources

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-udr"
RG_NAME="${PREFIX}-${LAB}-rg"
VNET_NAME="${PREFIX}-${LAB}-vnet"
SUBNET_NAME="workload"
VNET_CIDR="10.40.0.0/16"
SUBNET_CIDR="10.40.1.0/24"
RT_NAME="${PREFIX}-${LAB}-rt"
ENVEOF

source .env
echo "Loaded: $RG_NAME, $VNET_NAME, $RT_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and network
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

az network vnet create \
  --resource-group "$RG_NAME" \
  --name "$VNET_NAME" \
  --address-prefixes "$VNET_CIDR" \
  --subnet-name "$SUBNET_NAME" \
  --subnet-prefixes "$SUBNET_CIDR"
```

### 2) Create route table and routes
```bash
RT_ID="$(az network route-table create \
  --resource-group "$RG_NAME" \
  --name "$RT_NAME" \
  --location "$LOCATION" \
  --query id -o tsv)"

echo "RT_ID=$RT_ID"

az network route-table route create \
  --resource-group "$RG_NAME" \
  --route-table-name "$RT_NAME" \
  --name "default-to-internet" \
  --address-prefix "0.0.0.0/0" \
  --next-hop-type Internet

az network route-table route create \
  --resource-group "$RG_NAME" \
  --route-table-name "$RT_NAME" \
  --name "blackhole-example" \
  --address-prefix "10.99.0.0/16" \
  --next-hop-type None
```

### 3) Associate route table to subnet
```bash
az network vnet subnet update \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --route-table "$RT_ID"
```

### 4) Validate
```bash
az network route-table route list \
  --resource-group "$RG_NAME" \
  --route-table-name "$RT_NAME" \
  -o table

az network vnet subnet show \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --query "{subnet:name,routeTable:routeTable.id}" \
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
    "vnetName": { "type": "string" },
    "subnetName": { "type": "string" },
    "vnetCidr": { "type": "string" },
    "subnetCidr": { "type": "string" },
    "routeTableName": { "type": "string" }
  },
  "resources": [
    {
      "type": "Microsoft.Network/routeTables",
      "apiVersion": "2023-09-01",
      "name": "[parameters('routeTableName')]",
      "location": "[parameters('location')]",
      "properties": {
        "routes": [
          {
            "name": "default-to-internet",
            "properties": {
              "addressPrefix": "0.0.0.0/0",
              "nextHopType": "Internet"
            }
          },
          {
            "name": "blackhole-example",
            "properties": {
              "addressPrefix": "10.99.0.0/16",
              "nextHopType": "None"
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
        "[resourceId('Microsoft.Network/routeTables', parameters('routeTableName'))]"
      ],
      "properties": {
        "addressSpace": { "addressPrefixes": [ "[parameters('vnetCidr')]" ] },
        "subnets": [
          {
            "name": "[parameters('subnetName')]",
            "properties": {
              "addressPrefix": "[parameters('subnetCidr')]",
              "routeTable": {
                "id": "[resourceId('Microsoft.Network/routeTables', parameters('routeTableName'))]"
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
    subnetName="$SUBNET_NAME" \
    vnetCidr="$VNET_CIDR" \
    subnetCidr="$SUBNET_CIDR" \
    routeTableName="$RT_NAME"
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
- Route selection uses longest prefix match.
- For equal prefixes, UDR has higher precedence than BGP and system routes.
