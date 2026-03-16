# Lab: Basic Public Load Balancer (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a Standard public load balancer with frontend IP, backend pool, health probe, and load-balancing rule. Add two NICs to backend pool for topology validation.

## What you will build

 [Public IP] ---> [Standard Load Balancer]
                     |          |
                     v          v
                [Health Probe] [Backend Pool] <--- [NIC1, NIC2]

## Estimated time
35-50 minutes

## Cost + safety
- Resource group isolation enables full cleanup.
- No VMs are deployed in this lab to keep cost lower.

## Prerequisites
- Azure CLI authenticated (`az login`)
- Permission to create network resources

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-lb"
RG_NAME="${PREFIX}-${LAB}-rg"
VNET_NAME="${PREFIX}-${LAB}-vnet"
SUBNET_NAME="backend"
VNET_CIDR="10.60.0.0/16"
SUBNET_CIDR="10.60.1.0/24"
PIP_NAME="${PREFIX}-${LAB}-pip"
LB_NAME="${PREFIX}-${LAB}-lb"
ENVEOF

source .env
echo "Loaded: $RG_NAME, $LB_NAME"
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

### 2) Create public IP and load balancer
```bash
az network public-ip create \
  --resource-group "$RG_NAME" \
  --name "$PIP_NAME" \
  --sku Standard \
  --allocation-method Static

az network lb create \
  --resource-group "$RG_NAME" \
  --name "$LB_NAME" \
  --sku Standard \
  --public-ip-address "$PIP_NAME" \
  --frontend-ip-name fe-public \
  --backend-pool-name be-pool
```

### 3) Add probe and load-balancing rule
```bash
az network lb probe create \
  --resource-group "$RG_NAME" \
  --lb-name "$LB_NAME" \
  --name tcp-80-probe \
  --protocol Tcp \
  --port 80

az network lb rule create \
  --resource-group "$RG_NAME" \
  --lb-name "$LB_NAME" \
  --name http-rule \
  --protocol Tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name fe-public \
  --backend-pool-name be-pool \
  --probe-name tcp-80-probe
```

### 4) Create NICs and attach to backend pool
```bash
az network nic create \
  --resource-group "$RG_NAME" \
  --name nic-backend-01 \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME"

az network nic create \
  --resource-group "$RG_NAME" \
  --name nic-backend-02 \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME"

az network nic ip-config address-pool add \
  --address-pool be-pool \
  --ip-config-name ipconfig1 \
  --nic-name nic-backend-01 \
  --resource-group "$RG_NAME" \
  --lb-name "$LB_NAME"

az network nic ip-config address-pool add \
  --address-pool be-pool \
  --ip-config-name ipconfig1 \
  --nic-name nic-backend-02 \
  --resource-group "$RG_NAME" \
  --lb-name "$LB_NAME"
```

### 5) Validate
```bash
az network lb show \
  --resource-group "$RG_NAME" \
  --name "$LB_NAME" \
  --query "{name:name,sku:sku.name,frontend:frontendIPConfigurations[0].name,backendPool:backendAddressPools[0].name,probe:probes[0].name,rule:loadBalancingRules[0].name}" \
  -o table

az network public-ip show \
  --resource-group "$RG_NAME" \
  --name "$PIP_NAME" \
  --query "{name:name,ip:ipAddress,sku:sku.name}" \
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
    "publicIpName": { "type": "string" },
    "loadBalancerName": { "type": "string" }
  },
  "resources": [
    {
      "type": "Microsoft.Network/publicIPAddresses",
      "apiVersion": "2023-09-01",
      "name": "[parameters('publicIpName')]",
      "location": "[parameters('location')]",
      "sku": { "name": "Standard" },
      "properties": { "publicIPAllocationMethod": "Static" }
    },
    {
      "type": "Microsoft.Network/loadBalancers",
      "apiVersion": "2023-09-01",
      "name": "[parameters('loadBalancerName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', parameters('publicIpName'))]"
      ],
      "sku": { "name": "Standard" },
      "properties": {
        "frontendIPConfigurations": [
          {
            "name": "fe-public",
            "properties": {
              "publicIPAddress": {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses', parameters('publicIpName'))]"
              }
            }
          }
        ],
        "backendAddressPools": [
          { "name": "be-pool" }
        ],
        "probes": [
          {
            "name": "tcp-80-probe",
            "properties": {
              "protocol": "Tcp",
              "port": 80,
              "intervalInSeconds": 5,
              "numberOfProbes": 2
            }
          }
        ],
        "loadBalancingRules": [
          {
            "name": "http-rule",
            "properties": {
              "protocol": "Tcp",
              "frontendPort": 80,
              "backendPort": 80,
              "enableFloatingIP": false,
              "idleTimeoutInMinutes": 4,
              "loadDistribution": "Default",
              "frontendIPConfiguration": {
                "id": "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', parameters('loadBalancerName'), 'fe-public')]"
              },
              "backendAddressPool": {
                "id": "[resourceId('Microsoft.Network/loadBalancers/backendAddressPools', parameters('loadBalancerName'), 'be-pool')]"
              },
              "probe": {
                "id": "[resourceId('Microsoft.Network/loadBalancers/probes', parameters('loadBalancerName'), 'tcp-80-probe')]"
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
  --parameters location="$LOCATION" publicIpName="$PIP_NAME" loadBalancerName="$LB_NAME"
```

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env main.json
echo "Cleanup started: $RG_NAME"
```

## Notes
- A load balancer needs healthy backend targets to forward real traffic.
- This lab validates control-plane configuration and backend membership.
