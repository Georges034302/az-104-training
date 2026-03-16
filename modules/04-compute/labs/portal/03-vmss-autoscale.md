# Lab: VM Scale Set Autoscale (Basic)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a VM scale set and add a simple autoscale rule. Validate autoscale profile exists.

## What you will build
```mermaid
flowchart LR
  VMSS[VM Scale Set] --> Instances[Instances]
  Metrics[CPU] --> Autoscale[Autoscale Rules] --> VMSS
```

## Estimated time
45–60 minutes

## Cost + safety
- All resources are created in a **dedicated Resource Group** for this lab and can be deleted at the end.
- Default region: **australiaeast** (change if needed).

## Prerequisites
- Azure subscription with permission to create resources
- Azure CLI installed and authenticated (`az login`)
- (Optional) Azure Portal access

## Setup: Create environment file
```bash
cat > .env << 'EOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04-vmss"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Virtual machine scale sets → Create (Ubuntu, small SKU).
- Enable autoscaling: scale out when CPU > 70%, scale in when CPU < 30%.
- Validate in Autoscale settings and monitor instance count.



## Cleanup (required)
```bash
# Delete the resource group and all its resources asynchronously
az group delete \
  --name "$RG_NAME" \
  --yes \
  --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove the environment file
rm -f .env
echo "Cleaned up environment file"
```

## Notes
- Every CLI command that returns an ID/URL is captured into a **variable** and echoed.
- If a command returns JSON, use `--query ... -o tsv` for clean variable assignment.