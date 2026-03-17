# Lab: VM Scale Set with Autoscale Rules (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a VM Scale Set and attach autoscale rules based on Percentage CPU so the scale set can scale out and in within bounded limits.

## What you will build

 [CPU Metrics]
      |
      v
 [Autoscale Profile]
    /            \
   v              v
 [Scale Out]   [Scale In]
      \          /
       v        v
       [VM Scale Set]

## Estimated time
45-60 minutes

## Cost + safety
- VM Scale Sets can scale to multiple instances, so max-count should stay small in labs.
- Use conservative instance sizes and cleanup immediately after validation.

## Prerequisites
- Azure subscription with rights to create VMSS and Monitor autoscale settings
- Azure CLI installed and authenticated with az login

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04vmss"
RG_NAME="${PREFIX}-${LAB}-rg"
VMSS_NAME="${PREFIX}-${LAB}-vmss"
AUTOSCALE_NAME="${PREFIX}-${LAB}-autoscale"
ADMIN_USER="azureuser"
VM_IMAGE="Ubuntu2204"
VM_SKU="Standard_B1s"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, VMSS_NAME=$VMSS_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and VM Scale Set
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

VMSS_ID="$(az vmss create \
  --resource-group "$RG_NAME" \
  --name "$VMSS_NAME" \
  --image "$VM_IMAGE" \
  --vm-sku "$VM_SKU" \
  --instance-count 1 \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --upgrade-policy-mode automatic \
  --query id -o tsv)"

echo "VMSS_ID=$VMSS_ID"
```

### 2) Create autoscale setting and rules
```bash
AUTOSCALE_ID="$(az monitor autoscale create \
  --resource-group "$RG_NAME" \
  --resource "$VMSS_NAME" \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name "$AUTOSCALE_NAME" \
  --min-count 1 \
  --max-count 3 \
  --count 1 \
  --query id -o tsv)"

echo "AUTOSCALE_ID=$AUTOSCALE_ID"

az monitor autoscale rule create \
  --resource-group "$RG_NAME" \
  --autoscale-name "$AUTOSCALE_NAME" \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1

az monitor autoscale rule create \
  --resource-group "$RG_NAME" \
  --autoscale-name "$AUTOSCALE_NAME" \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 1
```

### 3) Validate
```bash
az monitor autoscale show \
  --resource-group "$RG_NAME" \
  --name "$AUTOSCALE_NAME" \
  --query "{enabled:enabled,min:profiles[0].capacity.minimum,max:profiles[0].capacity.maximum,default:profiles[0].capacity.default,rules:profiles[0].rules[].metricTrigger.metricName}" \
  -o jsonc

az vmss show \
  --resource-group "$RG_NAME" \
  --name "$VMSS_NAME" \
  --query "{vmss:name,sku:sku.name,capacity:sku.capacity,upgradePolicy:upgradePolicy.mode}" \
  -o table
```

## ARM template solution (when needed)
Not required for this lab. The key learning target is autoscale operations and rule behavior.

## Cleanup (required)
```bash
# Delete the resource group and all resources asynchronously
az group delete --name "$RG_NAME" --yes --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove local lab files
rm -f .env
echo "Cleaned up local lab files"
```

## Notes
- Autoscale is evaluation-based and not instant at threshold crossing.
- Use asymmetric thresholds and cooldown windows to reduce scale flapping.